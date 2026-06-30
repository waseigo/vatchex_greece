# Telemetry

VatchexGreece does not currently emit custom telemetry events.

HTTP-level instrumentation (request durations, response statuses, transport errors)
is available through the underlying HTTP client [Req](https://hex.pm/packages/req),
which uses [Finch](https://hex.pm/packages/finch) and emits standard
`[:finch, ...]` events.
