#!/usr/bin/env perl
no circular::require -hide => [
    qw(base Foo Bar main circular::require),
    (grep { /\.pm$/ }
          map { my $m = $_; $m =~ s+/+::+g; $m =~ s/\.pm$//; $m }
              keys %INC),
];

use strict;
use warnings;
use lib 't/hide_middleman';
use Test::More;

my @warnings;

{
    $SIG{__WARN__} = sub { push @warnings => @_ };

    use_ok( 'Foo' );
}

is_deeply(
    \@warnings,
    ["Circular require detected in Foo.pm (from unknown file)\n"],
    "don't loop infinitely if all packages are hidden"
);

done_testing;
