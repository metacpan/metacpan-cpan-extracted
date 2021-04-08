#include <catch2/catch.hpp>
#include <panda/log.h>

using namespace panda;
using namespace panda::log;

struct Ctx {
    int       cnt = 0;
    Info      info;
    string    str;
    string    fstr;

    Ctx () {
        set_logger([this](std::string& _str, const Info& _info, const IFormatter& formatter) {
            info  = _info;
            str   = string(_str.data(), _str.length());
            fstr  = formatter.format(_str, _info);
            ++cnt;
        });
        set_level(Level::Warning);
    }

    void check_called () {
        REQUIRE(cnt == 1);
        cnt = 0;
    }
};
