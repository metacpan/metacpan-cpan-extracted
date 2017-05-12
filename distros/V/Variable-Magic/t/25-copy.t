#!perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers;

use Variable::Magic qw<wizard cast dispell VMG_COMPAT_CODE_COPY_CLONE>;

plan tests => 2 + ((2 * 5 + 3) + (2 * 2 + 1)) + (2 * 9 + 6) + 3 + 1;

use lib 't/lib';
use Variable::Magic::TestWatcher;
use Variable::Magic::TestValue;

my $wiz = init_watcher 'copy', 'copy';

SKIP: {
 load_or_skip('Tie::Array', undef, undef, (2 * 5 + 3) + (2 * 2 + 1));

 tie my @a, 'Tie::StdArray';
 @a = (1 .. 10);

 my $res = watch { cast @a, $wiz } { }, 'cast on tied array';
 ok $res, 'copy: cast on tied array succeeded';

 watch { $a[3] = 13 } { copy => 1 }, 'tied array store';

 my $s = watch { $a[3] } { copy => 1 }, 'tied array fetch';
 is $s, 13, 'copy: tied array fetch correctly';

 $s = watch { exists $a[3] } { copy => 1 }, 'tied array exists';
 ok $s, 'copy: tied array exists correctly';

 watch { undef @a } { }, 'tied array undef';

 {
  tie my @val, 'Tie::StdArray';
  @val = (4 .. 6);

  my $wv = init_value @val, 'copy', 'copy';

  value { $val[3] = 8 } [ 4 .. 6 ];

  dispell @val, $wv;
  is_deeply \@val, [ 4 .. 6, 8 ], 'copy: value after';
 }
}

SKIP: {
 load_or_skip('Tie::Hash', undef, undef, 2 * 9 + 6);

 tie my %h, 'Tie::StdHash';
 %h = (a => 1, b => 2, c => 3);

 my $res = watch { cast %h, $wiz } { }, 'cast on tied hash';
 ok $res, 'copy: cast on tied hash succeeded';

 watch { $h{b} = 7 } { copy => 1 }, 'tied hash store';

 my $s = watch { $h{c} } { copy => 1 }, 'tied hash fetch';
 is $s, 3, 'copy: tied hash fetch correctly';

 $s = watch { exists $h{a} } { copy => 1 }, 'tied hash exists';
 ok $s, 'copy: tied hash exists correctly';

 $s = watch { delete $h{b} } { copy => 1 }, 'tied hash delete';
 is $s, 7, 'copy: tied hash delete correctly';

 watch { my ($k, $v) = each %h } { copy => 1 }, 'tied hash each';

 my @k = watch { keys %h } { }, 'tied hash keys';
 is_deeply [ sort @k ], [ qw<a c> ], 'copy: tied hash keys correctly';

 my @v = watch { values %h } { copy => 2 }, 'tied hash values';
 is_deeply [ sort { $a <=> $b } @v ], [ 1, 3 ], 'copy: tied hash values correctly';

 watch { undef %h } { }, 'tied hash undef';
}

SKIP: {
 skip 'copy magic not called for cloned prototypes before perl 5.17.0' => 3
                                              unless VMG_COMPAT_CODE_COPY_CLONE;
 my $w = wizard copy => sub {
  is ref($_[0]), 'CODE', 'first arg in copy on clone is a code ref';
  is $_[2],      undef,  'third arg in copy on clone is undef';
  is ref($_[3]), 'CODE', 'fourth arg in copy on clone is a code ref';
 };
 eval <<'TEST_COPY';
  package X;
  sub MODIFY_CODE_ATTRIBUTES {
   my ($pkg, $sub) = @_;
   &Variable::Magic::cast($sub, $w);
   return;
  }
  my $i;
  my $f = sub : Hello { $i };
TEST_COPY
}
