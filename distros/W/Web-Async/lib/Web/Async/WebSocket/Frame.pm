package Web::Async::WebSocket::Frame;
use Myriad::Class;

our $VERSION = '0.004'; ## VERSION
## AUTHORITY

field $opcode : reader : param;
field $payload : reader : param;

1;
