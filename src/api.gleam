import gleam/dynamic/decode
import lustre/effect
import rsvp

pub type User {
  User(
    id: String,
    email: String,
    username: String,
    created_at: String,
    password: String,
    active: Bool,
  )
}

pub fn get_me(msg_wrapper wrapper) {
  let handler = {
    rsvp.expect_json(decode.at(["user"], user_decoder()), wrapper)
  }

  rsvp.get(base_url() <> "/auth/me", handler)
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("userId", decode.string)
  use email <- decode.field("email", decode.string)
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)
  use created_at <- decode.field("createdAt", decode.string)
  use active <- decode.field("active", decode.bool)
  decode.success(User(id:, email:, username:, password:, created_at:, active:))
}

fn base_url() -> String {
  "/api/v0"
}
