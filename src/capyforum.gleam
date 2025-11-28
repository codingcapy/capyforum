import api
import gleam/http/response
import gleam/int
import gleam/io
import gleam/option
import gleam/result
import gleam/uri
import lib/async_data
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element/html
import message
import model.{type Model, Model}
import modem
import plinth/browser/window
import rsvp

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  io.println("Hello from capyforum!")
}

fn initial_route() -> model.Route {
  modem.initial_uri()
  |> result.map(fn(uri) { echo uri.path_segments(uri.path) })
  |> fn(path) {
    case path {
      Ok([]) -> model.NotAuthenticated(model.Login)
      Ok(["login"]) -> model.NotAuthenticated(model.Login)
      Ok(["dashboard", user_id]) -> {
        let user_id = int.parse(user_id)
        case user_id {
          Error(_) -> model.Authenticated(model.Dashboard)
          Ok(id) -> model.Authenticated(model.Dashboard)
        }
      }
      Ok(["logout"]) -> model.NotAuthenticated(model.Login)
      _ -> model.Authenticated(model.Dashboard)
    }
  }
}

pub fn init(_) -> #(Model, effect.Effect(message.Msg)) {
  let route = initial_route()
  let model = Model(route:, user: async_data.NotAsked)
  let #(model, data_fx) = ensure_data(model)
  let fx = effect.batch([modem.init(on_url_change), data_fx])
  #(model, fx)
}

fn update(model: Model, msg: message.Msg) -> #(Model, Effect(message.Msg)) {
  case msg {
    message.OnRouteChange(route) -> {
      let #(guarded_route, auth_fx) = guard_route(route, model.user)
      let model = Model(..model, route: guarded_route)

      let #(model, load_fx) = ensure_data(Model(..model, route:))

      let fx = effect.batch([auth_fx, load_fx])

      #(model, fx)
    }
    message.Navigate(to) -> {
      window.set_location(window.self(), to)

      #(model, effect.none())
    }
    message.ApiReturnedUser(user_result) -> {
      let user = async_data.Done(user_result)
      let model = Model(..model, user: user)

      // now that we know user, we may need to load workspaces/projects/memories
      let #(model, load_fx) = ensure_data(model)

      case user_result, model.route {
        // Logged in but currently on login screen -> go to dashboard
        Ok(_), model.NotAuthenticated(model.Login) -> {
          let route = model.Authenticated(model.Dashboard)
          let model = Model(..model, route: route)

          let #(model, more_fx) = ensure_data(model)

          let fx =
            effect.batch([
              modem.push("/dashboard", option.None, option.None),
              load_fx,
              more_fx,
            ])

          #(model, fx)
        }

        // 401 while on secure screen -> kick to login
        Error(rsvp.HttpError(response.Response(401, ..))),
          model.Authenticated(_)
        -> {
          let route = model.NotAuthenticated(model.Login)
          let model = Model(..model, route: route)

          let #(model, more_fx) = ensure_data(model)

          let fx =
            effect.batch([
              modem.push("/login", option.None, option.None),
              load_fx,
              more_fx,
            ])

          #(model, fx)
        }

        // Any other combination -> just store the user + any needed loads
        _, _ -> #(model, load_fx)
      }
    }
    message.None -> todo
  }
}

fn guard_route(
  route: model.Route,
  async_data: async_data.AsyncData(api.User, rsvp.Error),
) -> #(model.Route, Effect(message.Msg)) {
  todo
}

fn view(model: Model) {
  html.main([], [html.text("hello world")])
}

fn ensure_data(model: model.Model) {
  let model.Model(user:, ..) = model
  let #(user, user_fx) = case user {
    async_data.NotAsked -> #(
      async_data.Loading,
      api.get_me(message.ApiReturnedUser),
    )

    async_data.Loading -> #(user, effect.none())
    async_data.Done(_) -> #(user, effect.none())
  }
  #(
    Model(..model, user: user),
    effect.batch([
      user_fx,
    ]),
  )
}

fn on_url_change(uri: uri.Uri) -> message.Msg {
  case uri.path_segments(uri.path) {
    [] -> model.NotAuthenticated(model.Login) |> message.OnRouteChange
    [_, ..] -> model.NotAuthenticated(model.Login) |> message.OnRouteChange
  }
}
