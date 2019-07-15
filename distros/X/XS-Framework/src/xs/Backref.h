#pragma once
#include <xs/basic.h>
#include <memory>
#include <stdexcept>
#include <panda/cast.h>
#include <panda/refcnt.h>

namespace xs {

class Backref {
public:
    mutable SV*  svobj;
    mutable bool zombie;
    mutable bool in_cdtor;

    template <class T> static const Backref* get (T* var)                        { return panda::dyn_cast<const Backref*>(var); }
    template <class T> static const Backref* get (const panda::iptr<T>& var)     { return panda::dyn_cast<const Backref*>(var.get()); }
    template <class T> static const Backref* get (const std::shared_ptr<T>& var) { return panda::dyn_cast<const Backref*>(var.get()); }

protected:
    Backref () : svobj(NULL), zombie(false), in_cdtor(false) {}

    void dtor () const {
        in_cdtor = true;
        if (!svobj) return;
        auto tmp = svobj;
        svobj = NULL;
        SvREFCNT_dec_NN(tmp);
    };

    virtual ~Backref () { if (!in_cdtor) _throw_no_dtor(); } // protect against forgetting calling the dtor()

private:
    static void _throw_no_dtor () {
        throw std::logic_error("~Backref panic: dtor() wasn't called - you must explicitly call Backref::dtor() or use make_backref()");
    }
};

template <class CLASS>
class BackrefWrapper : public CLASS, public Backref {
    ~BackrefWrapper () override { Backref::dtor(); }
public:
    template <typename... Args> BackrefWrapper (Args&&... args) : CLASS(std::forward<Args>(args)...) {}
};

template <typename CLASS, typename... Args> inline CLASS* make_backref (Args&&... args) {
     return new BackrefWrapper<CLASS>(std::forward<Args>(args)...);
}

}
