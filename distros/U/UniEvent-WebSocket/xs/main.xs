#include <xs/unievent/http.h>
#include <xs/unievent/websocket.h>
#include <xs/CallbackDispatcher.h>
#include <xs/function.h>

using namespace xs;
using namespace xs::unievent::websocket;
using namespace panda::unievent;
using namespace panda::unievent::websocket;
using panda::function;
using panda::string;
using panda::string_view;

MODULE = UniEvent::WebSocket                PACKAGE = UniEvent::WebSocket 
PROTOTYPES: DISABLE

string ws_scheme (bool secure = false)

INCLUDE: Server.xsi

INCLUDE: Connection.xsi

INCLUDE: ServerConnection.xsi

INCLUDE: Client.xsi

INCLUDE: Iterator.xsi

INCLUDE: ConnectRequest.xsi

INCLUDE: Statistics.xsi
