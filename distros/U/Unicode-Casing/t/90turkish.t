# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Unicode-Casing.t'

use Test::More;

use if $^V ge v5.15.8, 'feature', 'fc';

plan skip_all => 'Needs 5.12 for various Unicode things' if $] < 5.012;
plan tests => 49;

# Verifies that can implement Turkish casing as defined by Unicode 5.2.

sub turkish_uc($) {
    my $string = shift;
    $string =~ s/i/\x{130}/g;
    return uc($string);
}

sub turkish_ucfirst($) {
    my $string = shift;
    $string =~ s/^i/\x{130}/;
    return ucfirst($string);
}

sub turkish_lc($) {
    my $string = shift;

    # Unless an I is before a dot_above, it turns into a dotless i (the dot
    # above being attached to the I, without an intervening other Above mark;
    # an intervening non-mark (ccc=0) would mean that the dot above would be
    # attached to that character and not the I)
    $string =~ s/I (?! [^\p{ccc=0}\p{ccc=Above}]* \x{0307} )/\x{131}/gx;

    # But when the I is followed by a dot_above, remove the dot_above so
    # the end result will be i.
    $string =~ s/I ([^\p{ccc=0}\p{ccc=Above}]* ) \x{0307}/i$1/gx;

    $string =~ s/\x{130}/i/g;

    return lc($string);
}

sub turkish_lcfirst($) {
    my $string = shift;

    # Unless an I is before a dot_above, it turns into a dotless i.
    $string =~ s/^I (?! [^\p{ccc=0}\p{ccc=Above}]* \x{0307} )/\x{131}/x;

    # But when the I is followed by a dot_above, remove the dot_above so
    # the end result will be i.
    $string =~ s/^I ([^\p{ccc=0}\p{ccc=Above}]* ) \x{0307}/i$1/x;

    $string =~ s/^\x{130}/i/;

    return lcfirst($string);
}

sub turkish_fc($) {
    # I (khw) believe this is correct, but am not sure.  It works just like
    # turkish_lc() does for the Turkic-specific changes.

    my $string = shift;

    $string =~ s/I (?! [^\p{ccc=0}\p{ccc=Above}]* \x{0307} )/\x{131}/gx;

    $string =~ s/I ([^\p{ccc=0}\p{ccc=Above}]* ) \x{0307}/i$1/gx;

    $string =~ s/\x{130}/i/g;

    return fc($string);
}

use if $^V lt v5.15.8, Unicode::Casing,
                lc => \&turkish_lc, lcfirst => \&turkish_lcfirst,
                uc => \&turkish_uc, ucfirst => \&turkish_ucfirst;
use if $^V ge v5.15.8, Unicode::Casing,
                lc => \&turkish_lc, lcfirst => \&turkish_lcfirst,
                uc => \&turkish_uc, ucfirst => \&turkish_ucfirst,
                fc => \&turkish_fc;

is(uc("aa"), "AA", 'Verify that uc of non-overridden ASCII works');
is("\Uaa", "AA", 'Verify that \U of non-overridden ASCII works');
is(uc("\x{101}\x{101}"), "\x{100}\x{100}", 'Verify that uc of non-overridden utf8 works');
is("\U\x{101}\x{101}", "\x{100}\x{100}", 'Verify that \U of non-overridden utf8 works');
is("\u\x{101}\x{101}", "\x{100}\x{101}", 'Verify that \u of non-overridden utf8 works');
is(uc("ii"), "\x{130}\x{130}", 'Verify uc("ii") eq "\x{130}\x{130}"');
is("\Uii", "\x{130}\x{130}", 'Verify "\Uii" eq "\x{130}\x{130}"');

is(ucfirst("\x{101}\x{101}"), "\x{100}\x{101}", 'Verify that ucfirst of non-overridden utf8 works');
is("\u\x{101}\x{101}", "\x{100}\x{101}", 'Verify that \u of non-overridden utf8 works');
is(ucfirst("aa"), "Aa", 'Verify that ucfirst of non-overridden ASCII works');
is("\uaa", "Aa", 'Verify that \u of non-overridden ASCII works');
is(ucfirst("ii"), "\x{130}i", 'Verify ucfirst("ii") eq "\x{130}i"');
is("\uii", "\x{130}i", 'Verify "\uii") eq "\x{130}i"');


is(lc("AA"), "aa", 'Verify that lc of non-overridden ASCII works');
is("\LAA", "aa", 'Verify that lc of non-overridden ASCII works');
is(lc("\x{0178}\x{0178}"), "\x{FF}\x{FF}", 'Verify that lc of non-overridden utf8 works');
is("\L\x{0178}\x{0178}", "\x{FF}\x{FF}", 'Verify that lc of non-overridden utf8 works');
is(lc("II"), "\x{131}\x{131}", 'Verify that lc("I") eq \x{131}');
is("\LII", "\x{131}\x{131}", 'Verify that "\LI" eq \x{131}');
is(lc("IG\x{0307}IG\x{0307}"), "\x{131}g\x{0307}\x{131}g\x{0307}", 'Verify that lc("I...\x{0307}") eq "\x{131}...\x{0307}"');
is("\LIG\x{0307}IG\x{0307}", "\x{131}g\x{0307}\x{131}g\x{0307}", 'Verify that "\LI...\x{0307}" eq "\x{131}...\x{0307}"');
is(lc("I\x{0307}I\x{0307}"), "ii", 'Verify that lc("I\x{0307}") removes the \x{0307}, leaving "i"');
is("\LI\x{0307}I\x{0307}", "ii", 'Verify that "\LI\x{0307}" removes the \x{0307}, leaving "i"');
is(lc("\x{130}\x{130}"), "ii", 'Verify that lc("\x{130}") eq "i"');
is("\L\x{130}\x{130}", "ii", 'Verify that "\L\x{130}" eq "i"');


is(lcfirst("AA"), "aA", 'Verify that lcfirst of non-overridden ASCII works');
is("\lAA", "aA", 'Verify that \l of non-overridden ASCII works');
is(lcfirst("\x{0178}\x{0178}"), "\x{FF}\x{0178}", 'Verify that lcfirst of non-overridden utf8 works');
is("\l\x{0178}\x{0178}", "\x{FF}\x{0178}", 'Verify that \l of non-overridden utf8 works');
is(lcfirst("I"), "\x{131}", 'Verify that lcfirst("II") eq "\x{131}I"');
is("\lI", "\x{131}", 'Verify that "\lII" eq \x{131}I"');
is(lcfirst("IG\x{0307}"), "\x{131}G\x{0307}", 'Verify that lcfirst("I...\x{0307}") eq "\x{131}...\x{0307}"');
is("\lIG\x{0307}", "\x{131}G\x{0307}", 'Verify that "\lI...\x{0307}" eq "\x{131}...\x{0307}"');
is(lcfirst("I\x{0307}I\x{0307}"), "iI\x{0307}", 'Verify that lcfirst("I\x{0307}I\x{0307}") removes the first \x{0307}, leaving "iI\x{0307}"');
is("\lI\x{0307}I\x{0307}", "iI\x{0307}", 'Verify that "\lI\x{0307}I\x{0307}" removes the first \x{0307}, leaving "iI\x{0307}"');
is(lcfirst("\x{130}\x{130}"), "i\x{130}", 'Verify that lcfirst("\x{130}\x{130}") eq "i\x{130}"');
is("\l\x{130}\x{130}", "i\x{130}", 'Verify that "\l\x{130}\x{130}" eq "i\x{130}"');

SKIP: { 
    skip "fc not in this version of Perl", 12 if $^V lt v5.15.8;

    is(fc("AA"), "aa", 'Verify that fc of non-overridden ASCII works');
    is("\FAA", "aa", 'Verify that fc of non-overridden ASCII works');
    is(fc("\x{0178}\x{0178}"), "\x{FF}\x{FF}", 'Verify that fc of non-overridden utf8 works');
    is("\F\x{0178}\x{0178}", "\x{FF}\x{FF}", 'Verify that fc of non-overridden utf8 works');
    is(fc("II"), "\x{131}\x{131}", 'Verify that fc("I") eq \x{131}');
    is("\FII", "\x{131}\x{131}", 'Verify that "\FI" eq \x{131}');
    is(fc("IG\x{0307}IG\x{0307}"), "\x{131}g\x{0307}\x{131}g\x{0307}", 'Verify that fc("I...\x{0307}") eq "\x{131}...\x{0307}"');
    is("\FIG\x{0307}IG\x{0307}", "\x{131}g\x{0307}\x{131}g\x{0307}", 'Verify that "\FI...\x{0307}" eq "\x{131}...\x{0307}"');
    is(fc("I\x{0307}I\x{0307}"), "ii", 'Verify that fc("I\x{0307}") removes the \x{0307}, leaving "i"');
    is("\FI\x{0307}I\x{0307}", "ii", 'Verify that "\FI\x{0307}" removes the \x{0307}, leaving "i"');
    is(fc("\x{130}\x{130}"), "ii", 'Verify that fc("\x{130}") eq "i"');
    is("\F\x{130}\x{130}", "ii", 'Verify that "\F\x{130}" eq "i"');
}
