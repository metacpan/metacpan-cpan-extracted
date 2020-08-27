#include <xs.h>
#include <stdlib.h>

using namespace xs;

static peep_t prev_rpeepp;

static int post = 0;

OP* intercepted_entersub(pTHX) {
    auto ret = PL_ppaddr[OP_ENTERSUB](aTHX);
    ++post;
    return ret;
}

static void my_rpeep(pTHX_ OP *first)
{
    auto mark = [] (OP* it) {
        if (it->op_type == OP_ENTERSUB) {
            it->op_ppaddr = &intercepted_entersub;
        }
    };
    OP *o, *t;
    for(t = o = first; o; o = o->op_next, t = t->op_next) {
        mark(o);
        o = o->op_next;
        if(!o || o == t) break;
        mark(o);
    }
    prev_rpeepp(aTHX_ first);
}

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE


BOOT {
    prev_rpeepp = PL_rpeepp;
    PL_rpeepp = my_rpeep;
}

int marker() {
    RETVAL = post;
}

void test() {
    // no-op
}
