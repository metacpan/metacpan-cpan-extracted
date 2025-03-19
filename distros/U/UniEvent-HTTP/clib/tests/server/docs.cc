#include "../lib/test.h"
#include <iostream>
#include <sys/socket.h>

TEST_CASE("server synopsis", "[.]") {
    using namespace unievent::http;

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
}

TEST_CASE("server docs", "[.]") {
    Server::Config conf;
    ServerSP server = new Server(conf);

    server->route_event.add([](const ServerRequestSP& request) {
        auto method = request->method();
        auto uri = request->uri;
        auto headers = request->headers;
        auto body = request->body; // ! may be empty or partially available !

        (void)method;(void)uri;(void)headers;(void)body;

        if (request->uri->path() == "/path1") {
            // process request when it's fully received in-memory
            request->receive_event.add([](auto request) {
                std::cout << request->body; // now it's fully available in-memory
            });
        }
        else if (request->uri->path() == "/put_file") {
            request->enable_partial();
            request->partial_event.add([](auto request, auto) {
                std::cout << request->body; // will grow from call to call if do nothing
                // write request->body to disk or do whatever
                request->body.clear(); // clear body to avoid in-memory accumulation
                if (request->is_done()) {
                    // request is fully received - finish stuff and send response
                }
            });
        }
    });

    // respond immediately
    server->request_event.add([](const ServerRequestSP& request) {
        request->respond(new ServerResponse(200, {}, Body("Hi")));
    });

    TcpSP some_data_source = new Tcp;
    // respond later, e.g. after making request to another server
    server->request_event.add([](const ServerRequestSP& request) {
        http_request(Request::Builder()
            .uri("https://example.com")
            .response_callback([request](auto, auto, auto) {
                request->respond(new ServerResponse(200, {}, Body("Hi")));
            })
            .build()
        );
    });

    // respond with chunks
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
}
