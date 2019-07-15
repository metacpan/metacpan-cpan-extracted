#include <xs.h>
#include <xs/CallbackDispatcher.h>

using namespace xs;

MODULE = XS::Framework                PACKAGE = XS::Framework
PROTOTYPES: DISABLE

BOOT {
    xs::typemap::object::init(aTHX);
}

void __at_perl_destroy () {
    __call_at_perl_destroy();
}

void sv_payload_attach (Scalar sv, SV* payload) {
    sv.payload_detach(Sv::default_marker());
    sv.payload_attach(payload, Sv::default_marker());
}    
    
bool sv_payload_exists (Scalar sv) {
    RETVAL = sv.payload_exists(Sv::default_marker());
}   
    
void sv_payload (Scalar sv) {
    SV* ret = sv.payload(Sv::default_marker()).obj;
    if (!ret) XSRETURN_UNDEF;
    ST(0) = ret;
    XSRETURN(1);
}    

int sv_payload_detach (Scalar sv) {
    RETVAL = sv.payload_detach(Sv::default_marker());
}

void rv_payload_attach (Ref rv, SV* payload) {
    if (!rv) throw "argument is not a reference";
    rv.value().payload_detach(Sv::default_marker());
    rv.value().payload_attach(payload, Sv::default_marker());
}    
    
bool rv_payload_exists (Ref rv) {
    if (!rv) throw "argument is not a reference";
    RETVAL = rv.value().payload_exists(Sv::default_marker());
}   
    
void rv_payload (Ref rv) {
    if (!rv) throw "argument is not a reference";
    SV* ret = rv.value().payload(Sv::default_marker()).obj;
    if (!ret) XSRETURN_UNDEF;
    ST(0) = ret;
    XSRETURN(1);
}    

int rv_payload_detach (Ref rv) {
    if (!rv) throw "argument is not a reference";
    RETVAL = rv.value().payload_detach(Sv::default_marker());
}

void any_payload_attach (Sv sv, SV* payload) {
    if (sv.is_ref()) sv = Ref(sv).value();
    sv.payload_detach(Sv::default_marker());
    sv.payload_attach(payload, Sv::default_marker());
}
    
bool any_payload_exists (Sv sv) {
    if (sv.is_ref()) sv = Ref(sv).value();
    RETVAL = sv.payload_exists(Sv::default_marker());
}   
    
SV* any_payload (Sv sv) {
    if (sv.is_ref()) sv = Ref(sv).value();
    SV* ret = sv.payload(Sv::default_marker()).obj;
    if (!ret) XSRETURN_UNDEF;
    ST(0) = ret;
    XSRETURN(1);
}

int any_payload_detach (Sv sv) {
    if (sv.is_ref()) sv = Ref(sv).value();
    RETVAL = sv.payload_detach(Sv::default_marker());
}

void obj2hv (Ref rv) {
    if (!rv) throw "argument is not a reference";
    auto sv = rv.value();
    if (SvOK(sv)) throw "only references to undefs can be upgraded";
    sv.upgrade(SVt_PVHV);
}

void obj2av (Ref rv) {
    if (!rv) throw "argument is not a reference";
    auto sv = rv.value();
    if (SvOK(sv)) throw "only references to undefs can be upgraded";
    sv.upgrade(SVt_PVAV);
}

INCLUDE: CallbackDispatcher.xsi
