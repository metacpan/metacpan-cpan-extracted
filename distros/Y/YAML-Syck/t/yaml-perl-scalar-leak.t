#!/usr/bin/perl -w

use strict;
use Test::More;
use YAML::Syck;

# Test that !perl/scalar loads correctly and doesn't leak SVs.
# GH: newRV_inc was used instead of newRV_noinc, leaking the inner SV.

{
    $YAML::Syck::LoadBlessed = 1;

    # Basic perl/scalar round-trip
    my $yaml = "--- !perl/scalar\nhello\n";
    my $result = Load($yaml);
    is(ref($result), 'SCALAR', 'perl/scalar loads as SCALAR ref');
    is($$result, 'hello', 'perl/scalar inner value is correct');

    # Blessed perl/scalar round-trip
    $yaml = "--- !perl/scalar:Foo::Bar\nworld\n";
    $result = Load($yaml);
    is(ref($result), 'Foo::Bar', 'blessed perl/scalar loads with correct class');
    is($$result, 'world', 'blessed perl/scalar inner value is correct');

    # Undef perl/scalar
    $yaml = "--- !perl/scalar\n~\n";
    $result = Load($yaml);
    is(ref($result), 'SCALAR', 'undef perl/scalar loads as SCALAR ref');
    ok(!defined($$result), 'undef perl/scalar inner value is undef');
}

SKIP: {
    skip("Devel::Leak not available or perl too old", 1)
      unless eval { require Devel::Leak; require 5.8.9; 1; };

    require Symbol;
    my $handle = Symbol::gensym();

    $YAML::Syck::LoadBlessed = 1;
    my $yaml = "--- !perl/scalar\nhello\n";

    # Warm up twice (stabilizes SV count per Devel::Leak behavior)
    my $before = Devel::Leak::NoteSV($handle);
    Load($yaml) for 1 .. 100;
    Devel::Leak::NoteSV($handle);

    $before = Devel::Leak::NoteSV($handle);
    Load($yaml) for 1 .. 100;
    my $diff = Devel::Leak::NoteSV($handle) - $before;
    is($diff, 0, "No leaks - perl/scalar Load");
}

done_testing;
