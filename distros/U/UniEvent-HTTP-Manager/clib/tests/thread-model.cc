#include <catch2/catch_test_macros.hpp>
#include <panda/unievent/http/manager/Mpm.h>
#include <panda/unievent/http.h>
#include <panda/log.h>
#include <thread>
#include <atomic>
#include <iostream>

using namespace panda;
using namespace panda::unievent::http::manager;
using namespace panda::unievent;

TEST_CASE("thread_model", "[thread_model]") {
    auto cfg = Mpm::Config{};
    cfg.worker_model = Manager::WorkerModel::Thread;
    cfg.server.locations = { {"127.0.0.1", 0} };
    cfg.min_servers = 1;
    cfg.max_servers = 1;

    panda::log::set_level(panda::log::Level::Debug, "UniEvent");
    panda::log::set_level(panda::log::Level::Debug, "UniEvent::HTTP::Manager");
    panda::log::set_logger([](const string& msg, auto&){
        printf("-> %s\n", msg.c_str());
    });
    panda::log::set_formatter("%4.6t =%p= %c[%L/%1M]%C %f:%l,%F(): %m");

    auto loop = panda::unievent::Loop::default_loop();
    ManagerSP mgr = new Manager(cfg, loop);
    REQUIRE(mgr);

    auto parent_id = std::this_thread::get_id();
    std::cout << "root thread = " << parent_id << "\n";

    SECTION("spawn_callback") {
        std::atomic_bool invoked{false};
        mgr->spawn_event.add([&](auto&){
            invoked = true;
            auto child_id = std::this_thread::get_id();
            CHECK(child_id != parent_id);
        });

        std::atomic_bool timer_invoked{false};
        auto timer = Timer::create_once(100, [&](auto&) {
            timer_invoked = true;
            mgr->stop();
        }, loop);
        mgr->run();
        CHECK(timer_invoked);
        CHECK(invoked);
    }

    SECTION("request_callback") {
        std::atomic_bool invoked{false};
        mgr->spawn_event.add([&](const http::ServerSP& server){
            server->run_event.add([&](){
                auto port  = server->sockaddr()->port();
                printf("going to use port %d\n", port);
                std::cout << "run thread = " << std::this_thread::get_id() << "\n";
                TimerSP timer = new Timer(server->loop());
                timer->event.add([&invoked, port = port, timer = timer](auto&) mutable {
                    char buff[50];
                    sprintf(buff, "http://127.0.0.1:%d/", port);
                    printf("going to make a request %s\n", buff);

                    http::ClientSP client = new http::Client(timer->loop());
                    auto req = http::Request::Builder().uri(buff).build();
                    req->response_event.add([&invoked, req = req, client = client](auto&, auto&, auto& err) mutable {
                        if (!err) {
                            invoked = true;
                        }
                        req.reset();
                        client.reset();
                    });
                    client->request(req);
                    timer->reset();
                    timer.reset();

                });
                timer->once(5);
                std::cout << "spawned timer = " << timer << ", on loop " << (void*)server->loop().get() << "\n";
            });
        });

        mgr->request_event.add([](const http::ServerRequestSP& req){
            req->respond(new http::ServerResponse(200));
        });

        std::atomic_bool timer_invoked{false};
        auto timer = Timer::create_once(100, [&](auto&) {
            timer_invoked = true;
            mgr->stop();
        }, loop);
        mgr->run();
        CHECK(timer_invoked);
        CHECK(invoked);
    }
}
