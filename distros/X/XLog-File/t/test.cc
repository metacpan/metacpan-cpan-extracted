#include <catch2/catch.hpp>
#include <sstream>
#include <iostream>
#include <panda/log/file.h>
#include <panda/unievent/Fs.h>

using namespace panda;
using namespace panda::log;
using panda::unievent::Fs;

#define TEST(name) TEST_CASE("log-file: " name, "[log-file]")

struct StderrCapture {
    std::stringstream ss;
    std::streambuf*   old;
    StderrCapture () : ss(), old(std::cerr.rdbuf(ss.rdbuf())) {}
    ~StderrCapture () { std::cerr.rdbuf(old); }
};

struct Ctx {
    string dir;

    Ctx () : dir("t/var") {
        Fs::mkpath(dir);
    }

    ~Ctx () {
        Fs::remove_all(dir);
    }
};

TEST("create") {
    Ctx c;
    FileLoggerSP logger;
    FileLogger::Config cfg;
    SECTION("no file") {
        cfg.file = c.dir + "/file.log";
    }
    SECTION("no path") {
        cfg.file = c.dir + "/mydir/file.log";
    }
    SECTION("file exists") {
        cfg.file = c.dir + "/file.log";
        Fs::touch(cfg.file);
    }
    logger = new FileLogger(cfg);
    CHECK(true);
}

TEST("log") {
    Ctx c;
    FileLogger::Config cfg;
    cfg.file = c.dir + "/file.log";
    set_logger(new FileLogger(cfg));
    set_format("%m");
    set_level(DEBUG);
    panda_log_debug("hello");
    set_logger(nullptr);

    set_logger(new FileLogger(cfg));
    panda_log_debug("world");
    set_logger(nullptr); // need to close file to flush it

    auto fd = Fs::open(cfg.file, Fs::OpenFlags::RDONLY).value();
    auto txt = Fs::read(fd, 999).value();
    CHECK(txt == "hello\nworld\n");
}

TEST("autoflush") {
    Ctx c;
    FileLogger::Config cfg;
    cfg.file = c.dir + "/file.log";
    cfg.autoflush = true;
    set_logger(new FileLogger(cfg));
    set_format("%m");
    set_level(DEBUG);

    panda_log_debug("hello");

    auto fd = Fs::open(cfg.file, Fs::OpenFlags::RDONLY).value();
    auto txt = Fs::read(fd, 999).value();
    CHECK(txt == "hello\n");

    panda_log_debug("world");

    fd = Fs::open(cfg.file, Fs::OpenFlags::RDONLY).value();
    txt = Fs::read(fd, 999).value();
    CHECK(txt == "hello\nworld\n");
}

TEST("reopen log file if moved/deleted/etc") {
    Ctx c;
    FileLogger::Config cfg;
    cfg.file = c.dir + "/file.log";
    cfg.autoflush = true;
    cfg.check_freq = 0;
    set_logger(new FileLogger(cfg));
    set_format("%m");
    set_level(DEBUG);

    panda_log_debug("hello");

    auto fd = Fs::open(cfg.file, Fs::OpenFlags::RDONLY).value();
    auto txt = Fs::read(fd, 999).value();
    CHECK(txt == "hello\n");

    Fs::remove(cfg.file);

    panda_log_debug("world");

    fd = Fs::open(cfg.file, Fs::OpenFlags::RDONLY).value();
    txt = Fs::read(fd, 999).value();
    CHECK(txt == "world\n");
}

TEST("ignore logging if log file could not be created/written") {
    Ctx c;
    FileLogger::Config cfg;
    cfg.check_freq = 0;

    string to_delete;
    SECTION("mkpath fails") {
        to_delete = c.dir + "/notdir";
        Fs::touch(to_delete);
        cfg.file = to_delete + "/file";
    }
    SECTION("open fails") {
        cfg.file = c.dir + "/notfile";
        Fs::mkpath(cfg.file);
        to_delete = cfg.file;
    }

    StderrCapture cap;

    set_logger(new FileLogger(cfg));
    panda_log_error("this log should be ignored");

    Fs::remove_all(to_delete); // remove the reason of failure

    panda_log_error("this log should NOT be ignored");

    auto fd = Fs::open(cfg.file, Fs::OpenFlags::RDONLY).value();
    auto txt = Fs::read(fd, 999).value();
    CHECK(txt == "this log should NOT be ignored\n");
}
