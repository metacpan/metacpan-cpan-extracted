UniEvent::HTTP - extremely fast sync/async http client and server framework

# Synopsis
```cpp
using namespace unievent::http;
// asynchronous request
http_request(Request::Builder()
    .uri("https://example.com")
    .timeout(5000)
    .response_callback([](const RequestSP& /*request*/,
                          const ResponseSP& response,
                          const ErrorCode& error) {
        if (error) {
            std::cerr << error << std::endl;
            return;
        }
        std::cout << response->to_string();
    }).build()
);

// simple API
http_get("http://mysite.com", [](auto, const ResponseSP& response, auto) {
    std::cout << response->body;
});

unievent::Loop::default_loop()->run();

// synchronous request
auto expected_response = http_get("https://example.com");
if (expected_response) {
    std::cout << (*expected_response)->body;
}
auto expected_response2 = http_request_sync(Request::Builder()
    .uri("https://example.com")
    .timeout(3000)
    .build()
);

// more control
http_request(Request::Builder()
    .uri("https://example.com")
    .method(Request::Method::Post)
    .header("Unique-Header", "Value")
    .cookie("MySiteAuth", "42")
    .timeout(5000) // ms
    .follow_redirect(true)
    .tcp_nodelay(true)
    .redirection_limit(5)
    .ssl_ctx(SslContext())
    .proxy(new URI("socks5://myproxy.com:8080"))
    .tcp_hints(unievent::AddrInfoHints(AF_UNSPEC))
    .compress(compression::Compression::GZIP)
    .allow_compression(compression::Compression::GZIP, compression::Compression::DEFLATE)
    .body("{}")
    .response_callback([](auto...){})
    .redirect_callback([](auto...){})
    .partial_callback([](auto...){})
    .build()
);

// http server
Server::Config conf;
conf.idle_timeout = 60'000;
conf.max_headers_size = 16384;
conf.max_body_size = 1'000'000;
conf.tcp_nodelay = true;
conf.max_keepalive_requests = 1000;
conf.locations = {
    Server::Location("*", 80),
    Server::Location("*", 443, 1000, SslContext())
};

ServerSP server = new Server(conf);

server->request_event.add([](const ServerRequestSP& request) {
    if (request->uri->path() == "/hello") {
        Headers response_headers;
        response_headers.add("HeaderName", "HeaderVal");
        request->respond(new ServerResponse(200, std::move(response_headers), Body("Hi")));
    } else {
        request->respond(new ServerResponse(404));
    }
});

auto sig = unievent::Signal::create(SIGINT, [server](const unievent::SignalSP& sig, int) {
    sig->stop();
    server->stop();
});

server->run();
unievent::Loop::default_loop()->run();

// personal pool
Pool::Config pool_conf;
pool_conf.max_connections = 10;
PoolSP pool = new Pool(pool_conf);

pool->request(Request::Builder()
    .uri("https://google.com")
    .build()
);

// personal client
ClientSP client = new Client;
client->request(Request::Builder()
    .uri("https://google.com")
    .build()
);

// user agent for http session, keeping cookies between requests, like browsers
UserAgentSP ua = new UserAgent(unievent::Loop::default_loop());
ua->request(Request::Builder()
    .uri("https://mysite.com/authorize?login=1&password=2")
    .response_callback([ua](const RequestSP&,
                            const ResponseSP&,
                            const ErrorCode&) {
        // ...
        ua->request(Request::Builder().uri("https://mysite.com/restricted_info").build());
        // ...
    })
    .build()
);
string serialized = ua->to_string();
/// ...
// load session data
UserAgentSP new_ua = new UserAgent(unievent::Loop::default_loop(), serialized);
new_ua->request(Request::Builder().uri("https://mysite.com/restricted_info").build());
// ...
```


UniEvent::HTTP contains both synchronous and asynchronous http client and asynchronous
http server framework.

It is built on top of [Protocol::HTTP](https://github.com/CrazyPandaLimited/Protocol-HTTP) http protocol implementation and [UniEvent](https://github.com/CrazyPandaLimited/UniEvent) event framework. This library is an [UniEvent](https://github.com/CrazyPandaLimited/UniEvent) user, so you need to run [UniEvent](https://github.com/CrazyPandaLimited/UniEvent)'s loop for it to work.

UniEvent::HTTP supports many features, including various request methods, cookies, request forms, chunks, compression, keep-alive, connection pools and so on.

See [UniEvent::HTTP::Manager](https://github.com/CrazyPandaLimited/UniEvent-HTTP-Manager) if you need async multi-process http server with process management.

# Build and Install

UniEvent::HTTP can be build using CMake. It supports both `find_package` and `add_subdirectory` approaches. Target name to link against your library or executable is `unievent-http`. See [detailed manual how to build UniEvent based projects](https://github.com/CrazyPandaLimited/UniEvent/blob/master/doc/build.md). For UniEvent http all the instructions are the same. Just add [UniEvent::HTTP itself](https://github.com/CrazyPandaLimited/UniEvent-HTTP), [Protocol::HTTP](https://github.com/CrazyPandaLimited/Protocol-HTTP) and its [dependencies](https://github.com/CrazyPandaLimited/Protocol-HTTP#build-and-install)  to list of modules to install/add.

# Client

Client http requests are made via [http_get()](#http_get), [http_request()](#http_request), [unievent::http::Pool](doc/pool.md), [unievent::http::Client](doc/client.md) and [unievent::http::UserAgent](doc/useragent.md).

The short description is given below, for full reference see corresponding package's docs.

# Simple API
### http_request
The simple interface is to use `http_request()` function

```cpp
void http_request (const RequestSP& request, const LoopSP& loop = {});
```

Where `request` is a [Request](doc/request.md) object. There is a builder class to make request construction easy - [Request::Builder](doc/request.md#builder).
```cpp
http_request(Request::Builder()
    .uri("https://example.com")
    .timeout(5000)
    .response_callback([](const RequestSP&, const ResponseSP&, const ErrorCode&) {
        // ...
    })
    .build()
);
```

Callbacks set in request object will be called during request or after it's finished. See [Request](doc/request.md).

### http_get
The even more simpler interface is `http_get()` function

```cpp
void http_get (const URISP& uri, const Request::response_fn& cb, const LoopSP& = {});
```
which is the same as

```cpp
http_request(Request::Builder()
    .uri(uri)
    .method(Request::Method::Get)
    .response_callback(cb)
    .build()
);
```

# Pool

[unievent::http::Pool](doc/pool.md) represents a pool of http client connections which makes use of http keep-alive feature and restricts the maximum number of running http requests at a time for certain destination.

Requests made via the same pool object share the same keep-alive connections. Any number of simultaneous requests can be made via one pool but not all of them may be executing at the same time (depending on request uris and config, see [unievent::http::Pool](doc/pool.md)).

```cpp
PoolSP pool = new Pool(pool_conf);

pool->request(Request::Builder().uri("https://google.com").build());
// .. after request is done poll will reuse connection
pool->request(Request::Builder().uri("https://google.com").build());
```
Simple methods like [http_request()](#http_request), [http_get()](#http_get) use global per-loop connection pool.


# Client

[Client](doc/client.md) represents a single http client connection and is the lowest-level API.

```cpp
ClientSP client = new Client;
client->request(Request::Builder()
    .uri("https://google.com")
    .build()
);
```

Only one request can be made via client at a time. To execute next request you must wait till active request finishes.

# Server

The short description is given below, for full reference see corresponding class's [docs](doc/server.md).

Server is an object to be run in single process/thread. If you need to make use of all processor cores, you need to create server in each process/thread.
See [UniEvent::HTTP::Manager](https://github.com/CrazyPandaLimited/UniEvent-HTTP-Manager).

Server is created via
```cpp
    ServerSP server = new Server(config);
```
And then is run by

```cpp
    server->run();
```
Method `run()` doesn't block anything, it just creates and activates various event handles in [UniEvent](https://github.com/CrazyPandaLimited/UniEvent). You must run the appropriate event loop afterwards.


## Receiving requests

There are two main methods of receiving http requests.

The first is adding a listener to `request_event`. It is called when request is fully received in-memory (including request body).
```cpp
server->request_event.add([](const ServerRequestSP& request) {
    auto method = request->method();
    auto uri = request->uri;
    auto headers = request->headers;
    auto body = request->body;
});
```

The second is setting `route_callback` which is called as early as possible but after all headers arrived. It is expected that user will decide how to process
the request depending on it's URI and other properties.
```cpp
server->route_event.add([](const ServerRequestSP& request) {
    auto method = request->method();
    auto uri = request->uri;
    auto headers = request->headers;
    auto body = request->body; // ! may be empty or partially available !

    if (request->uri->path() == "/path1") {
        // process request when it's fully received in-memory
        request->receive_event.add([](auto request) {
            std::cout << request->body; // now it's fully available in-memory
        });
    }
    else if (request->uri->path() == "/put_file") {
        request->enable_partial();
        request->partial_event.add([](auto request, auto error) {
            std::cout << request->body; // will grow from call to call if do nothing
            // write request->body to disk or do whatever
            request->body.clear(); // clear body to avoid in-memory accumulation
            if (request->is_done()) {
                // request is fully received - finish stuff and send response
            }
        });
    }
});
```

If uri is "/path1" we process request as in example before, after fully receiving all request.

If uri is "/put_file" we enable partial mode and set `partial_event` which will be called one or more times, every time new data arrives from network. When it is called for the last time, `request->is_done()` will be true. In this callback request's properties like `body` get filled with more and more data. We can use incremental parsing or write data to disk asynchronously or whatsoever. If any error occurs during request receival, callback will be called with an `error` indicating error occured. In this case no more calls will be made and request->is_done() will not be true.

## Sending response

Regardless of the way request is received, a response can be given asynchronously at any time - immediately or some time on the future.

Response can be fully given at once including body, or can be given partially - without body. The latter case is used to respond with chunks.

```cpp
// respond immediately
server->request_event.add([](const ServerRequestSP& request) {
    request->respond(new ServerResponse(200, {}, Body("Hi")));
});

// respond later, e.g. after making request to another server
server->request_event.add([](const ServerRequestSP& request) {
    http_request(Request::Builder()
        .uri("https://example.com")
        .response_callback([request](auto...) {
            request->respond(new ServerResponse(200, {}, Body("Hi")));
        })
        .build()
    );
});

// respond with chunks
TcpSP some_data_source = new Tcp;
server->request_event.add([=](const ServerRequestSP& request) {
    request->respond(ServerResponse::Builder()
        .code(200)
        .chunked()
        .build()
    );
    some_data_source->read_event.add([request](auto, string data, auto) {
        request->response()->send_chunk(data);
    });

    some_data_source->eof_event.add([request](auto) {
        request->response()->send_final_chunk();
    });
});
```

# Logs

Logs are accessible via [panda::log](https://github.com/CrazyPandaLimited/panda-lib/blob/master/doc/log.md) framework as "UniEvent::HTTP" module.

```cpp
    panda::log::set_logger(new ConsoleLogger());
    panda::log::set_level(panda::log::Level::Debug, "UniEvent::HTTP");
```