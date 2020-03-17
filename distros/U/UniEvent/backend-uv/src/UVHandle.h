#pragma once
#include "inc.h"
#include <panda/unievent/backend/HandleImpl.h>

namespace panda { namespace unievent { namespace backend { namespace uv {

template <class Base, class UvHandle>
struct UVHandle : Base {
protected:
    UvHandle uvh;

    template <class...Args>
    UVHandle (Args&&...args) : Base(args...) {
        _ECTOR();
        uvh.data = static_cast<HandleImpl*>(this);
    }

    bool active () const override {
        return uv_is_active(uvhp());
    }

    void set_weak () override {
        uv_unref(uvhp());
    }

    void unset_weak () override {
        uv_ref(uvhp());
    }

    void destroy () noexcept override {
        panda_mlog_verbose_debug(uelog, _type_name(uvhp()) << "::destroy " << this);
        this->listener = nullptr;
        uv_close(uvhp(), uvx_on_close);
    }

    const uv_handle_t* uvhp () const { return (const uv_handle_t*)&uvh; }
          uv_handle_t* uvhp ()       { return (uv_handle_t*)&uvh; }

private:
    static void uvx_on_close (uv_handle_t* p) {
        auto h = get_handle(p);
        panda_mlog_verbose_debug(uelog, "uvx_on_close " << h << " " << _type_name(p));
        delete h;
    }

    static const char* _type_name (uv_handle_t* p) {
#       define XX(uc,lc) case UV_##uc : return #lc;
        switch (p->type) {
            UV_HANDLE_TYPE_MAP(XX)
            case UV_FILE: return "file";
            default: break;
        }
#       undef XX
        return "";
    }
};

}}}}
