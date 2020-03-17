#pragma once
#include <xs/Object.h>

namespace xs { namespace unievent {

extern Sv::payload_marker_t event_listener_marker;

struct XSListener {
    Ref  objref;
    bool self;

    // methname is recommended to be a shared hash string for performance.
    template <class Ctx = void, class...Args>
    Sub::call_t<Ctx> call (const Simple& methname, const Sv& handle, Args&&...args) {
        if (self) {
            Object obj = handle;
            Sub cv = obj.method(methname);
            if (cv) return cv.call<Ctx>(handle, std::forward<Args>(args)...);
        } else {
            Object obj = objref.value<Object>();
            if (!obj) _throw_noobj(methname);
            Sub cv = obj.method(methname);
            if (cv) return cv.call<Ctx>(objref, handle, std::forward<Args>(args)...);
        }
        return Sub::call_t<Ctx>(); // return empty scalar (or void)
    }

    virtual ~XSListener () {}

private:
    void _throw_noobj (const Simple&);
};

template <class LISTENER, class HANDLE>
Ref event_listener (HANDLE* handle, Object obj, const Sv& svnewl, bool weak) {
    auto lst = (XSListener*)obj.payload(&event_listener_marker).ptr;
    if (svnewl) {
        if (!svnewl.defined()) {
            if (lst) {
                handle->event_listener(nullptr);
                obj.payload_detach(&event_listener_marker);
            }
            return {};
        }
        if (!lst) {
            auto newl = new LISTENER();
            handle->event_listener(newl);
            lst = newl;
            obj.payload_attach(lst, &event_listener_marker);
        }
        Object objnewl = svnewl;
        if (objnewl == obj) lst->self = true;
        else {
            lst->objref = Ref::create(objnewl);
            if (weak) sv_rvweaken(lst->objref);
        }
        return {};
    }
    return lst ? lst->objref : Ref();
}

}}
