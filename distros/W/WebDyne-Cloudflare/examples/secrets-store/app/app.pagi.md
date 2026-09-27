# Native PAGI Secrets Store supplement

`app.psp` is the default WebDyne example. Select this file as `webdyne.entry`
using the [example instructions](../../README.md#native-pagi-alternatives) to
exercise an explicit PAGI text response. The request retrieves `API_KEY`, sends
`Cache-Control: no-store`, and returns only `Secret retrieval succeeded`.
The value and its length are never included in the response.
