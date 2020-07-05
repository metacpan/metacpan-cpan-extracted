#include "logtest.h"

#define TEST(name) TEST_CASE("log-module: " name, "[log-module]")

TEST("modules") {
    SECTION("single") {
        auto mod = new Module("mymod");
        CHECK(mod->name == "mymod");
        set_level(DEBUG, "mymod");
        delete mod;
        CHECK_THROWS(set_level(DEBUG, "mymod"));
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
        CHECK_THROWS(set_level(DEBUG, "mymod"));
        set_level(DEBUG, "mymod::sub"); // submodule still can be used
    }
}

TEST("logging to module") {
    Ctx c;
    static Module mod("mymod1");
    CHECK(mod.name == "mymod1");
    mod.level = DEBUG;

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

    mod.level = NOTICE;

    panda_log_debug("hi");
    CHECK(c.cnt == 0);
    panda_log_debug(mod, "hi");
    CHECK(c.cnt == 0);
}

TEST("set level for module") {
    Ctx c;
    static Module mod("mymod2");
    static Module submod("submod2", &mod);
    mod.level = WARNING;
    submod.level = WARNING;

    SECTION("parent affects all children") {
        panda_log_module.set_level(INFO);
        CHECK(panda_log_module.level == INFO);
        CHECK(mod.level == INFO);
        CHECK(submod.level == INFO);

        //this is the same
        set_level(NOTICE);
        CHECK(panda_log_module.level == NOTICE);
        CHECK(mod.level == NOTICE);
        CHECK(submod.level == NOTICE);
    }

    SECTION("children do not affect parents") {
        mod.set_level(DEBUG);
        CHECK(panda_log_module.level == WARNING);
        CHECK(mod.level == DEBUG);
        CHECK(submod.level == DEBUG);
    }

    SECTION("setting via module's name") {
        set_level(ERROR, "mymod2");
        CHECK(panda_log_module.level == WARNING);
        CHECK(mod.level == ERROR);
        CHECK(submod.level == ERROR);
        set_level(CRITICAL, "mymod2::submod2");
        CHECK(panda_log_module.level == WARNING);
        CHECK(mod.level == ERROR);
        CHECK(submod.level == CRITICAL);
    }
}

TEST("secondary root module") {
    Ctx c;
    static Module rmod("rmod", nullptr);
    static Module rsmod("rsmod", &rmod);
    CHECK(rmod.parent == nullptr);
    rmod.level = INFO;
    rsmod.level = INFO;

    set_level(DEBUG);
    CHECK(panda_log_module.level == DEBUG);
    CHECK(rmod.level == INFO);
    CHECK(rsmod.level == INFO);

    rmod.set_level(WARNING);
    CHECK(panda_log_module.level == DEBUG);
    CHECK(rmod.level == WARNING);
    CHECK(rsmod.level == WARNING);
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
