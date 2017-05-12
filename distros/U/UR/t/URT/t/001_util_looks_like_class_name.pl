#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use above 'UR';


use_ok("UR::Util");

my @tests = (   [ 'Foo' => 1 ],
                [ 'Foo::Bar' => 1 ],
                [ 'foo' => 1 ],
                [ 'foo::bar' => 1 ],
                [ 'Foo.pm' => '' ],
                [ 'some/path::name' => '' ],
                [ 'An::ugly.pl' => '' ],
                [ '' => '' ],
                [ '::' => '' ],
            );
foreach my $test ( @tests ) {
    my($string, $expected) = @$test;

    my $got = UR::Util::looks_like_class_name($string);
    is($got, $expected, $string);
}
