#include "lib/test.h"

TEST_PREFIX("pipe: ", "[pipe]");

TEST("pair") {
    AsyncTest test(1000, 1);
    std::pair<PipeSP,PipeSP> p;

    SECTION("basic handles") {
        p = Pipe::pair(test.loop).value();
    }
    SECTION("custom handles") {
        struct MyPipe : Pipe { using Pipe::Pipe; };
        p = Pipe::pair(new MyPipe(test.loop), new MyPipe(test.loop)).value();
        CHECK(panda::dyn_cast<MyPipe*>(p.first.get()));
        CHECK(panda::dyn_cast<MyPipe*>(p.second.get()));
    }

    p.first->read_event.add([&](auto...){
        test.happens();
        p.first->reset();
        p.second->reset();
    });
    p.second->write("hello world");

    test.run();
    SUCCEED("ok");
}
