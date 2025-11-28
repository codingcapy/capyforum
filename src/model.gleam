import api
import lib/async_data
import rsvp

pub type Model {
  Model(route: Route, user: async_data.AsyncData(api.User, rsvp.Error))
}

pub type Route {
  Authenticated(SecureRoute)
  NotAuthenticated(PublicRoute)
}

pub type PublicRoute {
  Login
}

pub type SecureRoute {
  Dashboard
}
