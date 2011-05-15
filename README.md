# Configurable Rack endpoint for Async image resizing.

In progress.

Borrows heavily from Dragonfly ([https://github.com/markevans/dragonfly](https://github.com/markevans/dragonfly)).

Async mode relies on Thin's async.callback env variable and EventMachine.

See [http_router](/examples/http_router.ru) example for an intro.

## TODO

Error responses, testing, benchmarking.