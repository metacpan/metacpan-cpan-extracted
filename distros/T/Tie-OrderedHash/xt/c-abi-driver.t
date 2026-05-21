#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Exercises the public C ABI declared in include/tie_orderedhash.h
# from a third-party C harness, simulating what File::Raw::JSON's
# frj.c will do post-integration.  Author-only because Inline::C
# isn't in the base test deps.

BEGIN {
    eval { require Inline; require Inline::C; 1 }
        or plan skip_all => "Inline::C not installed (author test)";
    plan tests => 6;
}

use Tie::OrderedHash;
use FindBin qw($Bin);

# Resolve our own arch dir so Inline picks up the built shared
# object's tie_oh_* symbols.  On macOS dynamic_lookup means we don't
# need to link explicitly; Linux callers would link via Depends.
my $blib_arch = "$Bin/../blib/arch";

use Inline C => Config =>
    INC          => "-I$Bin/../include",
    BUILD_NOISY  => 0,
    CLEAN_AFTER_BUILD => 1;

use Inline C => <<'END_C';
#include "tie_orderedhash.h"

/* Build a Tie::OrderedHash, populate it, and read back via the
 * public C ABI.  Returns a list of strings for Perl to inspect. */
void
abi_smoke()
{
    SV *self;
    tie_oh_iter_t it;
    const char *key;
    STRLEN klen;
    SV *val;
    SV *fetched;
    int n;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    self = tie_oh_new(aTHX);

    /* Three pairs in known order. */
    tie_oh_store(aTHX_ self, "z", 1, newSViv(100));
    tie_oh_store(aTHX_ self, "a", 1, newSViv(200));
    tie_oh_store(aTHX_ self, "m", 1, newSViv(300));

    /* Count check. */
    Inline_Stack_Push(sv_2mortal(newSViv((IV)tie_oh_count(aTHX_ self))));

    /* is_instance check. */
    Inline_Stack_Push(sv_2mortal(newSViv(tie_oh_is_instance(aTHX_ self))));

    /* Fetch one value. */
    fetched = tie_oh_fetch(aTHX_ self, "a", 1);
    Inline_Stack_Push(fetched ? fetched : sv_2mortal(newSVpv("MISSING", 7)));

    /* Iterate and emit "key=value;" string. */
    {
        SV *out = newSVpvs("");
        tie_oh_iter_init(aTHX_ self, &it);
        while (tie_oh_iter_next(aTHX_ self, &it, &key, &klen, &val)) {
            sv_catpvf(out, "%.*s=%" IVdf ";", (int)klen, key, SvIV(val));
        }
        Inline_Stack_Push(sv_2mortal(out));
    }

    /* Delete a key, count again. */
    {
        SV *deleted = tie_oh_delete(aTHX_ self, "z", 1);
        Inline_Stack_Push(deleted ? deleted : sv_2mortal(newSVpv("none", 4)));
    }
    Inline_Stack_Push(sv_2mortal(newSViv((IV)tie_oh_count(aTHX_ self))));

    /* Cleanup. */
    SvREFCNT_dec(self);

    Inline_Stack_Done;
}
END_C

my @r = abi_smoke();
is($r[0], 3,                 'count after three stores');
is($r[1], 1,                 'is_instance recognised our object');
is($r[2], 200,               'fetch by key');
is($r[3], 'z=100;a=200;m=300;', 'iterator walks insertion order');
is($r[4], 100,               'delete returns the value');
is($r[5], 2,                 'count after delete');
