#include "lib/test.h"
#include <stdlib.h>

#ifdef __WIN32
    static bool win32 = true;
#else
    static bool win32 = false;
#endif

struct Test : AsyncTest {
    string procdir;
    string file;
    string file2;
    string dir;
    string dir2;
    function<void(const std::error_code&, const Fs::RequestSP&)> success;
    function<void(const std::error_code&, const Fs::RequestSP&)> fail;

    Test (int tmt = 0, int nevents = 0) : AsyncTest(tmt, nevents) {
        procdir = root_vdir + "/" + string::from_number(panda::unievent::getpid()) + "-" + string::from_number(rand());
        Fs::mkpath(procdir.c_str(), 0755);
        file  = path("file");
        file2 = path("file2");
        dir   = path("dir");
        dir2  = path("dir2");

        success = [this](auto err, auto) { CHECK(!err); happens(); };
        fail    = [this](auto err, auto) { CHECK(err); happens(); };
    }

    ~Test () {
        Fs::remove_all(procdir);
    }

    string path (string_view relpath) {
        return procdir + "/" + relpath;
    }
};

namespace sync {

TEST_PREFIX("fs-sync: ", "[fs]");

TEST("mkdir") {
    Test t;
    SECTION("non-existant") {
        auto ret = Fs::mkdir(t.dir);
        REQUIRE(ret);
        CHECK(Fs::isdir(t.dir));
    }
    SECTION("dir exists") {
        Fs::mkdir(t.dir);
        auto ret = Fs::mkdir(t.dir);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::file_exists);
    }
    SECTION("file exists") {
        Fs::touch(t.file);
        auto ret = Fs::mkdir(t.file);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::file_exists);
    }
}

TEST("rmdir") {
    Test t;
    SECTION("non-existant") {
        auto ret = Fs::rmdir(t.dir);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::no_such_file_or_directory);
    }
    SECTION("dir exists") {
        Fs::mkdir(t.dir);
        CHECK(Fs::rmdir(t.dir));
        CHECK(!Fs::isdir(t.dir));
    }
    SECTION("file exists") {
        Fs::touch(t.file);
        auto ret = Fs::rmdir(t.file);
        REQUIRE(!ret);
        CHECK(ret.error()); // code may vary accross platforms
    }
    SECTION("non-empty dir") {
        Fs::mkdir(t.dir);
        Fs::touch(t.path("dir/file"));
        auto ret = Fs::rmdir(t.dir);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::directory_not_empty);
    }
}

TEST("mkpath") {
    Test t;
    SECTION("non-existant") {
        CHECK(Fs::mkpath(t.dir));
        CHECK(Fs::isdir(t.dir));
    }
    SECTION("existant") {
        Fs::mkdir(t.dir);
        CHECK(Fs::mkpath(t.dir));
    }
    SECTION("deep") {
        CHECK(Fs::mkpath(t.path("dir2/dir3////dir4")));
        CHECK(Fs::isdir(t.path("dir2")));
        CHECK(Fs::isdir(t.path("dir2/dir3")));
        CHECK(Fs::isdir(t.path("dir2/dir3/dir4")));
    }
}

TEST("scandir") {
    Test t;
    SECTION("non-existant") {
        auto ret = Fs::scandir(t.dir);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::no_such_file_or_directory);
    }
    SECTION("empty dir") {
        auto ret = Fs::scandir(t.path(""));
        REQUIRE(ret);
        CHECK(ret.value().size() == 0);
    }
    SECTION("file") {
        Fs::touch(t.file);
        auto ret = Fs::scandir(t.file);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::not_a_directory);
    }
    SECTION("dir") {
        Fs::mkdir(t.path("adir"));
        Fs::mkdir(t.path("bdir"));
        Fs::touch(t.path("afile"));
        Fs::touch(t.path("bfile"));
        auto ret = Fs::scandir(t.path(""));
        REQUIRE(ret);
        auto& list = ret.value();
        CHECK(list.size() == 4);
        CHECK(list[0].name() == "adir");
        CHECK(list[0].type() == Fs::FileType::DIR);
        CHECK(list[1].name() == "afile");
        CHECK(list[1].type() == Fs::FileType::FILE);
        CHECK(list[2].name() == "bdir");
        CHECK(list[2].type() == Fs::FileType::DIR);
        CHECK(list[3].name() == "bfile");
        CHECK(list[3].type() == Fs::FileType::FILE);
    }
}

TEST("remove") {
    Test t;
    SECTION("non-existant") {
        CHECK(!Fs::remove(t.file));
    }
    SECTION("file") {
        Fs::touch(t.file);
        CHECK(Fs::remove(t.file));
        CHECK(!Fs::exists(t.file));
    }
    SECTION("dir") {
        Fs::mkdir(t.dir);
        CHECK(Fs::remove(t.dir));
        CHECK(!Fs::exists(t.dir));
    }
    SECTION("non-empty dir") {
        Fs::mkdir(t.dir);
        Fs::touch(t.path("dir/file"));
        auto ret = Fs::remove(t.dir);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::directory_not_empty);
    }
}

TEST("remove_all") {
    Test t;
    SECTION("non-existant") {
        auto ret = Fs::remove_all(t.dir);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::no_such_file_or_directory);
    }
    SECTION("file") {
        Fs::touch(t.file);
        CHECK(Fs::remove_all(t.file));
        CHECK(!Fs::exists(t.file));
    }
    SECTION("dir") {
        Fs::mkpath(t.path("dir/dir1/dir2/dir3"));
        Fs::mkpath(t.path("dir/dir4"));
        Fs::touch(t.path("dir/file1"));
        Fs::touch(t.path("dir/file2"));
        Fs::touch(t.path("dir/dir4/file3"));
        Fs::touch(t.path("dir/dir1/file4"));
        Fs::touch(t.path("dir/dir1/dir2/file5"));
        Fs::touch(t.path("dir/dir1/dir2/dir3/file6"));
        CHECK(Fs::remove_all(t.path("dir")));
        CHECK(!Fs::exists(t.path("dir")));
    }
}

TEST("open/close") {
    Test t;
    SECTION("non-existant no-create") {
        auto ret = Fs::open(t.file, Fs::OpenFlags::RDONLY);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::no_such_file_or_directory);
    }
    SECTION("non-existant create") {
        auto ret = Fs::open(t.file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT);
        CHECK(ret.value());
        CHECK(Fs::close(*ret));
    }
    SECTION("existant") {
        Fs::touch(t.file);
        auto ret = Fs::open(t.file, Fs::OpenFlags::RDONLY);
        REQUIRE(ret);
        Fs::close(*ret);
    }
}

TEST("stat") {
    Test t;
    SECTION("non-existant") {
        auto ret = Fs::stat(t.file);
        CHECK(!ret);
    }
    SECTION("path") {
        Fs::touch(t.file);
        auto ret = Fs::stat(t.file);
        REQUIRE(ret);
        auto s = ret.value();
        CHECK(s.mtime.get());
        CHECK(s.type() == Fs::FileType::FILE);
    }
    SECTION("fd") {
        Fs::touch(t.file);
        auto fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
        auto ret = Fs::stat(fd);
        REQUIRE(ret);
        CHECK(ret.value().type() == Fs::FileType::FILE);
        Fs::close(fd);
    }
}

TEST("statfs") {
    if (win32) return;
    Test t;
    auto ret = Fs::statfs("/");
    REQUIRE(ret);
    auto val = ret.value();
    CHECK(val.bsize);
    CHECK(val.blocks);
}

TEST("exists/isfile/isdir") {
    Test t;
    CHECK(!Fs::exists(t.file));
    CHECK(!Fs::isfile(t.file));
    CHECK(!Fs::isdir(t.file));
    Fs::touch(t.file);
    CHECK(Fs::exists(t.file));
    CHECK(Fs::isfile(t.file));
    CHECK(!Fs::isdir(t.file));
    Fs::mkdir(t.dir);
    CHECK(Fs::exists(t.dir));
    CHECK(!Fs::isfile(t.dir));
    CHECK(Fs::isdir(t.dir));
}

TEST("access") {
    Test t;
    CHECK(!Fs::access(t.file));
    CHECK(!Fs::access(t.file, 4));
    Fs::touch(t.file);
    CHECK(Fs::access(t.file));
    CHECK(Fs::access(t.file, 6));
    if (!win32) {
        CHECK(!Fs::access(t.file, 1));
        CHECK(!Fs::access(t.file, 7));
    }
}

TEST("unlink") {
    Test t;
    SECTION("non-existant") {
        auto ret = Fs::unlink(t.file);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::no_such_file_or_directory);
    }
    SECTION("file") {
        Fs::touch(t.file);
        CHECK(Fs::unlink(t.file));
        CHECK(!Fs::exists(t.file));
    }
    SECTION("dir") {
        Fs::mkdir(t.dir);
        auto ret = Fs::unlink(t.dir);
        REQUIRE(!ret);
        // can't check error - could be any on various platforms
    }
}

TEST("read/write") {
    Test t;
    auto fd = Fs::open(t.file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
    auto s = Fs::read(fd, 100).value();
    CHECK(s == "");

    CHECK(Fs::write(fd, "hello "));
    CHECK(Fs::write(fd, "world"));

    s = Fs::read(fd, 100, 0).value();
    CHECK(s == "hello world");

    std::vector<string_view> sv = {"d", "u", "d", "e"};
    Fs::write(fd, sv.begin(), sv.end(), 6);

    Fs::close(fd);

    CHECK(Fs::stat(t.file).value().size == 11);

    fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
    CHECK(Fs::read(fd, 11).value() == "hello duded");
    Fs::close(fd);
}

TEST("truncate") {
    Test t;
    auto fd = Fs::open(t.file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
    Fs::write(fd, "0123456789");
    Fs::close(fd);
    CHECK(Fs::stat(t.file).value().size == 10);

    fd = Fs::open(t.file, Fs::OpenFlags::RDWR).value();
    Fs::truncate(fd, 5);
    Fs::close(fd);
    CHECK(Fs::stat(t.file).value().size == 5);

    Fs::truncate(t.file);
    CHECK(Fs::stat(t.file).value().size == 0);
}

TEST("chmod") {
    if (win32) return; // it seems win32 ignores chmod
    Test t;
    Fs::touch(t.file, 0644);
    SECTION("path") {
        Fs::chmod(t.file, 0666);
        CHECK(Fs::stat(t.file).value().perms() == 0666);
    }
    SECTION("fd") {
        auto fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
        Fs::chmod(fd, 0600);
        CHECK(Fs::stat(t.file).value().perms() == 0600);
        Fs::close(fd);
    }
}

TEST("touch") {
    Test t;
    SECTION("non-existant") {
        CHECK(Fs::touch(t.file));
        CHECK(Fs::isfile(t.file));
    }
    SECTION("exists") {
        CHECK(Fs::touch(t.file));
        auto s = Fs::stat(t.file).value();
        auto mtime = s.mtime;
        auto atime = s.atime;
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        CHECK(Fs::touch(t.file));
        CHECK(Fs::isfile(t.file));
        s = Fs::stat(t.file).value();
        CHECK(s.mtime > mtime);
        CHECK(s.atime > atime);
    }
}

TEST("utime") {
    Test t;
    SECTION("non-existant") {
        auto ret = Fs::utime(t.file, 1000, 1000);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::no_such_file_or_directory);
    }
    SECTION("path") {
        Fs::touch(t.file);
        CHECK(Fs::utime(t.file, 1000, 1000));
        CHECK(Fs::stat(t.file).value().atime.get() == 1000);
        CHECK(Fs::stat(t.file).value().mtime.get() == 1000);
    }
    if (!win32) // win32 can't set utime via descriptor
        SECTION("fd") {
        Fs::touch(t.file);
        auto fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
        CHECK(Fs::utime(fd, 2000, 2000));
        Fs::close(fd);
        CHECK(Fs::stat(t.file).value().atime.get() == 2000);
        CHECK(Fs::stat(t.file).value().mtime.get() == 2000);
    }
}

// no tests for chown

TEST("rename") {
    Test t;
    SECTION("non-existant") {
        Fs::touch(t.file2);
        auto ret = Fs::rename(t.file, t.file2);
        REQUIRE(!ret);
        CHECK(ret.error() == std::errc::no_such_file_or_directory);
    }
    SECTION("exists file") {
        Fs::touch(t.file);
        CHECK(Fs::rename(t.file, t.file2));
        CHECK(Fs::isfile(t.file2));
    }
    SECTION("exists dir") {
        Fs::mkdir(t.dir);
        CHECK(Fs::rename(t.dir, t.dir2));
        CHECK(Fs::isdir(t.dir2));
    }
}

TEST("mkdtemp") {
    Test t;
    auto ret = Fs::mkdtemp(t.path("tmpXXXXXX")).value();
    CHECK(ret != "");
    CHECK(Fs::isdir(ret));
}

TEST("mkstemp") {
    Test t;
    auto ret = Fs::mkstemp(t.path("tmpXXXXXX")).value();
    CHECK(ret.path != "");
    CHECK(Fs::exists(ret.path));
    Fs::write(ret.fd, "hello world");
    Fs::close(ret.fd);
    CHECK(Fs::stat(ret.path).value().size == 11);
}

}

namespace async {

TEST_PREFIX("fs-async: ", "[fs]");

TEST("fs request") {
    Test t(2000);
    auto req = Fs::mkdtemp(t.path("tmpXXXXXX"), [](auto&&...){}, t.loop);
    CHECK(req->active());
    t.run();
    CHECK_FALSE(req->active());
}

TEST("mkdir") {
    Test t(10000, 1);
    SECTION("ok") {
        Fs::mkdir(t.dir, 0755, t.success, t.loop);
        t.run();
        CHECK(Fs::isdir(t.dir));
    }
    SECTION("err") {
        Fs::mkdir(t.dir);
        Fs::mkdir(t.dir, 0755, [&](auto& err, auto) {
            t.happens();
            CHECK(err == std::errc::file_exists);
        }, t.loop);
        t.run();
    }
}

TEST("rmdir") {
    Test t(10000, 1);
    SECTION("err") {
        Fs::rmdir(t.dir, [&](auto& err, auto) {
            t.happens();
            CHECK(err == std::errc::no_such_file_or_directory);
        }, t.loop);
        t.run();
    }
    SECTION("ok") {
        Fs::mkdir(t.dir);
        Fs::rmdir(t.dir, t.success, t.loop);
        t.run();
        CHECK(!Fs::exists(t.dir));
    }
}

TEST("mkpath") {
    Test t(10000, 1);
    Fs::mkpath(t.path("dir2/dir3////dir4"), 0755, t.success, t.loop);
    t.run();
    CHECK(Fs::isdir(t.path("dir2")));
    CHECK(Fs::isdir(t.path("dir2/dir3")));
    CHECK(Fs::isdir(t.path("dir2/dir3/dir4")));
}

TEST("scandir") {
    Test t(10000, 1);
    Fs::mkdir(t.path("adir"));
    Fs::mkdir(t.path("bdir"));
    Fs::touch(t.path("afile"));
    Fs::touch(t.path("bfile"));
    Fs::scandir(t.path(""), [&](auto& list, auto& err, auto) {
        t.happens();
        REQUIRE(!err);
        REQUIRE(list.size() == 4);
        CHECK(list[0].name() == "adir");
        CHECK(list[0].type() == Fs::FileType::DIR);
        CHECK(list[1].name() == "afile");
        CHECK(list[1].type() == Fs::FileType::FILE);
        CHECK(list[2].name() == "bdir");
        CHECK(list[2].type() == Fs::FileType::DIR);
        CHECK(list[3].name() == "bfile");
        CHECK(list[3].type() == Fs::FileType::FILE);
    }, t.loop);
    t.run();
}

TEST("remove") {
    Test t(10000, 1);
    Fs::touch(t.file);
    Fs::remove(t.file, t.success, t.loop);
    t.run();
    CHECK(!Fs::exists(t.file));
}

TEST("remove_all") {
    Test t(10000, 1);
    Fs::mkpath(t.path("dir/dir1/dir2/dir3"));
    Fs::mkpath(t.path("dir/dir4"));
    Fs::touch(t.path("dir/file1"));
    Fs::touch(t.path("dir/file2"));
    Fs::touch(t.path("dir/dir4/file3"));
    Fs::touch(t.path("dir/dir1/file4"));
    Fs::touch(t.path("dir/dir1/dir2/file5"));
    Fs::touch(t.path("dir/dir1/dir2/dir3/file6"));
    Fs::remove_all(t.dir, t.success, t.loop);
    t.run();
    CHECK(!Fs::exists(t.dir));
}

TEST("open/close") {
    Test t(10000, 1);
    t.set_expected(2);
    Fs::open(t.file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT, 0644, [&](auto fd, auto err, auto) {
        t.happens();
        REQUIRE(!err);
        REQUIRE(fd);
        Fs::close(fd, t.success, t.loop);
    }, t.loop);
    t.run();
}

TEST("stat") {
    Test t(10000, 1);
    Fs::touch(t.file);
    auto cb = [&](auto stat, auto err, auto) {
        CHECK(!err);
        CHECK(stat.mtime.get());
        CHECK(stat.type() == Fs::FileType::FILE);
        t.happens();
    };
    SECTION("path") {
        Fs::stat(t.file, cb, t.loop);
        t.run();
    }
    SECTION("fd") {
        auto fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
        Fs::stat(fd, cb, t.loop);
        t.run();
        Fs::close(fd);
    }
}

TEST("statfs") {
    if (win32) return;
    Test t(10000, 1);
    Fs::statfs("/", [&](auto& info, auto&, auto&){
        t.happens();
        CHECK(info.bsize);
        CHECK(info.blocks);
    }, t.loop);
    t.run();
}

TEST("exists/isfile/isdir") {
    Test t(10000, 1);
    t.set_expected(9);
    auto yes = [&](bool val, auto err, auto) {
        CHECK(!err);
        CHECK(val);
        t.happens();
    };
    auto no = [&](bool val, auto err, auto) {
        CHECK(!err);
        CHECK(!val);
        t.happens();
    };

    Fs::exists(t.file, no, t.loop);
    Fs::isfile(t.file, no, t.loop);
    Fs::isdir(t.file, no, t.loop);
    t.run();

    Fs::touch(t.file);

    Fs::exists(t.file, yes, t.loop);
    Fs::isfile(t.file, yes, t.loop);
    Fs::isdir(t.file, no, t.loop);
    t.run();

    Fs::mkdir(t.dir);

    Fs::exists(t.dir, yes, t.loop);
    Fs::isfile(t.dir, no, t.loop);
    Fs::isdir(t.dir, yes, t.loop);
    t.run();
}

TEST("access") {
    Test t(10000, 1);
    t.set_expected(win32 ? 4 : 6);
    Fs::access(t.file, 0, t.fail, t.loop);
    t.run();
    Fs::access(t.file, 4, t.fail, t.loop);
    t.run();
    Fs::touch(t.file);
    Fs::access(t.file, 0, t.success, t.loop);
    t.run();
    Fs::access(t.file, 6, t.success, t.loop);
    t.run();
    if (!win32) {
        Fs::access(t.file, 1, t.fail, t.loop);
        t.run();
        Fs::access(t.file, 7, t.fail, t.loop);
        t.run();
    }
}

TEST("unlink") {
    Test t(10000, 1);
    Fs::touch(t.file);
    Fs::unlink(t.file, t.success, t.loop);
    t.run();
    CHECK(!Fs::exists(t.file));
}

TEST("read/write") {
    Test t(10000, 1);
    t.set_expected(6);
    auto fd = Fs::open(t.file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
    Fs::read(fd, 100, 0, [&](auto s, auto err, auto) {
        t.happens();
        CHECK(!err);
        CHECK(s == "");
    }, t.loop);
    t.run();

    Fs::write(fd, "hello ", -1, t.success, t.loop);
    t.run();
    Fs::write(fd, "world", -1, t.success, t.loop);
    t.run();

    Fs::read(fd, 100, 0, [&](auto s, auto err, auto){
        t.happens();
        CHECK(!err);
        CHECK(s == "hello world");
    }, t.loop);
    t.run();

    std::vector<string_view> sv = {"d", "u", "d", "e"};
    Fs::write(fd, sv.begin(), sv.end(), 6, t.success, t.loop);
    t.run();

    Fs::close(fd);

    CHECK(Fs::stat(t.file).value().size == 11);

    fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
    Fs::read(fd, 11, 0, [&](auto s, auto err, auto){
        t.happens();
        CHECK(!err);
        CHECK(s == "hello duded");
    }, t.loop);
    t.run();
    Fs::close(fd);
}

TEST("truncate") {
    Test t(10000, 1);
    t.set_expected(2);
    auto fd = Fs::open(t.file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
    Fs::write(fd, "0123456789");
    Fs::close(fd);
    CHECK(Fs::stat(t.file).value().size == 10);

    fd = Fs::open(t.file, Fs::OpenFlags::RDWR).value();
    Fs::truncate(fd, 5, t.success, t.loop);
    t.run();
    Fs::close(fd);
    CHECK(Fs::stat(t.file).value().size == 5);

    Fs::truncate(t.file, 0, t.success, t.loop);
    t.run();
    CHECK(Fs::stat(t.file).value().size == 0);
}

TEST("chmod") {
    if (win32) return;
    Test t(10000, 1);
    Fs::touch(t.file, 0644);
    SECTION("path") {
        Fs::chmod(t.file, 0666, t.success, t.loop);
        t.run();
        CHECK(Fs::stat(t.file).value().perms() == 0666);
    }
    SECTION("fd") {
        auto fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
        Fs::chmod(fd, 0600, t.success, t.loop);
        t.run();
        CHECK(Fs::stat(t.file).value().perms() == 0600);
        Fs::close(fd);
    }
}

TEST("touch") {
    Test t(10000, 1);
    t.set_expected(2);
    Fs::touch(t.file, 0644, t.success, t.loop);
    t.run();
    auto s = Fs::stat(t.file).value();
    auto mtime = s.mtime;
    auto atime = s.atime;
    std::this_thread::sleep_for(std::chrono::milliseconds(1));

    Fs::touch(t.file, 0644, t.success, t.loop);
    t.run();
    CHECK(Fs::isfile(t.file));
    s = Fs::stat(t.file).value();
    CHECK(s.mtime > mtime);
    CHECK(s.atime > atime);
}

TEST("utime") {
    Test t(10000, 1);
    Fs::touch(t.file);
    SECTION("path") {
        Fs::utime(t.file, 1000, 1000, t.success, t.loop);
        t.run();
        CHECK(Fs::stat(t.file).value().atime.get() == 1000);
        CHECK(Fs::stat(t.file).value().mtime.get() == 1000);
    }
    if (!win32)
    SECTION("fd") {
        auto fd = Fs::open(t.file, Fs::OpenFlags::RDONLY).value();
        Fs::utime(fd, 2000, 2000, t.success, t.loop);
        t.run();
        Fs::close(fd);
        CHECK(Fs::stat(t.file).value().atime.get() == 2000);
        CHECK(Fs::stat(t.file).value().mtime.get() == 2000);
    }
}

// no tests for chown

TEST("rename") {
    Test t(10000, 1);
    Fs::touch(t.file);
    Fs::rename(t.file, t.file2, t.success, t.loop);
    t.run();
    CHECK(!Fs::exists(t.file));
    CHECK(Fs::isfile(t.file2));
}

TEST("mkdtemp") {
    Test t(2000, 1);
    Fs::mkdtemp(t.path("tmpXXXXXX"), [&](auto& path, auto& err, auto&){
        REQUIRE(!err);
        CHECK(path != "");
        CHECK(Fs::isdir(path));
        t.happens();
    }, t.loop);
    t.run();
}

TEST("mkstemp") {
    Test t(2000, 1);
    Fs::mkstemp(t.path("tmpXXXXXX"), [&](auto& path, auto fd, auto& err, auto&){
        REQUIRE(!err);
        CHECK(path != "");
        CHECK(Fs::exists(path));
        t.happens();

        Fs::write(fd, "hello world");
        Fs::close(fd);
        CHECK(Fs::stat(path).value().size == 11);
    }, t.loop);
    t.run();
}

}
