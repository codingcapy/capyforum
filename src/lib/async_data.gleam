pub type AsyncData(data, error) {
  NotAsked
  Loading
  Done(Result(data, error))
}
