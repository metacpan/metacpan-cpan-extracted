#include "test.h"
#include <panda/log.h>
#include <catch2/reporters/catch_reporter_registrars.hpp>
#include <catch2/reporters/catch_reporter_event_listener.hpp>

namespace test {
    struct MyListener : Catch::EventListenerBase {
        using EventListenerBase::EventListenerBase;

        void testRunStarting (Catch::TestRunInfo const&) override {
            panda::log::set_level(panda::log::Level::Warning);
        }

        void testCaseStarting (Catch::TestCaseInfo const&) override {
        }

        void testCaseEnded (Catch::TestCaseStats const&) override {
            // tests pollution cleanup
            if (panda::log::get_modules().size() != 1) throw std::runtime_error("some test created and not deleted a log module");
            panda::log::set_logger(nullptr);
            panda::log::set_formatter(nullptr);
        }
    };
    CATCH_REGISTER_LISTENER(MyListener);

    int Tracer::copy_calls = 0;
    int Tracer::ctor_calls = 0;
    int Tracer::move_calls = 0;
    int Tracer::dtor_calls = 0;

    Stat allocs;

    const char* external_fn() { return "lorem impsum"; }
}

