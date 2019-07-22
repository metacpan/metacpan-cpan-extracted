#pragma once
#include <string>
#include <xs/Scalar.h>
#include <xs/HashEntry.h>
#include <panda/string.h>
#include <panda/string_view.h>

namespace xs {

using xs::my_perl;

namespace detail {
    template <typename T> inline SV* _newnum (T val, panda::enable_if_signed_integral_t<T>*   = nullptr) { return newSViv(val); }
    template <typename T> inline SV* _newnum (T val, panda::enable_if_unsigned_integral_t<T>* = nullptr) { return newSVuv(val); }
    template <typename T> inline SV* _newnum (T val, panda::enable_if_floatp_t<T>*            = nullptr) { return newSVnv(val); }

    template <typename T> inline panda::enable_if_signed_integral_t<T>   _getrawnum (const SV* sv) { return SvIVX(sv); }
    template <typename T> inline panda::enable_if_unsigned_integral_t<T> _getrawnum (const SV* sv) { return SvUVX(sv); }
    template <typename T> inline panda::enable_if_floatp_t<T>            _getrawnum (const SV* sv) { return SvNVX(sv); }

    template <typename T> inline panda::enable_if_signed_integral_t<T>   _getnum (SV* sv) { return SvIV_nomg(sv); }
    template <typename T> inline panda::enable_if_unsigned_integral_t<T> _getnum (SV* sv) { return SvUV_nomg(sv); }
    template <typename T> inline panda::enable_if_floatp_t<T>            _getnum (SV* sv) { return SvNV_nomg(sv); }

    template <typename T> inline void _setrawnum (SV* sv, T val, panda::enable_if_signed_integral_t<T>*   = nullptr) { SvIV_set(sv, val); }
    template <typename T> inline void _setrawnum (SV* sv, T val, panda::enable_if_unsigned_integral_t<T>* = nullptr) { SvUV_set(sv, val); }
    template <typename T> inline void _setrawnum (SV* sv, T val, panda::enable_if_floatp_t<T>*            = nullptr) { SvNV_set(sv, val); }

    template <typename T> inline void _setnum (SV* sv, T val, panda::enable_if_signed_integral_t<T>*   = nullptr) { sv_setiv(sv, val); }
    template <typename T> inline void _setnum (SV* sv, T val, panda::enable_if_unsigned_integral_t<T>* = nullptr) { sv_setuv(sv, val); }
    template <typename T> inline void _setnum (SV* sv, T val, panda::enable_if_floatp_t<T>*            = nullptr) { sv_setnv(sv, val); }

    #if IVSIZE < 8 // use NV(double) as storage for 64bit integer on 32-bit perls (much more range available)
        template <> inline SV* _newnum<int64_t>  (int64_t  val) { return newSVnv(val); }
        template <> inline SV* _newnum<uint64_t> (uint64_t val) { return newSVnv(val); }

        template <> inline int64_t  _getrawnum<int64_t>  (const SV* sv) { return SvNVX(sv); }
        template <> inline uint64_t _getrawnum<uint64_t> (const SV* sv) { return SvNVX(sv); }

        template <> inline int64_t  _getnum<int64_t>  (SV* sv) { return SvNV_nomg(sv); }
        template <> inline uint64_t _getnum<uint64_t> (SV* sv) { return SvNV_nomg(sv); }

        template <> inline void _setrawnum<int64_t>  (SV* sv, int64_t  val) { SvNV_set(sv, val); }
        template <> inline void _setrawnum<uint64_t> (SV* sv, uint64_t val) { SvNV_set(sv, val); }

        template <> inline void _setnum<int64_t>  (SV* sv, int64_t  val) { sv_setnv(sv, val); }
        template <> inline void _setnum<uint64_t> (SV* sv, uint64_t val) { sv_setnv(sv, val); }
    #endif
}

struct Simple : Scalar {
    static const Simple undef;
    static const Simple yes;
    static const Simple no;

    static Simple create (size_t capacity) {
        SV* sv = newSV(capacity+1);
        SvPOK_on(sv);
        SvCUR_set(sv, 0);
        return Simple(sv, NONE);
    }

    static Simple shared (HEK* k)                                    { return newSVhek(k); }
    static Simple shared (const panda::string_view& s, U32 hash = 0) { return newSVpvn_share(s.data(), s.length(), hash); }

    static Simple format (const char*const pat, ...);

    Simple (std::nullptr_t = nullptr) {}

    Simple (SV* sv, bool policy = INCREMENT) : Scalar(sv, policy) { _validate(); }

    Simple (const Simple& oth) : Scalar(oth)            {}
    Simple (Simple&&      oth) : Scalar(std::move(oth)) {}
    Simple (const Scalar& oth) : Scalar(oth)            { _validate(); }
    Simple (Scalar&&      oth) : Scalar(std::move(oth)) { _validate(); }
    Simple (const Sv&     oth) : Simple(oth.get())      {}
    Simple (Sv&&          oth) : Scalar(std::move(oth)) { _validate(); }

    Simple (const Ref&)   = delete;
    Simple (const Glob&)  = delete;
    Simple (const Array&) = delete;
    Simple (const Hash&)  = delete;
    Simple (const Sub&)   = delete;

    template <class T, typename = panda::enable_if_arithmetic_t<T>>
    explicit
    Simple (T val) { sv = detail::_newnum<T>(val); }

    explicit
    Simple (const panda::string_view& s) { sv = newSVpvn(s.data(), s.length()); }

    static Simple noinc (SV* val) { return Simple(val, NONE); }

    Simple& operator= (SV* val) {
        Scalar::operator=(val);
        _validate();
        return *this;
    }

    Simple& operator= (const Simple& oth) {
        Scalar::operator=(oth);
        return *this;
    }

    Simple& operator= (Simple&& oth) {
        Scalar::operator=(std::move(oth));
        return *this;
    }

    Simple& operator= (const Scalar& oth) {
        Scalar::operator=(oth);
        _validate();
        return *this;
    }

    Simple& operator= (Scalar&& oth) {
        Scalar::operator=(std::move(oth));
        _validate();
        return *this;
    }

    Simple& operator= (const Sv& oth) { return operator=(oth.get()); }

    Simple& operator= (Sv&& oth) {
        Scalar::operator=(std::move(oth));
        _validate();
        return *this;
    }

    Simple& operator= (const Ref&)   = delete;
    Simple& operator= (const Glob&)  = delete;
    Simple& operator= (const Array&) = delete;
    Simple& operator= (const Hash&)  = delete;
    Simple& operator= (const Sub&)   = delete;

    // safe setters (slower)
    template <typename T, typename = panda::enable_if_arithmetic_t<T>>
    Simple& operator= (T val) {
        if (sv) detail::_setnum(sv, val);
        else sv = detail::_newnum(val);
        return *this;
    }

    Simple& operator= (const panda::string_view& s) {
        if (sv) sv_setpvn(sv, s.data(), s.length());
        else sv = newSVpvn(s.data(), s.length());
        return *this;
    }

    template <typename T, typename = panda::enable_if_arithmetic_t<T>>
    void set (T val)                { detail::_setrawnum<T>(sv, val); }
    void set (panda::string_view s) { sv_setpvn(sv, s.data(), s.length()); }
    void set (SV* val)              { Scalar::set(val); }

    using Sv::operator bool; // otherwise, operator arithmetic_t<T> will be in priority

    template <class T, typename = panda::enable_if_arithmetic_t<T>>
    operator T () const { return sv ? detail::_getnum<T>(sv) : T(); }

    const char* c_str () const { return sv ? SvPV_nomg_const_nolen(sv) : NULL; }

    operator panda::string_view () const { return as_string<panda::string_view>(); }

    // unsafe getters (faster)
    template <typename T>      panda::enable_if_arithmetic_t<T>                 get () const { return detail::_getrawnum<T>(sv); }
    template <typename T>      panda::enable_if_one_of_t<T,char*,const char*>   get () const { return SvPVX(sv); }
    template <typename T>      panda::enable_if_one_of_t<T, panda::string_view> get () const { return panda::string_view(SvPVX(sv), SvCUR(sv)); }
    template <typename T = SV> panda::enable_if_one_of_t<T,SV>*                 get () const { return sv; }

    template <class T = panda::string>
    T as_string () const {
        if (!sv) return T();
        STRLEN len;
        const char* buf = SvPV_nomg(sv, len);
        return T(buf, len);
    }

    char  operator[] (size_t i) const { return SvPVX_const(sv)[i]; }
    char& operator[] (size_t i)       { return SvPVX(sv)[i]; }

    char at (size_t i) {
        if (!sv) throw std::out_of_range("at: no sv");
        STRLEN len;
        auto buf = SvPV_const(sv, len);
        if (i >= len) throw std::out_of_range("at: index out of bounds");
        return buf[i];
    }

    bool   is_string () const        { return sv && SvPOK(sv); }
    bool   is_shared () const        { return sv && SvIsCOW_shared_hash(sv); }
    STRLEN length    () const        { return SvCUR(sv); }
    void   length    (STRLEN newlen) { SvCUR_set(sv, newlen); }
    STRLEN capacity  () const        { return SvLEN(sv); }
    bool   utf8      () const        { return SvUTF8(sv); }
    void   utf8      (bool val)      { if (val) SvUTF8_on(sv); else SvUTF8_off(sv); }

    U32 hash () const;

    HEK* hek () const { return SvSHARED_HEK_FROM_PV(SvPVX_const(sv)); }

    static void __at_perl_destroy ();

private:
    void _validate () {
        if (!sv) return;
        if (SvTYPE(sv) > SVt_PVMG || SvROK(sv)) {
            reset();
            throw std::invalid_argument("wrong SV* type for Simple");
        }
    }
};

template <class T> T Scalar::as_string () const { return Simple(sv).as_string<T>(); }
template <class T> T Scalar::as_number () const { return Simple(sv); }

template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator== (const Simple& lhs, T rhs) { return (T)lhs == rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator== (T lhs, const Simple& rhs) { return lhs == (T)rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator!= (const Simple& lhs, T rhs) { return (T)lhs != rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator!= (T lhs, const Simple& rhs) { return lhs != (T)rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator>  (const Simple& lhs, T rhs) { return (T)lhs > rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator>  (T lhs, const Simple& rhs) { return lhs > (T)rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator>= (const Simple& lhs, T rhs) { return (T)lhs >= rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator>= (T lhs, const Simple& rhs) { return lhs >= (T)rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator<  (const Simple& lhs, T rhs) { return (T)lhs < rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator<  (T lhs, const Simple& rhs) { return lhs < (T)rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator<= (const Simple& lhs, T rhs) { return (T)lhs <= rhs; }
template <typename T, typename = panda::enable_if_arithmetic_t<T>> inline bool operator<= (T lhs, const Simple& rhs) { return lhs <= (T)rhs; }

inline bool operator== (const Simple& lhs, const panda::string_view& rhs) { return (panda::string_view)lhs == rhs; }
inline bool operator== (const panda::string_view& lhs, const Simple& rhs) { return lhs == (panda::string_view)rhs; }
inline bool operator!= (const Simple& lhs, const panda::string_view& rhs) { return (panda::string_view)lhs != rhs; }
inline bool operator!= (const panda::string_view& lhs, const Simple& rhs) { return lhs != (panda::string_view)rhs; }
inline bool operator>  (const Simple& lhs, const panda::string_view& rhs) { return (panda::string_view)lhs > rhs; }
inline bool operator>  (const panda::string_view& lhs, const Simple& rhs) { return lhs > (panda::string_view)rhs; }
inline bool operator>= (const Simple& lhs, const panda::string_view& rhs) { return (panda::string_view)lhs >= rhs; }
inline bool operator>= (const panda::string_view& lhs, const Simple& rhs) { return lhs >= (panda::string_view)rhs; }
inline bool operator<  (const Simple& lhs, const panda::string_view& rhs) { return (panda::string_view)lhs < rhs; }
inline bool operator<  (const panda::string_view& lhs, const Simple& rhs) { return lhs < (panda::string_view)rhs; }
inline bool operator<= (const Simple& lhs, const panda::string_view& rhs) { return (panda::string_view)lhs <= rhs; }
inline bool operator<= (const panda::string_view& lhs, const Simple& rhs) { return lhs <= (panda::string_view)rhs; }

inline bool operator== (const Simple& lhs, const char* rhs) { return (panda::string_view)lhs == panda::string_view(rhs); }
inline bool operator== (const char* lhs, const Simple& rhs) { return panda::string_view(lhs) == (panda::string_view)rhs; }
inline bool operator!= (const Simple& lhs, const char* rhs) { return (panda::string_view)lhs != panda::string_view(rhs); }
inline bool operator!= (const char* lhs, const Simple& rhs) { return panda::string_view(lhs) != (panda::string_view)rhs; }
inline bool operator>  (const Simple& lhs, const char* rhs) { return (panda::string_view)lhs > panda::string_view(rhs); }
inline bool operator>  (const char* lhs, const Simple& rhs) { return panda::string_view(lhs) > (panda::string_view)rhs; }
inline bool operator>= (const Simple& lhs, const char* rhs) { return (panda::string_view)lhs >= panda::string_view(rhs); }
inline bool operator>= (const char* lhs, const Simple& rhs) { return panda::string_view(lhs) >= (panda::string_view)rhs; }
inline bool operator<  (const Simple& lhs, const char* rhs) { return (panda::string_view)lhs < panda::string_view(rhs); }
inline bool operator<  (const char* lhs, const Simple& rhs) { return panda::string_view(lhs) < (panda::string_view)rhs; }
inline bool operator<= (const Simple& lhs, const char* rhs) { return (panda::string_view)lhs <= panda::string_view(rhs); }
inline bool operator<= (const char* lhs, const Simple& rhs) { return panda::string_view(lhs) <= (panda::string_view)rhs; }

inline bool operator== (const Simple& lhs, char* rhs) { return (panda::string_view)lhs == panda::string_view(rhs); }
inline bool operator== (char* lhs, const Simple& rhs) { return panda::string_view(lhs) == (panda::string_view)rhs; }
inline bool operator!= (const Simple& lhs, char* rhs) { return (panda::string_view)lhs != panda::string_view(rhs); }
inline bool operator!= (char* lhs, const Simple& rhs) { return panda::string_view(lhs) != (panda::string_view)rhs; }
inline bool operator>  (const Simple& lhs, char* rhs) { return (panda::string_view)lhs > panda::string_view(rhs); }
inline bool operator>  (char* lhs, const Simple& rhs) { return panda::string_view(lhs) > (panda::string_view)rhs; }
inline bool operator>= (const Simple& lhs, char* rhs) { return (panda::string_view)lhs >= panda::string_view(rhs); }
inline bool operator>= (char* lhs, const Simple& rhs) { return panda::string_view(lhs) >= (panda::string_view)rhs; }
inline bool operator<  (const Simple& lhs, char* rhs) { return (panda::string_view)lhs < panda::string_view(rhs); }
inline bool operator<  (char* lhs, const Simple& rhs) { return panda::string_view(lhs) < (panda::string_view)rhs; }
inline bool operator<= (const Simple& lhs, char* rhs) { return (panda::string_view)lhs <= panda::string_view(rhs); }
inline bool operator<= (char* lhs, const Simple& rhs) { return panda::string_view(lhs) <= (panda::string_view)rhs; }
}
