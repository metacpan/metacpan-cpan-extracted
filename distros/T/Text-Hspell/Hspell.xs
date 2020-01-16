#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <hspell.h>

typedef struct
{
    struct dict_radix *dict;
} PqInC;

SV* texthspell_proto_new() {
        PqInC * s;
        SV*      obj_ref = newSViv(0);
        SV*      obj = newSVrv(obj_ref, "Text::Hspell");
        New(42, s, 1, PqInC);

        if (hspell_init(&(s->dict), 0)) {
            fprintf(stderr, "hspell_init() failed.\n");
            exit(-1);
        }
        sv_setiv(obj, (IV)s);
        SvREADONLY_on(obj);
        return obj_ref;
}

static inline PqInC * deref(SV * const obj) {
    return (PqInC*)SvIV(SvRV(obj));
}

static inline struct dict_radix * q(SV * const obj) {
    return (deref(obj)->dict);
}

int texthspell_check_word_internal(SV * obj, char * word) {
    int no_use;
    int ret = hspell_check_word(q(obj), word, &no_use);
    return ret;
}

MODULE = Text::Hspell  PACKAGE = Text::Hspell PREFIX = texthspell_

PROTOTYPES: DISABLE


SV *
texthspell_proto_new ()

int
texthspell_check_word_internal (obj, s)
	SV *	obj
    char *  s

void
texthspell_DESTROY(obj)
    SV * obj
    CODE:
        hspell_uninit(q(obj));
