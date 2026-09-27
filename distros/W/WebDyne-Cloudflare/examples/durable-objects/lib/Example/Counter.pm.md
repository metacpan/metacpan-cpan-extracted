# Example::Counter

Ordinary Perl Durable Object handlers. `initialize($context)` creates the table
and initial row idempotently. `increment($context, $amount)` atomically updates and
returns the counter row. `read($context)` returns that row. All three return Futures.
Only increment/read are exposed as RPC methods by the example configuration.
