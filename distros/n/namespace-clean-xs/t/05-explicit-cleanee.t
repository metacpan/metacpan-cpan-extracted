#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 2020;

use_ok('CleaneeTarget');

ok  CleaneeTarget->can('IGNORED'),  'symbol in exception list still there';
ok  CleaneeTarget->can('NOTAWAY'),  'symbol after import call still there';
ok !CleaneeTarget->can('AWAY'),     'normal symbol has disappeared';

ok !CleaneeTarget->can('x_foo'),    'explicitely removed disappeared (1/2)';
ok  CleaneeTarget->can('x_bar'),    'not in explicit removal and still there';
ok !CleaneeTarget->can('x_baz'),    'explicitely removed disappeared (2/2)';

ok !CleaneeTarget->can('d_foo'),    'directly removed disappeared (1/2)';
ok  CleaneeTarget->can('d_bar'),    'not in direct removal and still there';
ok !CleaneeTarget->can('d_baz'),    'directly removed disappeared (2/2)';
ok !CleaneeTarget->can('d_const'),  'directly removed const disappeared';

my @values = qw( 23 27 17 XFOO XBAR XBAZ 7 8 9 );
is(CleaneeTarget->summary->[ $_ ], $values[ $_ ], sprintf('testing sub in cleanee (%d/%d)', $_ + 1, scalar @values))
    for 0 .. $#values;


# some torture
SKIP: {

  skip "This part of the test segfaults perl $] with both tie() and B::H::EOS."
    . ' Actual code (e.g. DBIx::Class) works fine so did not investigate further',
    2000 if $] < 5.008003;

  local @INC = @INC;
  my @code;
  unshift @INC, sub {

    if ($_[1] =~ /CleaneeTarget\/No(\d+)/) {
      my @code = (
        "package CleaneeTarget::No${1};",
        "sub x_foo { 'XFOO' }",
        "sub x_bar { 'XBAR' }",

        "use CleaneeBridgeExplicit;",

        "1;",
      );

      return sub { return 0 unless @code; $_ = shift @code; 1; }
    }
    else {
      return ();
    }
  };

  for (1..1000) {
    my $pkg = "CleaneeTarget::No${_}";

    my @val = require "CleaneeTarget/No${_}.pm";

    ok !$pkg->can('x_foo'),    'explicitely removed disappeared';
    ok  $pkg->can('x_bar'),    'not in explicit removal and still there';
  }
}
