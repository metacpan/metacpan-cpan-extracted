package UniEvent::WebSocket;
use 5.012;
use UniEvent;
use Protocol::WebSocket::Fast;

our $VERSION = '1.0.1';

XS::Loader::load();

*UE::WebSocket::OPCODE_CONTINUE = \&Protocol::WebSocket::Fast::OPCODE_CONTINUE;
*UE::WebSocket::OPCODE_TEXT     = \&Protocol::WebSocket::Fast::OPCODE_TEXT;
*UE::WebSocket::OPCODE_BINARY   = \&Protocol::WebSocket::Fast::OPCODE_BINARY;
*UE::WebSocket::OPCODE_CLOSE    = \&Protocol::WebSocket::Fast::OPCODE_CLOSE;
*UE::WebSocket::OPCODE_PING     = \&Protocol::WebSocket::Fast::OPCODE_PING;
*UE::WebSocket::OPCODE_PONG     = \&Protocol::WebSocket::Fast::OPCODE_PONG;

*UE::WebSocket::CLOSE_DONE             = \&Protocol::WebSocket::Fast::CLOSE_DONE;
*UE::WebSocket::CLOSE_AWAY             = \&Protocol::WebSocket::Fast::CLOSE_AWAY;
*UE::WebSocket::CLOSE_PROTOCOL_ERROR   = \&Protocol::WebSocket::Fast::CLOSE_PROTOCOL_ERROR;
*UE::WebSocket::CLOSE_INVALID_DATA     = \&Protocol::WebSocket::Fast::CLOSE_INVALID_DATA;
*UE::WebSocket::CLOSE_UNKNOWN          = \&Protocol::WebSocket::Fast::CLOSE_UNKNOWN;
*UE::WebSocket::CLOSE_ABNORMALLY       = \&Protocol::WebSocket::Fast::CLOSE_ABNORMALLY;
*UE::WebSocket::CLOSE_INVALID_TEXT     = \&Protocol::WebSocket::Fast::CLOSE_INVALID_TEXT;
*UE::WebSocket::CLOSE_BAD_REQUEST      = \&Protocol::WebSocket::Fast::CLOSE_BAD_REQUEST;
*UE::WebSocket::CLOSE_MAX_SIZE         = \&Protocol::WebSocket::Fast::CLOSE_MAX_SIZE;
*UE::WebSocket::CLOSE_EXTENSION_NEEDED = \&Protocol::WebSocket::Fast::CLOSE_EXTENSION_NEEDED;
*UE::WebSocket::CLOSE_INTERNAL_ERROR   = \&Protocol::WebSocket::Fast::CLOSE_INTERNAL_ERROR;
*UE::WebSocket::CLOSE_TLS              = \&Protocol::WebSocket::Fast::CLOSE_TLS;

1;
