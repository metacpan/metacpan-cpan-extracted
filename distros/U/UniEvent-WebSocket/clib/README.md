# Unievent-WebSocket

UniEvent-WebSocket - Extremely efficient asynchronous WebSocket Client and Server.

# Synopsis

```cpp
// Client
ClientSP client = new Client();
client->connect("ws://myserver.com:12345");
client->connect_event.add([](ClientSP client, ConnectResponseSP connect_response) {
    if (connect_response->error()) { /*...*/ }
    client->send_text("hello");
});
client->message_event.add([](ConnectionSP client, MessageSP message){
    for (string s : message->payload) {
        std::cout << s;
    }
    client->close(CloseCode::DONE);
});
client->peer_close_event.add([](ConnectionSP /*client*/, MessageSP message) {
    std::cout << message->close_code();
    std::cout << message->close_message();
});

unievent::Loop::default_loop()->run();

// Server
Server::Config conf;
Location ws;
ws.host = "*";
ws.port = 80;
ws.reuse_port = 1;
ws.backlog = 1024;
conf.locations.push_back(ws);

Location wss = ws;
wss.port = 443;
wss.set_ssl_ctx(SslContext()); // set actual context with keys
conf.locations.push_back(wss);

conf.max_frame_size = 1000;
conf.max_message_size = 100'000;
conf.deflate->compression_level = 3;
conf.deflate->compression_threshold = 1000;

ServerSP server = new Server();
server->configure(conf);

server->connection_event.add([](ServerSP /*server*/, ServerConnectionSP client, ConnectRequestSP) {
    client->message_event.add([](ConnectionSP /*client*/, MessageSP message) {
        for (string s : message->payload) {
            std::cout << s;
        }
    });
    client->peer_close_event.add([](ConnectionSP /*client*/, MessageSP message) {
        std::cout << message->close_code();
        std::cout << message->close_message();
    });
    client->send_text("hello from server");
});

server->run();
unievent::Loop::default_loop()->run();
```

**Unievent-WebSocket** is built on top of [Protocol-WebSocket](https://github.com/CrazyPandaLimited/Protocol-WebSocket-Fast) websocket protocol implementation and [UniEvent](https://github.com/CrazyPandaLimited/UniEvent) event framework.
This library is an [UniEvent](https://github.com/CrazyPandaLimited/UniEvent) user, so you need to run `UniEvent`'s loop for it to work.

**UniEvent::WebSocket** supports per-message deflate.

It is built on top of [UniEvent-HTTP](https://github.com/CrazyPandaLimited/UniEvent-HTTP) so UniEvent-WebSocket is a http server as well and can serve http requests also. It can be run as a part of complex [UniEvent-HTTP](https://github.com/CrazyPandaLimited/UniEvent-HTTP) server or as standalone websocket server.

You can use [UniEvent::HTTP::Manager](https://github.com/CrazyPandaLimited/UniEvent-HTTP-Manager) to run multi-process http/websocket server with process management.

# Build

UniEvent-WebSocket can be built using CMake. It can be used as a subproject or standalone installation. Add all dependencies with `add_subdirectory` before including UniEvent-WebSocket or make sure they are available via `find_package`. Direct dependencies are
* [UniEvent-HTTP](https://github.com/CrazyPandaLimited/UniEvent-HTTP)
* [Protocol-Websocket](https://github.com/CrazyPandaLimited/Protocol-WebSocket-Fast)

All the dependencies can be downloaded automatically on the configuration step. Just set `UNIEVENT_WEBSOCKET_FETCH_DEPS=ON` and they would be downloaded recursively.

To add UniEvent-WebSocket to your CMake project it is easier to use FetchContent as well

```cmake
include(FetchContent)
FetchContent_Declare(unievent-websocket GIT_REPOSITORY https://github.com/CrazyPandaLimited/UniEvent-WebSocket.git)
FetchContent_MakeAvailable(unievent-websocket)
```

And then link against `unievent-websocket` target

```cmake
target_link_libraries(your_project PUBLIC unievent-websocket)
```

If you want to build  UniEvent-WebSocket itself then just run

```bash
mkdir build
cd build
cmake .. -DUNIEVENT_WEBSOCKET_FETCH_DEPS=ON
cmake --build . -j
```

More information and common build details of UniEvent-based project look [here](https://github.com/CrazyPandaLimited/UniEvent/blob/master/doc/build.md).

# Reference

In progress
