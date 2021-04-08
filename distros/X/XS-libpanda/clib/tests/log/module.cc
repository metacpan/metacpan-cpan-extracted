#include "logtest.h"

#define TEST(name) TEST_CASE("log-module: " name, "[log-module]")

TEST("modules") {
    SECTION("single") {
        auto mod = new Module("mymod");
        CHECK(mod->name() == "mymod");
        set_level(Level::Debug, "mymod");
        delete mod;
        CHECK_THROWS(set_level(Level::Debug, "mymod"));
    }
    SECTION("with submodule") {
        auto mod = new Module("mymod");
        Module smod("sub", *mod);
        CHECK(mod->name() == "mymod");
        CHECK(smod.name() == "mymod::sub");
        CHECK(mod->children().size() == 1);

        delete mod;
        CHECK(smod.parent() == nullptr); // became a root module
        CHECK(smod.name() == "mymod::sub"); // name didn't change
        CHECK_THROWS(set_level(Level::Debug, "mymod"));
        set_level(Level::Debug, "mymod::sub"); // submodule still can be used
    }
}

TEST("logging to module") {
    Ctx c;
    Module mod("mymod1");
    CHECK(mod.name() == "mymod1");
    mod.set_level(Level::Debug);

    panda_log_verbose_debug("hi");
    CHECK(c.cnt == 0);
    panda_log_verbose_debug(mod, "hi");
    CHECK(c.cnt == 0);

    panda_log_debug("hi");
    CHECK(c.cnt == 0);
    panda_log_debug(mod, "hi");
    c.check_called();
    CHECK(c.info.module == &mod);

    panda_log_warning("hi");
    c.check_called();
    CHECK(c.info.module == &panda_log_module);
    panda_log_warning(mod, "hi");
    c.check_called();
    CHECK(c.info.module == &mod);

    mod.set_level(Level::Notice);

    panda_log_debug("hi");
    CHECK(c.cnt == 0);
    panda_log_debug(mod, "hi");
    CHECK(c.cnt == 0);
}

TEST("set level for module") {
    Ctx c;
    Module mod("mymod2", Level::Warning);
    Module submod("submod2", mod, Level::Warning);

    SECTION("parent affects all children") {
        panda_log_module.set_level(Level::Info);
        CHECK(panda_log_module.level() == Level::Info);
        CHECK(mod.level() == Level::Info);
        CHECK(submod.level() == Level::Info);

        //this is the same
        set_level(Level::Notice);
        CHECK(panda_log_module.level() == Level::Notice);
        CHECK(mod.level() == Level::Notice);
        CHECK(submod.level() == Level::Notice);
    }

    SECTION("children do not affect parents") {
        mod.set_level(Level::Debug);
        CHECK(panda_log_module.level() == Level::Warning);
        CHECK(mod.level() == Level::Debug);
        CHECK(submod.level() == Level::Debug);
    }

    SECTION("setting via module's name") {
        set_level(Level::Error, "mymod2");
        CHECK(panda_log_module.level() == Level::Warning);
        CHECK(mod.level() == Level::Error);
        CHECK(submod.level() == Level::Error);
        set_level(Level::Critical, "mymod2::submod2");
        CHECK(panda_log_module.level() == Level::Warning);
        CHECK(mod.level() == Level::Error);
        CHECK(submod.level() == Level::Critical);
    }
}

TEST("secondary root module") {
    Ctx c;
    Module rmod("rmod", nullptr, Level::Info);
    Module rsmod("rsmod", rmod, Level::Info);
    CHECK(rmod.parent() == nullptr);

    set_level(Level::Debug);
    CHECK(panda_log_module.level() == Level::Debug);
    CHECK(rmod.level() == Level::Info);
    CHECK(rsmod.level() == Level::Info);

    rmod.set_level(Level::Warning);
    CHECK(panda_log_module.level() == Level::Debug);
    CHECK(rmod.level() == Level::Warning);
    CHECK(rsmod.level() == Level::Warning);
}

TEST("logging by scopes") {
    Ctx c;

    panda_log_error("");
    CHECK(c.info.module == &::panda_log_module);

    Module panda_log_module("scope1");
    panda_log_error("");
    CHECK(c.info.module->name() == "scope1");

    {
        panda_log_error("");
        CHECK(c.info.module->name() == "scope1");

        Module panda_log_module("scope2");
        panda_log_error("");
        CHECK(c.info.module->name() == "scope2");
    }
}

TEST("panda_rlog_*") {
    Ctx c;
    Module panda_log_module("non-root");
    panda_rlog_error("");
    CHECK(c.info.module == &::panda_log_module);
}

TEST("set logger/formatter for module") {
    Module root("root", nullptr, Level::Warning);
    Module mod("mod", root, Level::Warning);
    Module submod("submod", mod, Level::Warning);

    using V = std::vector<int>;
    V l,f;

    // parent l/f propagated to children
    root.set_logger([&](const std::string&, const Info&) { l.push_back(1); });
    root.set_formatter([&](std::string&, const Info&) -> string { f.push_back(1); return ""; });
    panda_log_error(root, "");
    panda_log_error(mod, "");
    panda_log_error(submod, "");
    CHECK(l == V{1,1,1});
    CHECK(f == V{1,1,1});
    l.clear(); f.clear();

    // custom l/f used for module and it's children
    mod.set_logger([&](const std::string&, const Info&) { l.push_back(2); });
    mod.set_formatter([&](std::string&, const Info&) -> string { f.push_back(2); ; return ""; });
    panda_log_error(root, "");
    panda_log_error(mod, "");
    panda_log_error(submod, "");
    CHECK(l == V{1,2,2});
    CHECK(f == V{1,2,2});
    l.clear(); f.clear();

    // changing parent's l/f doesn't change explicitly installed l/f in children
    root.set_logger([&](const std::string&, const Info&) { l.push_back(11); });
    root.set_formatter([&](std::string&, const Info&) -> string { f.push_back(11); return ""; });
    panda_log_error(root, "");
    panda_log_error(mod, "");
    panda_log_error(submod, "");
    CHECK(l == V{11,2,2});
    CHECK(f == V{11,2,2});
    l.clear(); f.clear();

    // nulling l/f restores parent's behaviour
    mod.set_logger(nullptr);
    mod.set_formatter(nullptr);
    panda_log_error(root, "");
    panda_log_error(mod, "");
    panda_log_error(submod, "");
    CHECK(l == V{11,11,11});
    CHECK(f == V{11,11,11});
    l.clear(); f.clear();

    // nulling root formatter sets default formatter
    root.set_formatter(nullptr);
    panda_log_error(root, "");
    panda_log_error(mod, "");
    panda_log_error(submod, "");
    CHECK(l == V{11,11,11});
    CHECK(f == V{}); // because default formatter (pattern formatter) is created
    l.clear(); f.clear();

    // nulling root logger disables logging
    root.set_logger(nullptr);
    root.set_formatter([&](std::string&, const Info&) -> string { f.push_back(1); return ""; });
    panda_log_error(root, "");
    panda_log_error(mod, "");
    panda_log_error(submod, "");
    CHECK(l == V{});
    CHECK(f == V{});
    l.clear(); f.clear();

    // nulling root l/f do not disables custom installed l/f in submodules
    mod.set_logger([&](const std::string&, const Info&) { l.push_back(2); });
    mod.set_formatter([&](std::string&, const Info&) -> string { f.push_back(2); ; return ""; });
    root.set_logger(nullptr);
    root.set_formatter(nullptr);
    panda_log_error(root, "");
    panda_log_error(mod, "");
    panda_log_error(submod, "");
    CHECK(l == V{2,2});
    CHECK(f == V{2,2});
    l.clear(); f.clear();
}

TEST("logger passthrough") {
    Module root("root", nullptr, Level::Warning);
    Module mod("mod", root, Level::Warning);
    Module submod("submod", mod, Level::Warning);

    using V = std::vector<int>;
    V l;

    root.set_logger([&](const std::string&, const Info&) { l.push_back(1); }, true); // root module should not passthrough anywhere
    submod.set_logger([&](const std::string&, const Info&) { l.push_back(2); }, true);

    panda_log_error(submod, "");
    CHECK(l == V{2,1});
    l.clear();
}
