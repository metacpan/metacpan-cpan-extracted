#include "../lib/test.h"
#include "catch2/catch_test_macros.hpp"
#include "panda/protocol/http/compression/Compression.h"
#include "panda/protocol/http/compression/Gzip.h"
#include "panda/unievent/AddrInfo.h"
#include "panda/unievent/Loop.h"
#include "panda/unievent/Signal.h"
#include "panda/unievent/SslContext.h"
#include "panda/unievent/forward.h"
#include "panda/unievent/http.h"
#include "panda/unievent/http/Request.h"
#include "panda/unievent/http/Response.h"
#include "panda/unievent/http/Server.h"
#include "panda/unievent/http/ServerResponse.h"
#include "panda/unievent/http/UserAgent.h"
#include "panda/unievent/http/msg.h"
#include <iostream>
#include <sys/socket.h>

TEST_CASE("clietn synopsis", "[.]") {
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
        })
        .build()
    );

    // simple API
    http_get("http://mysite.com", [](const RequestSP& /*request*/,
                                     const ResponseSP& response,
                                     const ErrorCode& /*error*/) {
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
        .response_callback([](auto, auto, auto){})
        .redirect_callback([](auto, auto, auto){})
        .partial_callback([](auto, auto, auto){})
        .build()
    );

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

}
