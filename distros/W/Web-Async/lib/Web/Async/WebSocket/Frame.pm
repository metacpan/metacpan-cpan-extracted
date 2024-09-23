package Web::Async::WebSocket::Frame;
use Full::Class qw(:v1);

our $VERSION = '0.006'; ## VERSION
## AUTHORITY

field $opcode : reader : param;
field $payload : reader : param;

1;
