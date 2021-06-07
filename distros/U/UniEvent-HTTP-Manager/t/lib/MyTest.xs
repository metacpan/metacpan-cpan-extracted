#include <xs.h>
#include <xs/unievent/Loop.h>
#include <xs/unievent/http/manager.h>

using namespace xs;
using namespace panda;
using namespace panda::unievent;
using namespace panda::unievent::http;

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

void run_server (Manager::Config config = {}, LoopSP loop = {}) {
    panda::log::set_level(panda::log::Level::Debug, "UniEvent::HTTP::Manager");
    panda::log::set_logger([](auto& str, auto&) {
        printf("%s\n", str.c_str());
    });
    panda::log::set_formatter("%4.6t =%p=%T= %c[%L/%1M]%C %f:%l,%F(): %m");
    
    
    Manager mgr(config, loop);
    if (0) mgr.request_event.add([](auto& req) {
        req->respond(
            ServerResponse::Builder()
            .code(200)
            .body("epta")
            .build()
        );
    });
    
    if (1) mgr.spawn_event.add([](auto& server) {
        server->request_event.add([](auto& req) {
            req->respond(
                ServerResponse::Builder()
                .code(200)
                .body("epta")
                .build()
            );
        });
    });
    
    mgr.run();
}