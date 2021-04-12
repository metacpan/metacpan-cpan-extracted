#include "streamer.h"
#include <panda/unievent/streamer/File.h>

TEST_PREFIX("streamer-file: ", "[streamer-file]")

using namespace panda::unievent::streamer;

namespace {
    struct TestFileInput : FileInput {
        using FileInput::FileInput;

        int stop_reading_cnt = 0;

        void stop_reading () override {
            stop_reading_cnt++;
            FileInput::stop_reading();
        }
    };

    static string read_file (string_view path) {
        size_t chunk_size = 1000000;
        string ret, buf;
        auto fd = Fs::open(path, Fs::OpenFlags::RDONLY).value();
        do {
            buf = Fs::read(fd, chunk_size).value();
            ret += buf;
        } while (buf.length() == chunk_size);
        return ret;
    }
}

TEST("normal input") {
    AsyncTest test(3000, 1);
    auto i = new TestFileInput("tests/streamer/file.txt", 10000);
    auto o = new TestOutput(20000);
    StreamerSP s = new Streamer(i, o, 100000, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        if (err) WARN(err);
        CHECK(!err);
        test.happens();
    });
    test.run();
    CHECK(i->stop_reading_cnt == 0);
}

TEST("pause input") {
    AsyncTest test(3000, 1);
    auto i = new TestFileInput("tests/streamer/file.txt", 30000);
    auto o = new TestOutput(10000);
    StreamerSP s = new Streamer(i, o, 50000, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        if (err) WARN(err);
        CHECK(!err);
        test.happens();
    });
    test.run();
    CHECK(i->stop_reading_cnt > 0);
}

TEST("normal output") {
    Fs::mkpath("tests/var/streamer").nevermind();
    AsyncTest test(3000, 1);
    auto i = new TestFileInput("tests/streamer/file.txt", 10000);
    auto o = new FileOutput("tests/var/streamer/fout.txt");
    StreamerSP s = new Streamer(i, o, 100000, test.loop);
    s->start();
    s->finish_event.add([&](const ErrorCode& err) {
        if (err) WARN(err);
        CHECK(!err);
        test.happens();
    });
    test.run();

    auto s1 = read_file("tests/streamer/file.txt");
    auto s2 = read_file("tests/var/streamer/fout.txt");
    CHECK((s1 == s2));
}
