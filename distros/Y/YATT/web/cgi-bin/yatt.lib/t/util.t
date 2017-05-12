#!/usr/bin/perl
use strict;
use File::Basename;
use lib dirname(__FILE__) . "/..", dirname(__FILE__);

use Test::More qw(no_plan);

use_ok(qw(YATT::Util));
use YATT::Util;

ok(1 == (lsearch {defined} [undef, 0, undef]), 'lsearch 1st defined');
ok(3 == (lsearch {defined} [0, undef, undef, 1], 1), 'lsearch next defined');
ok(not (defined lsearch {$_ > 10} [0 .. 8]), 'lsearch greater than 10');

sub copy {my $cp = shift};

is escape(copy(q{<foo "bar"&'baz'>}))
  , '&lt;foo &quot;bar&quot;&amp;&#39;baz&#39;&gt;', 'escape - basic';

is join("", escape(\ q{<a>}, copy(q{<b>bar</b>}), \ q{</a>}))
  , q{<a>&lt;b&gt;bar&lt;/b&gt;</a>}, 'escape - list context, scalar ref';

BEGIN {
  package util_test_base;
  use fields qw(foo bar);
  sub new {fields::new(shift)}

  package util_test;
  use base qw(util_test_base);
  use fields qw(baz);
}

SKIP: {
  skip "Hash::Util is only used for newer perl", 1 unless $] >= 5.009;
  require_ok('Hash::Util');
};
require_ok('YATT::Util::Symbol');

my $orig = util_test_base->new;

is ref YATT::Util::Symbol::rebless_with($orig, 'util_test')
  , 'util_test', 'rebless_with';
