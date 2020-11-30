#include "logtest.h"

#define TEST(name) TEST_CASE("log-module: " name, "[log-module]")

TEST("modules") {
    SECTION("single") {
        auto mod = new Module("mymod");
        CHECK(mod->name == "mymod");
        set_level(Level::Debug, "mymod");
        delete mod;
        CHECK_THROWS(set_level(Level::Debug, "mymod"));
    }
    SECTION("with submodule") {
        auto mod = new Module("mymod");
        Module smod("sub", mod);
        CHECK(mod->name == "mymod");
        CHECK(smod.name == "mymod::sub");
        CHECK(mod->children.size() == 1);

        delete mod;
        CHECK(smod.parent == nullptr); // became a root module
        CHECK(smod.name == "mymod::sub"); // name didn't change
        CHECK_THROWS(set_level(Level::Debug, "mymod"));
        set_level(Level::Debug, "mymod::sub"); // submodule still can be used
    }
}

TEST("logging to module") {
    Ctx c;
    static Module mod("mymod1");
    CHECK(mod.name == "mymod1");
    mod.level = Level::Debug;

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

    mod.level = Level::Notice;

    panda_log_debug("hi");
    CHECK(c.cnt == 0);
    panda_log_debug(mod, "hi");
    CHECK(c.cnt == 0);
}

TEST("set level for module") {
    Ctx c;
    static Module mod("mymod2");
    static Module submod("submod2", &mod);
    mod.level = Level::Warning;
    submod.level = Level::Warning;

    SECTION("parent affects all children") {
        panda_log_module.set_level(Level::Info);
        CHECK(panda_log_module.level == Level::Info);
        CHECK(mod.level == Level::Info);
        CHECK(submod.level == Level::Info);

        //this is the same
        set_level(Level::Notice);
        CHECK(panda_log_module.level == Level::Notice);
        CHECK(mod.level == Level::Notice);
        CHECK(submod.level == Level::Notice);
    }

    SECTION("children do not affect parents") {
        mod.set_level(Level::Debug);
        CHECK(panda_log_module.level == Level::Warning);
        CHECK(mod.level == Level::Debug);
        CHECK(submod.level == Level::Debug);
    }

    SECTION("setting via module's name") {
        set_level(Level::Error, "mymod2");
        CHECK(panda_log_module.level == Level::Warning);
        CHECK(mod.level == Level::Error);
        CHECK(submod.level == Level::Error);
        set_level(Level::Critical, "mymod2::submod2");
        CHECK(panda_log_module.level == Level::Warning);
        CHECK(mod.level == Level::Error);
        CHECK(submod.level == Level::Critical);
    }
}

TEST("secondary root module") {
    Ctx c;
    static Module rmod("rmod", nullptr);
    static Module rsmod("rsmod", &rmod);
    CHECK(rmod.parent == nullptr);
    rmod.level = Level::Info;
    rsmod.level = Level::Info;

    set_level(Level::Debug);
    CHECK(panda_log_module.level == Level::Debug);
    CHECK(rmod.level == Level::Info);
    CHECK(rsmod.level == Level::Info);

    rmod.set_level(Level::Warning);
    CHECK(panda_log_module.level == Level::Debug);
    CHECK(rmod.level == Level::Warning);
    CHECK(rsmod.level == Level::Warning);
}

TEST("logging by scopes") {
    Ctx c;

    panda_log_error("");
    CHECK(c.info.module == &::panda_log_module);

    static Module panda_log_module("scope1");
    panda_log_error("");
    CHECK(c.info.module->name == "scope1");

    {
        panda_log_error("");
        CHECK(c.info.module->name == "scope1");

        static Module panda_log_module("scope2");
        panda_log_error("");
        CHECK(c.info.module->name == "scope2");
    }
}

TEST("panda_rlog_*") {
    Ctx c;
    static Module panda_log_module("non-root");
    panda_rlog_error("");
    CHECK(c.info.module == &::panda_log_module);
}
