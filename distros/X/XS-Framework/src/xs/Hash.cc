#include <xs/Hash.h>

namespace xs {

Hash::Hash (const std::initializer_list<std::tuple<panda::string_view, Scalar>>& l) {
    sv = (SV*)newHV();
    reserve(l.size());
    auto end = l.end();
    for (auto ptr = l.begin(); ptr != end; ++ptr) store(std::get<0>(*ptr), std::get<1>(*ptr));
}

void Hash::store (const panda::string_view& key, const Scalar& v, U32 hash) {
    if (!sv) throw std::logic_error("store: empty object");
    SV* val = v;
    if (val) SvREFCNT_inc_simple_void_NN(val);
    else val = newSV(0);
    SV** ret = hv_store((HV*)sv, key.data(), key.length(), val, hash);
    if (!ret) SvREFCNT_dec_NN(val);
}

U32 Hash::push_on_stack (SV** sp) const {
    HV* hv = (HV*)sv;
    auto sz = HvUSEDKEYS(hv) * 2;
    if (!sz) return 0;
    EXTEND(sp, (I32)sz);
    STRLEN hvmax = HvMAX(hv);
    HE** hvarr = HvARRAY(hv);
    for (STRLEN bucket_num = 0; bucket_num <= hvmax; ++bucket_num)
        for (const HE* he = hvarr[bucket_num]; he; he = HeNEXT(he)) {
            *++sp = sv_2mortal(newSVpvn(HeKEY(he), HeKLEN(he)));
            *++sp = sv_2mortal(SvREFCNT_inc_NN(HeVAL(he)));
        }
    return sz;
}

}
