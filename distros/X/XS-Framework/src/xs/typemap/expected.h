#pragma once
#include "base.h"
#include <panda/expected.h>
#include <panda/excepted.h>

#define XSRETURN_EXPECTED(val) do { xs::expected_to_stack(val, MARK, ax); return; } while (0)

namespace xs {

    template <class T>
    void _expected_to_stack (const T& ret, SV**& sp, I32& ax, std::false_type) {
        auto wcnt = Sub::want_count();
        if (ret) {
            mXPUSHs(xs::out(ret.value()).detach());
            if (wcnt == 2) {
                XPUSHs(&PL_sv_undef);
                XSRETURN(2);
            }
            XSRETURN(1);
        }
        if (wcnt != 2) throw ret.error();
        XPUSHs(&PL_sv_undef);
        mXPUSHs(xs::out(ret.error()).detach());
        XSRETURN(2);
    }

    template <class T>
    void _expected_to_stack (const T& ret, SV**& sp, I32& ax, std::true_type) {
        auto wcnt = Sub::want_count();
        if (wcnt == 0) {
            if (!ret) throw ret.error();
            XSRETURN_EMPTY;
        }
        XPUSHs(boolSV(ret));
        if (wcnt == 2) {
            if (ret) XPUSHs(&PL_sv_undef);
            else     mXPUSHs(xs::out(ret.error()).detach());
            XSRETURN(2);
        }
        XSRETURN(1);
    }

    template <class TYPE, class ERROR>
    void expected_to_stack (const panda::excepted<TYPE,ERROR>& ret, SV**& sp, I32& ax) {
        return _expected_to_stack(ret, sp, ax, std::is_same<void,TYPE>());
    }

    template <class TYPE, class ERROR>
    void expected_to_stack (const panda::expected<TYPE,ERROR>& ret, SV**& sp, I32& ax) {
        return _expected_to_stack(ret, sp, ax, std::is_same<void,TYPE>());
    }

}
