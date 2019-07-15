#include <xs/Array.h>

namespace xs {

Array Array::create (size_t size, SV** content, create_type_t type) {
    Array ret = create();
    ret.resize(size);
    SV** dst = ret._svlist();

    if (type == COPY) {
        for (size_t i = 0; i < size; ++i) {
            if (*content) {
                SV* val = *dst++ = newSV(0);
                sv_setsv_flags(val, *content++, SV_DO_COW_SVSETSV|SV_NOSTEAL);
            } else {
                ++content;
                ++dst;
            }
        }
    } else {
        for (size_t i = 0; i < size; ++i) *dst++ = SvREFCNT_inc(*content++);
    }
    return ret;
}

Array::Array (std::initializer_list<Scalar> l, create_type_t type) {
    SV* svs[l.size()];
    const Scalar* from = l.begin();
    for (size_t i = 0; i < l.size(); ++i) svs[i] = (*from++).get();
    auto tmp = create(l.size(), svs, type);
    *this = std::move(tmp);
}

void Array::store (size_t key, const Scalar& val) {
    if (!sv) throw std::logic_error("store: empty object");
    SvREFCNT_inc_simple_void(val.get());

    if (key >= _cap()) av_extend((AV*)sv, key);

    auto ptr = _svlist() + key;
    auto old = *ptr;
    *ptr = val.get();

    if (_size() <= key) _size(key+1);
    else SvREFCNT_dec(old);
}

void Array::push (const std::initializer_list<Scalar>& l) {
    auto oldsize = size();
    auto addsize = l.size();
    resize(oldsize + addsize);
    const Scalar* from = l.begin();
    SV** dst = _svlist() + oldsize;
    for (size_t i = 0; i < addsize; ++i) *dst++ = SvREFCNT_inc((from++)->get());
}

void Array::push (const List& l) {
    auto oldsize = size();
    auto addsize = l.size();
    resize(oldsize + addsize);
    SV** from = l._svlist();
    SV** dst = _svlist() + oldsize;
    for (size_t i = 0; i < addsize; ++i) *dst++ = SvREFCNT_inc(*from++);
}

void Array::push (const Scalar& v) {
    auto oldsize = size();
    resize(oldsize + 1);
    _svlist()[oldsize] = SvREFCNT_inc(v.get());
}

void Array::unshift (const std::initializer_list<Scalar>& l) {
    auto addsize = l.size();
    av_unshift((AV*)sv, addsize);
    const Scalar* from = l.begin();
    SV** dst = _svlist();
    for (size_t i = 0; i < addsize; ++i) *dst++ = SvREFCNT_inc((from++)->get());
}

void Array::unshift (const List& l) {
    auto addsize = l.size();
    av_unshift((AV*)sv, addsize);
    SV** from = l._svlist();
    SV** dst = _svlist();
    for (size_t i = 0; i < addsize; ++i) *dst++ = SvREFCNT_inc(*from++);
}

void Array::unshift (const Scalar& v) {
    av_unshift((AV*)sv, 1);
    *(_svlist()) = SvREFCNT_inc(v.get());
}

U32 Array::push_on_stack (SV** sp, U32 max) const {
    auto sz = size();
    if (max && sz > max) sz = max;
    EXTEND(sp, (I32)sz);
    SV** list = _svlist();
    for (decltype(sz) i = 0; i < sz; ++i) *++sp = sv_2mortal(SvREFCNT_inc(list[i]));
    return sz;
}

}
