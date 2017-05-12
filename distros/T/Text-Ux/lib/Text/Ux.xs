#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

// Hack to work around "error: declaration of 'Perl___notused' has a different
// language linkage" error on Clang
#ifdef dNOOP
# undef dNOOP
# define dNOOP
#endif

#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif

#define NEED_sv_2pvbyte
#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#define NEED_newSVpvn_flags
#define NEED_sv_2pv_flags
#include "ppport.h"

#include <sstream>
#include "ux.hpp"

#define CHECK_RESULT(ret) STMT_START { \
    int rc = ret; \
    if (rc != 0) { \
        std::string what = THIS->what(rc); \
        if (what.empty()) { \
            what = "An error occured"; \
        } \
        croak("%s", what.c_str()); \
    } \
} STMT_END

static SV *
do_callback(pTHX_ SV *callback, SV *str) {
    dSP;
    int count;
    SV *retval;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(str));
    PUTBACK;
    count = call_sv(callback, G_SCALAR);
    SPAGAIN;
    if (count != 1) {
        croak("callback sub must return scalar!");
    }
    retval = newSVsv(POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

MODULE = Text::Ux PACKAGE = Text::Ux

PROTOTYPES: DISABLE

BOOT:
    {
        HV* ux = gv_stashpv("Text::Ux", 1);
        newCONSTSUB(ux, "LIMIT_DEFAULT", newSViv(ux::LIMIT_DEFAULT));
    }

ux::Trie*
ux::Trie::new()
CODE:
    RETVAL = new ux::Trie();
OUTPUT:
    RETVAL

void
ux::Trie::build(AV* key_list, bool is_tail_ux = true)
CODE:
    std::vector<std::string> keys;
    I32 keys_len = av_len(key_list);
    for (I32 i = 0; i <= keys_len; i++) {
        STRLEN len;
        char* key = SvPV(*av_fetch(key_list, i, 0), len);
        keys.push_back(std::string(key, len));
    }
    THIS->build(keys, is_tail_ux);

void
ux::Trie::save(SV* stuff)
CODE:
    if (SvROK(stuff) && strcmp(sv_reftype(SvRV(stuff), TRUE), "SCALAR") == 0) {
        std::ostringstream os;
        CHECK_RESULT(THIS->save(os));
        std::string str = os.str();
        sv_setpvn(SvRV(stuff), str.c_str(), str.length());
    } else {
        CHECK_RESULT(THIS->save(SvPV_nolen(stuff)));
    }

void
ux::Trie::load(SV* stuff)
CODE:
    if (SvROK(stuff) && strcmp(sv_reftype(SvRV(stuff), TRUE), "SCALAR") == 0) {
        STRLEN len;
        char* str = SvPVbyte(SvRV(stuff), len);
        std::istringstream is(std::string(str, len));
        CHECK_RESULT(THIS->load(is));
    } else {
        CHECK_RESULT(THIS->load(SvPV_nolen(stuff)));
    }

SV*
ux::Trie::prefix_search(SV* query)
CODE:
    if (!SvOK(query)) {
        XSRETURN_UNDEF;
    }
    STRLEN len;
    char* str = SvPV(query, len);
    size_t ret_len;
    ux::id_t id = THIS->prefixSearch(str, len, ret_len);
    if (id == ux::NOTFOUND) {
        XSRETURN_UNDEF;
    }
    std::string key = THIS->decodeKey(id);
    RETVAL = newSVpvn_utf8(key.c_str(), key.length(), SvUTF8(query));
OUTPUT:
    RETVAL

void
ux::Trie::common_prefix_search(SV* query, size_t limit = ux::LIMIT_DEFAULT)
PPCODE:
    if (!SvOK(query)) {
        XSRETURN_EMPTY;
    }
    STRLEN len;
    char* str = SvPV(query, len);
    std::vector<ux::id_t> ret_ids;
    size_t num_keys = THIS->commonPrefixSearch(str, len, ret_ids, limit);
    if (num_keys == 0) {
        XSRETURN_EMPTY;
    }
    EXTEND(SP, num_keys);
    bool is_utf8 = SvUTF8(query);
    for (size_t i = 0; i < num_keys; i++) {
        std::string key = THIS->decodeKey(ret_ids[i]);
        PUSHs(sv_2mortal(newSVpvn_utf8(key.c_str(), key.length(), is_utf8)));
    }
    XSRETURN(num_keys);

void
ux::Trie::predictive_search(SV* query, size_t limit = ux::LIMIT_DEFAULT)
PPCODE:
    if (!SvOK(query)) {
        XSRETURN_EMPTY;
    }
    STRLEN len;
    char* str = SvPV(query, len);
    std::vector<ux::id_t> ret_ids;
    size_t num_keys = THIS->predictiveSearch(str, len, ret_ids, limit);
    if (num_keys == 0) {
        XSRETURN_EMPTY;
    }
    EXTEND(SP, num_keys);
    bool is_utf8 = SvUTF8(query);
    for (size_t i = 0; i < num_keys; i++) {
        std::string key = THIS->decodeKey(ret_ids[i]);
        PUSHs(sv_2mortal(newSVpvn_utf8(key.c_str(), key.length(), is_utf8)));
    }
    XSRETURN(num_keys);

size_t
ux::Trie::size()

void
ux::Trie::clear()

size_t
ux::Trie::alloc_size()
CODE:
    RETVAL = THIS->getAllocSize();
OUTPUT:
    RETVAL

std::string
ux::Trie::alloc_stat(size_t alloc_size)
CODE:
    std::ostringstream os;
    THIS->allocStat(alloc_size, os);
    RETVAL = os.str();
OUTPUT:
    RETVAL

std::string
ux::Trie::stat()
CODE:
    std::ostringstream os;
    THIS->stat(os);
    RETVAL = os.str();
OUTPUT:
    RETVAL

SV*
ux::Trie::gsub(SV* query, SV* callback)
CODE:
    if (!SvOK(query)) {
        XSRETURN_UNDEF;
    }
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV) {
        croak("callback must be a CODE reference");
    }
    bool is_utf8 = SvUTF8(query);
    SV* result = newSVpvs("");
    char* head = SvPV_nolen(query);
    char* tail = head + SvCUR(query);
    size_t ret_len;
    while (head < tail) {
        if (THIS->prefixSearch(head, tail - head, ret_len) != ux::NOTFOUND) {
            SV* str = newSVpvn_utf8(head, ret_len, is_utf8);
            SV* ret = do_callback(aTHX_ callback, str);
            if (SvOK(ret)) {
                sv_catsv(result, ret);
            }
            SvREFCNT_dec(ret);
            head += ret_len;
        } else {
            I32 len = is_utf8 ? UTF8SKIP(head) : 1;
            sv_catpvn(result, head, len);
            head += len;
        }
    }
    RETVAL = result;
OUTPUT:
    RETVAL

SV*
ux::Trie::decode_key(ux::id_t id)
CODE:
    if (id >= THIS->size()) {
        XSRETURN_UNDEF;
    }
    std::string key = THIS->decodeKey(id);
    if (key.empty()) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpvn(key.c_str(), key.length());
OUTPUT:
    RETVAL

SV*
ux::Trie::decode_key_utf8(ux::id_t id)
CODE:
    if (id >= THIS->size()) {
        XSRETURN_UNDEF;
    }
    std::string key = THIS->decodeKey(id);
    if (key.empty()) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpvn_utf8(key.c_str(), key.length(), 1);
OUTPUT:
    RETVAL

void
ux::Trie::DESTROY()
