#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use Locale::gettext_pp;

BEGIN {
	plan tests => 2006;
}

sub russian_plural {
    my $n = shift;

    my ($plural, $nplurals);

    $nplurals = 3;
    $plural = ($n % 10 == 1 && $n % 100 != 11 ? 0 : $n % 10 >= 2 && $n % 10 <= 4 && $n % 10 <= 4 && ($n % 100 < 10 || $n % 100 >= 20) ? 1 : 2);

    return ($nplurals, $plural ? $plural : 0);
}

# This test uses private functions of Locale::gettext_pp.  Do NOT use this as
# an example for your own code.

my $code = 'nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2';

my $untainted = Locale::gettext_pp::__untaint_plural_header $code;

ok length $untainted;

my $plural_function = Locale::gettext_pp::__compile_plural_function $code;

ok $plural_function;
ok ref $plural_function;
ok 'CODE' eq ref $plural_function;

foreach my $n (0 .. 1000) {
    my ($got_nplurals, $got_plural) = $plural_function->($n);
    my ($wanted_nplurals, $wanted_plural) = russian_plural $n;

    ok $got_nplurals, $wanted_nplurals,
       "wanted $wanted_nplurals, got $got_nplurals nplurals for n = $n";
    ok $got_plural, $wanted_plural,
       "wanted plural form #$wanted_nplurals, got #$got_nplurals for n = $n";


    print "$n:$got_plural:$wanted_plural\n";
}

