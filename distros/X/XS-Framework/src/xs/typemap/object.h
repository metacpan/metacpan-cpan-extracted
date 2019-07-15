#pragma once
#include "base.h"
#include "../Ref.h"
#include "../Stash.h"
#include "../Backref.h"
#include <typeinfo>
#include <panda/refcnt.h>

namespace xs {

using panda::refcnt_inc;
using panda::refcnt_dec;
using panda::refcnt_get;

namespace typemap { namespace object {
    using svt_clear_t = int(*)(pTHX_ SV*, MAGIC*);
    using svt_copy_t  = int(*)(pTHX_ SV*, MAGIC*, SV*, const char*, I32);

    extern CV*        fake_dtor;
    extern svt_copy_t backref_marker;

    void init (pTHX);

    template <class T> struct TypemapMarker {
        static int func (pTHX_ SV*, MAGIC*) { return 0; }
        PANDA_GLOBAL_MEMBER_PTR(TypemapMarker, svt_clear_t, get, &func);
    };

    void _throw_no_package (const std::type_info&);
}}

template <class TYPEMAP, class TYPE>
struct ObjectStorageIV {
    static const bool auto_disposable = false;

    static inline void* get (SV* arg) {
        return SvIOK(arg) ? (void*)SvIVX(arg) : nullptr;
    }

    static inline void set (SV* arg, void* ptr) {
        SvIOK_on(arg);
        SvIVX(arg) = (IV)ptr;
    }

    static Sv out (pTHX_ const TYPE& var, const Sv& proto) {
        return Typemap<TYPE>::create(aTHX_ var, proto);
    }
};

template <class TYPEMAP, class TYPE, class BACKREF>
struct ObjectStorageMG_Impl {
    using PURE_TYPEMAP = std::remove_const_t<std::remove_pointer_t<std::remove_reference_t<TYPEMAP>>>;

    static const bool auto_disposable = true;

    static inline void* get (SV* arg) {
        MAGIC* mg = _get_magic(arg);
        return mg ? mg->mg_ptr : NULL;
    }

    static inline void set (SV* arg, void* ptr) {
        auto marker = xs::Sv::PayloadMarker<TYPE>::get();
        marker->svt_clear = typemap::object::TypemapMarker<PURE_TYPEMAP>::get();
        marker->svt_free = _on_free;
        _set_br(marker, BACKREF());

        MAGIC* mg;
        Newx(mg, 1, MAGIC);
        mg->mg_moremagic = SvMAGIC(arg);
        SvMAGIC_set(arg, mg);
        mg->mg_virtual = marker;
        mg->mg_type = PERL_MAGIC_ext;
        mg->mg_len = 0;
        mg->mg_obj = nullptr;
        mg->mg_ptr = (char*)ptr;
        mg->mg_private = 0;

        #ifdef USE_ITHREADS
            marker->svt_dup = _on_svdup;
            mg->mg_flags = MGf_DUP;
        #else
            mg->mg_flags = 0;
        #endif
    }

    static Sv out (pTHX_ const TYPE& var, const Sv& proto) { return _out(aTHX_ var, proto, BACKREF()); }

private:
    static inline MAGIC* _get_magic (SV* sv) {
        auto marker = typemap::object::TypemapMarker<PURE_TYPEMAP>::get();
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) if (mg->mg_virtual && mg->mg_virtual->svt_clear == marker) return mg;
        return NULL;
    }

    static inline void _set_br (Sv::payload_marker_t*,        std::false_type) {}
    static inline void _set_br (Sv::payload_marker_t* marker, std::true_type)  {
        marker->svt_copy  = typemap::object::backref_marker;
        marker->svt_local = _destroy_hook;
    }

    static inline Sv _out (pTHX_ const TYPE& var, const Sv& proto, std::false_type) { return Typemap<TYPE>::create(aTHX_ var, proto); }

    static inline Sv _out (pTHX_ const TYPE& var, const Sv& proto, std::true_type) {
        auto br = Backref::get(var);
        if (!br) return Typemap<TYPE>::create(aTHX_ var, proto);
        if (br->svobj) {
            if (!std::is_const<std::remove_pointer_t<TYPE>>::value) SvREADONLY_off(br->svobj);
            if (!br->zombie) return Ref::create(br->svobj);
            _from_zombie(Typemap<TYPE>::IType::template cast<TYPEMAP>(var), br->svobj, _get_magic(br->svobj), br);
            return Sv::noinc(newRV_noinc(br->svobj));
        }
        auto ret = Typemap<TYPE>::create(aTHX_ var, proto);
        br->svobj = SvRV(ret);
        return ret;
    }

    // this hook is invoked before perl frees SV and before DESTROY() method if SV is an object
    // if non-zero value is returned then the destruction of SV is completely aborted (and DESTROY() method is not called)
    static int _destroy_hook (pTHX_ SV* sv, MAGIC* mg) { return throw_guard(aTHX_ Sub(), [=]() -> int {
        TYPEMAP var = Typemap<TYPE>::IType::template in<TYPEMAP>(mg->mg_ptr);
        auto br = Backref::get(var);
        if (!br) return 0;

        if (br->zombie) {
            // as no one has strong reference to our zombie SV backref, its destruction is only possible in 2 cases:
            // - decremented from C destructor of XSBackref class
            // - perl is cleaning his arena in destruction phase
            _restore_dtor(sv);
            _from_zombie(var, sv, mg, br);
            if (br->in_cdtor) Typemap<TYPE>::IType::retain(var); // avoid double deletion if refcnt policy of 'var' drops to 0 during deletion
            else assert(PL_in_clean_objs);
            return 0;
        }

        // if we are the only owner or in global destroy phase there is no sense of making zombie
        if (Typemap<TYPE>::IType::use_count(var) <= 1 || PL_in_clean_objs) {
            _restore_dtor(sv);
            br->svobj = NULL;
            return 0;
        }

        // perl SV goes out of scope, but C object is still accessible -> save SV to zombie
        _to_zombie(var, sv, mg, br);
        return 1;
    });}

    struct ZombieMarker {};

    static inline MAGIC* _zombie_get_stash_magic (HV* stash) {
        auto marker = xs::Sv::PayloadMarker<ZombieMarker>::get();
        MAGIC *mg;
        for (mg = SvMAGIC(stash); mg; mg = mg->mg_moremagic) if (mg->mg_virtual == marker) return mg;
        return NULL;
    }

    // prevent S_curse from calling dtor
    static inline void _ignore_dtor (SV* sv) {
        auto stash = SvSTASH(sv);
        auto meta = HvMROMETA(stash);
        if (meta->destroy == typemap::object::fake_dtor) return;
        auto stmg = _zombie_get_stash_magic(stash);
        if (!stmg) stmg = Sv(stash).payload_attach(Sv::Payload(), xs::Sv::PayloadMarker<ZombieMarker>::get());
        stmg->mg_obj = (SV*)meta->destroy;
        stmg->mg_ptr = (char*)(uint64_t)meta->destroy_gen;
        meta->destroy = typemap::object::fake_dtor;
        meta->destroy_gen = PL_sub_generation; // make cache valid
    }

    static inline void _restore_dtor (SV* sv) {
        auto stash = SvSTASH(sv);
        auto meta = HvMROMETA(stash);
        if (meta->destroy != typemap::object::fake_dtor) return;
        auto stmg = _zombie_get_stash_magic(stash);
        meta->destroy = (CV*)stmg->mg_obj; // restore dtor
        meta->destroy_gen = (uint64_t)stmg->mg_ptr;
    }

    static inline void _to_zombie (const TYPEMAP& var, SV* sv, MAGIC*, const Backref* br) {
        br->zombie = true;
        SvREFCNT(sv)++;
        Typemap<TYPE>::IType::release(var);
        _ignore_dtor(sv);
    }

    static inline void _from_zombie (const TYPEMAP& var, SV*, MAGIC*, const Backref* br) {
        br->zombie = false;
        Typemap<TYPE>::IType::retain(var);
    }

    static int _on_free (pTHX_ SV* sv, MAGIC* mg) {return throw_guard(aTHX_ Sub(), [=]() -> int {
        using IType = typename Typemap<TYPE>::IType;
        TYPEMAP downgraded = IType::template in<TYPEMAP>(mg->mg_ptr);
        TYPE var = Typemap<TYPE>::template cast<TYPE,TYPEMAP>(downgraded);
        if (!var) throw "TYPEMAP PANIC: bad object in sv";
        Typemap<TYPE>::dispose(aTHX_ var, sv);
        return 0;
    });}

    static int _on_svdup (pTHX_ MAGIC* mg, CLONE_PARAMS*) { return throw_guard(aTHX_ Sub(), [=]() -> int {
        using IType = typename Typemap<TYPE>::IType;
        TYPEMAP downgraded = IType::template in<TYPEMAP>(mg->mg_ptr);
        TYPEMAP new_downgraded = Typemap<TYPE>::dup(downgraded);
        _on_svdup_br(aTHX_ downgraded, new_downgraded, BACKREF());
        mg->mg_ptr = (char*)IType::out(new_downgraded);
        return 0;
    });}

    static void _on_svdup_br (pTHX_ const TYPEMAP&,     const TYPEMAP&,         std::false_type) {}
    static void _on_svdup_br (pTHX_ const TYPEMAP& var, const TYPEMAP& new_var, std::true_type)  {
        auto br     = Backref::get(var);
        auto new_br = Backref::get(new_var);
        if (br && br->svobj && new_br) {
            new_br->svobj = MUTABLE_SV(ptr_table_fetch(PL_ptr_table, br->svobj));
            assert(new_br->svobj);
        }
    }
};

template <class TYPEMAP, class TYPE> using ObjectStorageMG        = ObjectStorageMG_Impl<TYPEMAP,TYPE,std::false_type>;
template <class TYPEMAP, class TYPE> using ObjectStorageMGBackref = ObjectStorageMG_Impl<TYPEMAP,TYPE,std::true_type>;

struct ObjectTypePtr {
    template <class T> static inline T           in      (void* p)     { return static_cast<T>(p); }
    template <class T> static inline const void* out     (T* var)      { return var; }
    template <class T> static inline void        destroy (T* var, SV*) { delete var; }

    template <class TO, class FROM> static inline TO cast    (FROM* var) { return static_cast<TO>(const_cast<std::remove_const_t<FROM>*>(var)); }
    template <class TO, class FROM> static inline TO upgrade (FROM* var) { return panda::dyn_cast<TO>(var); }
};

struct ObjectTypeForeignPtr {
    template <class T> static inline T           in      (void* p) { return static_cast<T>(p); }
    template <class T> static inline const void* out     (T* var)  { return var; }
    template <class T> static inline void        destroy (T*, SV*) {}

    template <class TO, class FROM> static inline TO cast    (FROM* var) { return static_cast<TO>(const_cast<std::remove_const_t<FROM>*>(var)); }
    template <class TO, class FROM> static inline TO upgrade (FROM* var) { return panda::dyn_cast<TO>(var); }
};

struct ObjectTypeRefcntPtr {
    template <class T> static inline T           in        (void* p)     { return static_cast<T>(p); }
    template <class T> static inline const void* out       (T* var)      { refcnt_inc(var); return var; }
    template <class T> static inline void        destroy   (T* var, SV*) { refcnt_dec(var); }
    template <class T> static inline void        retain    (T* var)      { refcnt_inc(var); }
    template <class T> static inline void        release   (T* var)      { refcnt_dec(var); }
    template <class T> static inline uint32_t    use_count (T* var)      { return refcnt_get(var); }

    template <class TO, class FROM> static inline TO cast    (FROM* var) { return static_cast<TO>(const_cast<std::remove_const_t<FROM>*>(var)); }
    template <class TO, class FROM> static inline TO upgrade (FROM* var) { return panda::dyn_cast<TO>(var); }
};

struct ObjectTypeSharedPtr {
    template <class T> static inline T           in  (void* p)                       { return *(static_cast<T*>(p)); }
    template <class T> static inline const void* out (const std::shared_ptr<T>& var) { return new std::shared_ptr<T>(var); }

    template <class T> static inline void retain (const std::shared_ptr<T>& var) {
        char tmp[sizeof(var)];
        new (tmp) std::shared_ptr<T>(var);
    }

    template <class T> static inline void release (const std::shared_ptr<T>& var) {
        std::shared_ptr<T> tmp;
        memcpy(&tmp, &var, sizeof(tmp));
    }

    template <class T> static inline uint32_t use_count (const std::shared_ptr<T>& var) { return var.use_count() - 1; }

    template <class T> static inline void destroy (const std::shared_ptr<T>&, SV* arg) {
        using sp_t = std::shared_ptr<T>;
        void* p = Typemap<sp_t>::IStorage::get(arg);
        delete static_cast<sp_t*>(p);
    }

    template <class TO, class FROM> static inline TO cast (const std::shared_ptr<FROM>& var) {
        return std::static_pointer_cast<typename TO::element_type>(std::const_pointer_cast<std::remove_const_t<FROM>>(var));
    }

    template <class TO, class FROM> static inline TO upgrade (const std::shared_ptr<FROM>& var) {
        return std::dynamic_pointer_cast<typename TO::element_type>(var);
    }
};

using StaticCast  = std::true_type;
using DynamicCast = std::false_type;

template <class TYPEMAP, class TYPE, class _IType, template<class,class> class _IStorage, class CastType = StaticCast>
struct TypemapObject : TypemapBase<TYPEMAP, TYPE> {
    using IType    = _IType;
    using IStorage = _IStorage<TYPEMAP,TYPE>;
    using TypeNP   = typename std::remove_pointer<TYPE>::type;

    static TYPE in (pTHX_ SV* arg) {
        if (!SvOBJECT(arg)) {
            if (SvROK(arg)) {
                arg = SvRV(arg);
                if (!SvOBJECT(arg)) throw "arg is a reference to non-object";
            }
            else if (!SvOK(arg)) return TYPE();
            else throw "arg is not a reference to object";
        }

        auto ptr = IStorage::get(arg);
        if (ptr) {
            TYPEMAP downgraded = IType::template in<TYPEMAP>(ptr);
            TYPE ret = cast<TYPE,TYPEMAP>(downgraded);
            if (ret) {
                if (!std::is_const<TypeNP>::value && SvREADONLY(arg)) throw "cannot modify read-only object";
                return ret;
            }
        }

        throw "arg is an incorrect or corrupted object";
    }

    static Sv out (pTHX_ const TYPE& var, const Sv& proto = Sv()) { return IStorage::out(aTHX_ var, proto); }

    /* proto is a hint for TypemapObject's out/create to attach 'var' to
     * it might be:
     * 1) blessed object (or reference to it): in this case it is used as final object
     *    typical usage - when calling next method
     *    PROTO = stash.call_next(...);
     * 2) class name or stash to bless to: in this case reference to undef is created and blessed into this class
     *    typical usage - in constructor, to bless to the class 'new' was called into, not to default class
     *    PROTO = ST(0);
     * 3) other values (or reference to it): in this case it is blessed to typemap's default class and used
     *    typical usage - in constructor or in overloaded typemap's create() method to specify object's base
     *    PROTO = Array::create();
     * 4) empty: in this case reference to undef is created and blessed to typemap's default class and used
     */
    static Sv create (pTHX_ const TYPE& var, const Sv& proto = Sv()) {
        if (!var) return &PL_sv_undef;
        Sv rv;
        SV* base;
        if (proto) {
            if (SvROK(proto)) { // ref to object/base
                rv = proto;
                base = SvRV(proto);
            }
            else if (proto.type() < SVt_PVMG) { // class name
                base = newSV_type(SVt_PVMG);
                rv = Sv::noinc(newRV_noinc(base));
                sv_bless(rv, gv_stashsv(proto, GV_ADD));
                goto ATTACH; // skip optional blessing
            }
            else if (proto.type() == SVt_PVHV && HvNAME(proto)) { // stash
                base = newSV_type(SVt_PVMG);
                rv = Sv::noinc(newRV_noinc(base));
                sv_bless(rv, proto.get<HV>());
                goto ATTACH; // skip optional blessing
            }
            else { // base given
                rv = Sv::noinc(newRV(proto));
                base = proto;
            }
        }
        else { // nothing given, create ref to undef
            base = newSV_type(SVt_PVMG);
            rv = Sv::noinc(newRV_noinc(base));
            goto BLESS; // definitely needs blessing
        }

        if (!SvOBJECT(base)) { // not blessed -> bless to default typemap's class
            BLESS:
            static PERL_THREAD_LOCAL HV* stash = gv_stashpvn(Typemap<TYPE>::package().data(), Typemap<TYPE>::package().length(), GV_ADD);
            sv_bless(rv, stash); // TODO: custom faster bless
        }

        ATTACH:
        IStorage::set(base, const_cast<void*>(IType::out(IType::template cast<TYPEMAP>(var))));

        if (std::is_const<TypeNP>::value) SvREADONLY_on(base);

        return rv;
    }

    static TYPEMAP dup (const TYPEMAP& obj) { return obj; }

    static void dispose (pTHX_ const TYPE& var, SV* arg) {
        IType::destroy(var, arg);
    }

    static void destroy (pTHX_ const TYPE& var, SV* arg) {
        if (!std::is_same<TYPEMAP, TYPE>::value) return;
        if (!IStorage::auto_disposable) dispose(aTHX_ var, arg);
    }

    template <class TO, class FROM> static inline TO cast (FROM v) { return _cast<TO, FROM>(v, CastType()); }

    static std::string_view package () { typemap::object::_throw_no_package(typeid(TYPE)); return ""; }

    static Stash default_stash () {
        static PERL_THREAD_LOCAL Stash stash = gv_stashpvn(Typemap<TYPE>::package().data(), Typemap<TYPE>::package().length(), GV_ADD);
        return stash;
    }

private:
    template <class TO, class FROM> static inline TO _cast (FROM v, DynamicCast) { return IType::template upgrade<TO>(v); }
    template <class TO, class FROM> static inline TO _cast (FROM v, StaticCast)  { return IType::template cast<TO>(v); }
};

}
