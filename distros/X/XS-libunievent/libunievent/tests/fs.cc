#include "lib/test.h"
#include <stdlib.h>

string root_vdir = "tests/var";

#ifdef __WIN32
    static bool win32 = true;
#else
    static bool win32 = false;
#endif

struct VarDir {
    string dir;

    VarDir () {
        dir = root_vdir + "/" + string::from_number(panda::unievent::getpid()) + "-" + string::from_number(rand());
        Fs::mkpath(dir.c_str(), 0755);
    }

    ~VarDir () {
        Fs::remove_all(dir);
    }

    string path (string_view relpath) {
        return dir + "/" + relpath;
    }
};

TEST_CASE("fs-sync", "[fs]") {
    VarDir vdir;
    auto p     = [&](string_view s) { return vdir.path(s); };
    auto file  = p("file");
    auto file2 = p("file2");
    auto dir   = p("dir");
    auto dir2  = p("dir2");

    SECTION("mkdir") {
        SECTION("non-existant") {
            auto ret = Fs::mkdir(dir);
            REQUIRE(ret);
            CHECK(Fs::isdir(dir));
        }
        SECTION("dir exists") {
            Fs::mkdir(dir);
            auto ret = Fs::mkdir(dir);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::file_exists);
        }
        SECTION("file exists") {
            Fs::touch(file);
            auto ret = Fs::mkdir(file);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::file_exists);
        }
    }

    SECTION("rmdir") {
        SECTION("non-existant") {
            auto ret = Fs::rmdir(dir);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::no_such_file_or_directory);
        }
        SECTION("dir exists") {
            Fs::mkdir(dir);
            CHECK(Fs::rmdir(dir));
            CHECK(!Fs::isdir(dir));
        }
        SECTION("file exists") {
            Fs::touch(file);
            auto ret = Fs::rmdir(file);
            REQUIRE(!ret);
            CHECK(ret.error()); // code may vary accross platforms
        }
        SECTION("non-empty dir") {
            Fs::mkdir(dir);
            Fs::touch(p("dir/file"));
            auto ret = Fs::rmdir(dir);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::directory_not_empty);
        }
    }
	
    SECTION("mkpath") {
        SECTION("non-existant") {
            CHECK(Fs::mkpath(dir));
            CHECK(Fs::isdir(dir));
        }
        SECTION("existant") {
            Fs::mkdir(dir);
            CHECK(Fs::mkpath(dir));
        }
        SECTION("deep") {
            CHECK(Fs::mkpath(p("dir2/dir3////dir4")));
            CHECK(Fs::isdir(p("dir2")));
            CHECK(Fs::isdir(p("dir2/dir3")));
            CHECK(Fs::isdir(p("dir2/dir3/dir4")));
        }
    }

    SECTION("scandir") {
        SECTION("non-existant") {
            auto ret = Fs::scandir(dir);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::no_such_file_or_directory);
        }
        SECTION("empty dir") {
            auto ret = Fs::scandir(p(""));
            REQUIRE(ret);
            CHECK(ret.value().size() == 0);
        }
        SECTION("file") {
            Fs::touch(file);
            auto ret = Fs::scandir(file);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::not_a_directory);
        }
        SECTION("dir") {
            Fs::mkdir(p("adir"));
            Fs::mkdir(p("bdir"));
            Fs::touch(p("afile"));
            Fs::touch(p("bfile"));
            auto ret = Fs::scandir(p(""));
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

    SECTION("remove") {
        SECTION("non-existant") {
            CHECK(!Fs::remove(file));
        }
        SECTION("file") {
            Fs::touch(file);
            CHECK(Fs::remove(file));
            CHECK(!Fs::exists(file));
        }
        SECTION("dir") {
            Fs::mkdir(dir);
            CHECK(Fs::remove(dir));
            CHECK(!Fs::exists(dir));
        }
        SECTION("non-empty dir") {
            Fs::mkdir(dir);
            Fs::touch(p("dir/file"));
            auto ret = Fs::remove(dir);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::directory_not_empty);
        }
    }

    SECTION("remove_all") {
        SECTION("non-existant") {
            auto ret = Fs::remove_all(dir);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::no_such_file_or_directory);
        }
        SECTION("file") {
            Fs::touch(file);
            CHECK(Fs::remove_all(file));
            CHECK(!Fs::exists(file));
        }
        SECTION("dir") {
            Fs::mkpath(p("dir/dir1/dir2/dir3"));
            Fs::mkpath(p("dir/dir4"));
            Fs::touch(p("dir/file1"));
            Fs::touch(p("dir/file2"));
            Fs::touch(p("dir/dir4/file3"));
            Fs::touch(p("dir/dir1/file4"));
            Fs::touch(p("dir/dir1/dir2/file5"));
            Fs::touch(p("dir/dir1/dir2/dir3/file6"));
            CHECK(Fs::remove_all(p("dir")));
            CHECK(!Fs::exists(p("dir")));
        }
    }

    SECTION("open/close") {
        SECTION("non-existant no-create") {
            auto ret = Fs::open(file, Fs::OpenFlags::RDONLY);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::no_such_file_or_directory);
        }
        SECTION("non-existant create") {
            auto ret = Fs::open(file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT);
            CHECK(ret.value());
            CHECK(Fs::close(*ret));
        }
        SECTION("existant") {
            Fs::touch(file);
            auto ret = Fs::open(file, Fs::OpenFlags::RDONLY);
            REQUIRE(ret);
            Fs::close(*ret);
        }
    }

    SECTION("stat") {
        SECTION("non-existant") {
            auto ret = Fs::stat(file);
            CHECK(!ret);
        }
        SECTION("path") {
            Fs::touch(file);
            auto ret = Fs::stat(file);
            REQUIRE(ret);
            auto s = ret.value();
            CHECK(s.mtime.get());
            CHECK(s.type() == Fs::FileType::FILE);
        }
        SECTION("fd") {
            Fs::touch(file);
            auto fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
            auto ret = Fs::stat(fd);
            REQUIRE(ret);
            CHECK(ret.value().type() == Fs::FileType::FILE);
            Fs::close(fd);
        }
    }

    SECTION("exists/isfile/isdir") {
        CHECK(!Fs::exists(file));
        CHECK(!Fs::isfile(file));
        CHECK(!Fs::isdir(file));
        Fs::touch(file);
        CHECK(Fs::exists(file));
        CHECK(Fs::isfile(file));
        CHECK(!Fs::isdir(file));
        Fs::mkdir(dir);
        CHECK(Fs::exists(dir));
        CHECK(!Fs::isfile(dir));
        CHECK(Fs::isdir(dir));
    }

    SECTION("access") {
        CHECK(!Fs::access(file));
        CHECK(!Fs::access(file, 4));
        Fs::touch(file);
        CHECK(Fs::access(file));
        CHECK(Fs::access(file, 6));
        if (!win32) {
            CHECK(!Fs::access(file, 1));
            CHECK(!Fs::access(file, 7));
        }
    }

    SECTION("unlink") {
        SECTION("non-existant") {
            auto ret = Fs::unlink(file);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::no_such_file_or_directory);
        }
        SECTION("file") {
            Fs::touch(file);
            CHECK(Fs::unlink(file));
            CHECK(!Fs::exists(file));
        }
        SECTION("dir") {
            Fs::mkdir(dir);
            auto ret = Fs::unlink(dir);
            REQUIRE(!ret);
            // can't check error - could be any on various platforms
        }
    }

    SECTION("read/write") {
        auto fd = Fs::open(file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
        auto s = Fs::read(fd, 100).value();
        CHECK(s == "");

        CHECK(Fs::write(fd, "hello "));
        CHECK(Fs::write(fd, "world"));

        s = Fs::read(fd, 100, 0).value();
        CHECK(s == "hello world");

        std::vector<string_view> sv = {"d", "u", "d", "e"};
        Fs::write(fd, sv.begin(), sv.end(), 6);

        Fs::close(fd);

        CHECK(Fs::stat(file).value().size == 11);

        fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
        CHECK(Fs::read(fd, 11).value() == "hello duded");
        Fs::close(fd);
    }

    SECTION("truncate") {
        auto fd = Fs::open(file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
        Fs::write(fd, "0123456789");
        Fs::close(fd);
        CHECK(Fs::stat(file).value().size == 10);

        fd = Fs::open(file, Fs::OpenFlags::RDWR).value();
        Fs::truncate(fd, 5);
        Fs::close(fd);
        CHECK(Fs::stat(file).value().size == 5);

        Fs::truncate(file);
        CHECK(Fs::stat(file).value().size == 0);
    }

    if (!win32) // it seems win32 ignores chmod
    SECTION("chmod") {
        Fs::touch(file, 0644);
        SECTION("path") {
            Fs::chmod(file, 0666);
            CHECK(Fs::stat(file).value().perms() == 0666);
        }
        SECTION("fd") {
            auto fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
            Fs::chmod(fd, 0600);
            CHECK(Fs::stat(file).value().perms() == 0600);
            Fs::close(fd);
        }
    }

    SECTION("touch") {
        SECTION("non-existant") {
            CHECK(Fs::touch(file));
            CHECK(Fs::isfile(file));
        }
        SECTION("exists") {
            CHECK(Fs::touch(file));
            auto s = Fs::stat(file).value();
            auto mtime = s.mtime;
            auto atime = s.atime;
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
            CHECK(Fs::touch(file));
            CHECK(Fs::isfile(file));
            s = Fs::stat(file).value();
            CHECK(s.mtime > mtime);
            CHECK(s.atime > atime);
        }
    }

    SECTION("utime") {
        SECTION("non-existant") {
            auto ret = Fs::utime(file, 1000, 1000);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::no_such_file_or_directory);
        }
        SECTION("path") {
            Fs::touch(file);
            CHECK(Fs::utime(file, 1000, 1000));
            CHECK(Fs::stat(file).value().atime.get() == 1000);
            CHECK(Fs::stat(file).value().mtime.get() == 1000);
        }
        if (!win32) // win32 can't set utime via descriptor
            SECTION("fd") {
            Fs::touch(file);
            auto fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
            CHECK(Fs::utime(fd, 2000, 2000));
            Fs::close(fd);
            CHECK(Fs::stat(file).value().atime.get() == 2000);
            CHECK(Fs::stat(file).value().mtime.get() == 2000);
        }
    }

    // no tests for chown

    SECTION("rename") {
        SECTION("non-existant") {
            Fs::touch(file2);
            auto ret = Fs::rename(file, file2);
            REQUIRE(!ret);
            CHECK(ret.error() == std::errc::no_such_file_or_directory);
        }
        SECTION("exists file") {
            Fs::touch(file);
            CHECK(Fs::rename(file, file2));
            CHECK(Fs::isfile(file2));
        }
        SECTION("exists dir") {
            Fs::mkdir(dir);
            CHECK(Fs::rename(dir, dir2));
            CHECK(Fs::isdir(dir2));
        }
    }
}

TEST_CASE("fs-async", "[fs]") {
    VarDir vdir;
    AsyncTest test(10000, 1);
    auto l       = test.loop;
    auto p       = [&](string_view s) { return vdir.path(s); };
    auto file    = p("file");
    auto file2   = p("file2");
    auto dir     = p("dir");
    auto dir2    = p("dir2");
    auto success = [&](auto err, auto) { CHECK(!err); test.happens(); };
    auto fail    = [&](auto err, auto) { CHECK(err); test.happens(); };

    SECTION("mkdir") {
        SECTION("ok") {
            Fs::mkdir(dir, 0755, success, l);
            l->run();
            CHECK(Fs::isdir(dir));
        }
        SECTION("err") {
            Fs::mkdir(dir);
            Fs::mkdir(dir, 0755, [&](auto& err, auto) {
                test.happens();
                CHECK(err == std::errc::file_exists);
            }, l);
        }
    }

    SECTION("rmdir") {
        SECTION("err") {
            Fs::rmdir(dir, [&](auto& err, auto) {
                test.happens();
                CHECK(err == std::errc::no_such_file_or_directory);
            }, l);
        }
        SECTION("ok") {
            Fs::mkdir(dir);
            Fs::rmdir(dir, success, l);
            l->run();
            CHECK(!Fs::exists(dir));
        }
    }

    SECTION("mkpath") {
        Fs::mkpath(p("dir2/dir3////dir4"), 0755, success, l);
        l->run();
        CHECK(Fs::isdir(p("dir2")));
        CHECK(Fs::isdir(p("dir2/dir3")));
        CHECK(Fs::isdir(p("dir2/dir3/dir4")));
    }

    SECTION("scandir") {
        Fs::mkdir(p("adir"));
        Fs::mkdir(p("bdir"));
        Fs::touch(p("afile"));
        Fs::touch(p("bfile"));
        Fs::scandir(p(""), [&](auto& list, auto& err, auto) {
            test.happens();
            CHECK(!err);
            CHECK(list.size() == 4);
            CHECK(list[0].name() == "adir");
            CHECK(list[0].type() == Fs::FileType::DIR);
            CHECK(list[1].name() == "afile");
            CHECK(list[1].type() == Fs::FileType::FILE);
            CHECK(list[2].name() == "bdir");
            CHECK(list[2].type() == Fs::FileType::DIR);
            CHECK(list[3].name() == "bfile");
            CHECK(list[3].type() == Fs::FileType::FILE);
        }, l);
    }

    SECTION("remove") {
        Fs::touch(file);
        Fs::remove(file, success, l);
        l->run();
        CHECK(!Fs::exists(file));
    }

    SECTION("remove_all") {
        Fs::mkpath(p("dir/dir1/dir2/dir3"));
        Fs::mkpath(p("dir/dir4"));
        Fs::touch(p("dir/file1"));
        Fs::touch(p("dir/file2"));
        Fs::touch(p("dir/dir4/file3"));
        Fs::touch(p("dir/dir1/file4"));
        Fs::touch(p("dir/dir1/dir2/file5"));
        Fs::touch(p("dir/dir1/dir2/dir3/file6"));
        Fs::remove_all(dir, success, l);
        l->run();
        CHECK(!Fs::exists(dir));
    }

    SECTION("open/close") {
        test.set_expected(2);
        Fs::open(file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT, 0644, [&](auto fd, auto err, auto) {
            test.happens();
            CHECK(!err);
            CHECK(fd);
            Fs::close(fd, success, l);
        }, l);
    }

    SECTION("stat") {
        Fs::touch(file);
        auto cb = [&](auto stat, auto err, auto) {
            CHECK(!err);
            CHECK(stat.mtime.get());
            CHECK(stat.type() == Fs::FileType::FILE);
            test.happens();
        };
        SECTION("path") {
            Fs::stat(file, cb, l);
        }
        SECTION("fd") {
            auto fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
            Fs::stat(fd, cb, l);
            l->run();
            Fs::close(fd);
        }
    }

    SECTION("exists/isfile/isdir") {
        test.set_expected(9);
        auto yes = [&](bool val, auto err, auto) {
            CHECK(!err);
            CHECK(val);
            test.happens();
        };
        auto no = [&](bool val, auto err, auto) {
            CHECK(!err);
            CHECK(!val);
            test.happens();
        };

        Fs::exists(file, no, l);
        Fs::isfile(file, no, l);
        Fs::isdir(file, no, l);
        l->run();

        Fs::touch(file);

        Fs::exists(file, yes, l);
        Fs::isfile(file, yes, l);
        Fs::isdir(file, no, l);
        l->run();

        Fs::mkdir(dir);

        Fs::exists(dir, yes, l);
        Fs::isfile(dir, no, l);
        Fs::isdir(dir, yes, l);
        l->run();
    }

    SECTION("access") {
        test.set_expected(win32 ? 4 : 6);
        Fs::access(file, 0, fail, l);
        l->run();
        Fs::access(file, 4, fail, l);
        l->run();
        Fs::touch(file);
        Fs::access(file, 0, success, l);
        l->run();
        Fs::access(file, 6, success, l);
        l->run();
        if (!win32) {
            Fs::access(file, 1, fail, l);
            l->run();
            Fs::access(file, 7, fail, l);
            l->run();
        }
    }

    SECTION("unlink") {
        Fs::touch(file);
        Fs::unlink(file, success, l);
        l->run();
        CHECK(!Fs::exists(file));
    }

    SECTION("read/write") {
        test.set_expected(6);
        auto fd = Fs::open(file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
        Fs::read(fd, 100, 0, [&](auto s, auto err, auto) {
            test.happens();
            CHECK(!err);
            CHECK(s == "");
        }, l);
        l->run();

        Fs::write(fd, "hello ", -1, success, l);
        l->run();
        Fs::write(fd, "world", -1, success, l);
        l->run();

        Fs::read(fd, 100, 0, [&](auto s, auto err, auto){
            test.happens();
            CHECK(!err);
            CHECK(s == "hello world");
        }, l);
        l->run();

        std::vector<string_view> sv = {"d", "u", "d", "e"};
        Fs::write(fd, sv.begin(), sv.end(), 6, success, l);
        l->run();

        Fs::close(fd);

        CHECK(Fs::stat(file).value().size == 11);

        fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
        Fs::read(fd, 11, 0, [&](auto s, auto err, auto){
            test.happens();
            CHECK(!err);
            CHECK(s == "hello duded");
        }, l);
        l->run();
        Fs::close(fd);
    }

    SECTION("truncate") {
        test.set_expected(2);
        auto fd = Fs::open(file, Fs::OpenFlags::RDWR | Fs::OpenFlags::CREAT).value();
        Fs::write(fd, "0123456789");
        Fs::close(fd);
        CHECK(Fs::stat(file).value().size == 10);

        fd = Fs::open(file, Fs::OpenFlags::RDWR).value();
        Fs::truncate(fd, 5, success, l);
        l->run();
        Fs::close(fd);
        CHECK(Fs::stat(file).value().size == 5);

        Fs::truncate(file, 0, success, l);
        l->run();
        CHECK(Fs::stat(file).value().size == 0);
    }

    if (!win32)
    SECTION("chmod") {
        Fs::touch(file, 0644);
        SECTION("path") {
            Fs::chmod(file, 0666, success, l);
            l->run();
            CHECK(Fs::stat(file).value().perms() == 0666);
        }
        SECTION("fd") {
            auto fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
            Fs::chmod(fd, 0600, success, l);
            l->run();
            CHECK(Fs::stat(file).value().perms() == 0600);
            Fs::close(fd);
        }
    }

    SECTION("touch") {
        test.set_expected(2);
        Fs::touch(file, 0644, success, l);
        l->run();
        auto s = Fs::stat(file).value();
        auto mtime = s.mtime;
        auto atime = s.atime;
        std::this_thread::sleep_for(std::chrono::milliseconds(1));

        Fs::touch(file, 0644, success, l);
        l->run();
        CHECK(Fs::isfile(file));
        s = Fs::stat(file).value();
        CHECK(s.mtime > mtime);
        CHECK(s.atime > atime);
    }

    SECTION("utime") {
        Fs::touch(file);
        SECTION("path") {
            Fs::utime(file, 1000, 1000, success, l);
            l->run();
            CHECK(Fs::stat(file).value().atime.get() == 1000);
            CHECK(Fs::stat(file).value().mtime.get() == 1000);
        }
        if (!win32)
        SECTION("fd") {
            auto fd = Fs::open(file, Fs::OpenFlags::RDONLY).value();
            Fs::utime(fd, 2000, 2000, success, l);
            l->run();
            Fs::close(fd);
            CHECK(Fs::stat(file).value().atime.get() == 2000);
            CHECK(Fs::stat(file).value().mtime.get() == 2000);
        }
    }

    // no tests for chown

    SECTION("rename") {
        Fs::touch(file);
        Fs::rename(file, file2, success, l);
        l->run();
        CHECK(!Fs::exists(file));
        CHECK(Fs::isfile(file2));
    }

    l->run();
}
