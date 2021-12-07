#include <catch2/catch_test_macros.hpp>
#include <sstream>
#include <iostream>
#include <panda/log/file.h>
#include <panda/unievent/Fs.h>

using namespace panda;
using namespace panda::log;
using panda::unievent::Fs;

#define TEST(name) TEST_CASE("log-file: " name, "[log-file]")

#ifdef _WIN32
    #define NL "\r\n"
#else
    #define NL "\n"
#endif

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
        set_logger(nullptr);
        Fs::remove_all(dir);
    }

    string readfile (string path) {
        auto fd = Fs::open(path, Fs::OpenFlags::RDONLY).value();
        auto content = Fs::read(fd, 999).value();
        Fs::close(fd);
        return content;
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
    set_formatter("%m");
    set_level(Level::Debug);
    panda_log_debug("hello");
    set_logger(nullptr);

    set_logger(new FileLogger(cfg));
    panda_log_debug("world");
    set_logger(nullptr);  // need to close file to flush it

    CHECK(c.readfile(cfg.file) == "hello" NL "world" NL);
}

TEST("autoflush") {
    Ctx c;
    FileLogger::Config cfg;
    cfg.file = c.dir + "/file.log";
    cfg.autoflush = true;
    set_logger(new FileLogger(cfg));
    set_formatter("%m");
    set_level(Level::Debug);

    panda_log_debug("hello");

    CHECK(c.readfile(cfg.file) == "hello" NL);

    panda_log_debug("world");

    CHECK(c.readfile(cfg.file) == "hello" NL "world" NL);
}

#ifndef _WIN32 // windows will not allow to change busy file
TEST("reopen log file if moved/deleted/etc") {
    Ctx c;
    FileLogger::Config cfg;
    cfg.file = c.dir + "/file.log";
    cfg.autoflush = true;
    cfg.check_freq = 0;
    set_logger(new FileLogger(cfg));
    set_formatter("%m");
    set_level(Level::Debug);

    panda_log_debug("hello");

    CHECK(c.readfile(cfg.file) == "hello" NL);

    SECTION("remove") { Fs::remove(cfg.file); }
    SECTION("move") { Fs::rename(cfg.file, cfg.file + ".tmp"); }

    panda_log_debug("world");

    CHECK(c.readfile(cfg.file) == "world" NL);
}
#endif

TEST("ignore logging if log file could not be created/written") {
    Ctx c;
    FileLogger::Config cfg;
    cfg.check_freq = 0;
    cfg.autoflush = true;

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
    CHECK(txt == "this log should NOT be ignored" NL);
}
