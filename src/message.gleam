import api
import model
import rsvp

pub type Msg {
  OnRouteChange(model.Route)
  ApiReturnedUser(Result(api.User, rsvp.Error))
  None
  Navigate(route: String)
}
