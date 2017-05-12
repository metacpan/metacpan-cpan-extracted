#!/usr/bin/perl -w

use strict;
use Test::More tests => 46;

use_ok( 'Text::Sequence' );

my @elements = (
  map("foo$_.ext", 13..15, 5..11),
);

my ($singles, %seqs) = find_into_hash(@elements);
is(scalar keys %seqs, 1, 'one seq');
my $seq = $seqs{'foo%d.ext'};
ok($seq, 'template');
my @members = $seq->members;
# order is preserved for items of same width
ok(eq_array(\@members, [ 5..9, 13..15, 10..11 ]), 'members');

push @elements, 'foo123.ext', map "foo0$_.ext", 7..9;
($singles, %seqs) = find_into_hash(@elements);
is(scalar keys %seqs, 2, 'more seqs');
is(scalar @$singles, 0, 'no singletons');
ok($seqs{'foo%.2d.ext'}, 'template 1');
ok($seqs{'foo%d.ext'},   'template 2');
@members = $seqs{'foo%.2d.ext'}->members;
ok(eq_array(\@members, [ 7..9, 13..15, 10..11 ]), 'members 1');
@members = $seqs{'foo%d.ext'}->members;
ok(eq_array(\@members, [ 5..9, 123 ]), 'members 2');

# Now confuse things even further by having multiple digits
push @elements, map sprintf("foo07-%02d.ext", $_), 26, 13, 6;
($singles, %seqs) = find_into_hash(@elements);
is(scalar keys %seqs, 3, 'yet more seqs');
is(scalar @$singles, 0, 'no singletons');
ok($seqs{'foo%.2d.ext'},    'template 1');
ok($seqs{'foo%d.ext'},      'template 2');
ok($seqs{'foo07-%.2d.ext'}, 'template 3');
@members = $seqs{'foo%.2d.ext'}->members;
ok(eq_array(\@members, [ 7..9, 13..15, 10..11 ]), 'members 1');
@members = $seqs{'foo%d.ext'}->members;
ok(eq_array(\@members, [ 5..9, 123 ]), 'members 2');
@members = $seqs{'foo07-%.2d.ext'}->members;
ok(eq_array(\@members, [ 6, 26, 13 ]), 'members 3');

# Add some singletons
push @elements, 'like a s0re thumb', 'black_sh33p';
($singles, %seqs) = find_into_hash(@elements);
is(scalar keys %seqs, 3, 'yet more seqs');
ok(eq_array([ sort @$singles ], [ @elements[ -1, -2 ] ]), 'singletons');
ok($seqs{'foo%.2d.ext'},    'template 1');
ok($seqs{'foo%d.ext'},      'template 2');
ok($seqs{'foo07-%.2d.ext'}, 'template 3');
@members = $seqs{'foo%.2d.ext'}->members;
ok(eq_array(\@members, [ 7..9, 13..15, 10..11 ]), 'members 1');
@members = $seqs{'foo%d.ext'}->members;
ok(eq_array(\@members, [ 5..9, 123 ]), 'members 2');
@members = $seqs{'foo07-%.2d.ext'}->members;
ok(eq_array(\@members, [ 6, 26, 13 ]), 'members 3');

# Now test letter sequences
my @letter_seq = map { "foo-07$_.ext" } 'c'..'e', 'a';
($singles, %seqs) = find_into_hash(@letter_seq);
is(scalar keys %seqs, 1, 'one letter seq');
is(scalar @$singles, 0, 'no singletons');
ok($seqs{'foo-07%s.ext'}, 'template');
@members = $seqs{'foo-07%s.ext'}->members;
ok(eq_array(\@members, [ 'c'..'e', 'a' ]), 'members');

push @letter_seq, map { "foo-03$_.ext" } 'a', 'c';

($singles, %seqs) = find_into_hash(@letter_seq);
is(scalar @$singles, 0, 'no singletons');
is(scalar(grep /%s/,   keys %seqs), 2, 'letter seqs in combo');
# ('a', 'c') x ('03', 07') is the overlap 
is(scalar(grep /%.2d/, keys %seqs), 2, 'number seqs in combo');
ok($seqs{'foo-03%s.ext'}, "template foo-03%s.ext");
ok($seqs{'foo-07%s.ext'}, "template foo-03%s.ext");
ok($seqs{'foo-%.2da.ext'}, "template foo-%.2da.ext");
ok($seqs{'foo-%.2dc.ext'}, "template foo-%.2dc.ext");
@members = $seqs{'foo-07%s.ext'}->members;
ok(eq_array(\@members, [ 'c'..'e', 'a' ]), 'members');

push @letter_seq, 'foo-04b.ext';
($singles, %seqs) = find_into_hash(@letter_seq);
ok(eq_array($singles, [ $letter_seq[-1] ]), 'singletons');
is(scalar(grep /%s/,   keys %seqs), 2, 'letter seqs in combo');
# ('a', 'c') x ('03', 07') is the overlap 
is(scalar(grep /%.2d/, keys %seqs), 2, 'number seqs in combo');
ok($seqs{'foo-03%s.ext'}, "template foo-03%s.ext");
ok($seqs{'foo-07%s.ext'}, "template foo-03%s.ext");
ok($seqs{'foo-%.2da.ext'}, "template foo-%.2da.ext");
ok($seqs{'foo-%.2dc.ext'}, "template foo-%.2dc.ext");
@members = $seqs{'foo-07%s.ext'}->members;
ok(eq_array(\@members, [ 'c'..'e', 'a' ]), 'members');

sub find_into_hash {
  my ($seqs, $singles) = Text::Sequence::find(@_);
  my %hash;
  foreach my $seq (@$seqs) {
    die "duplicate templates" if $hash{$seq->template};
    $hash{$seq->template} = $seq;
  }
  return ($singles, %hash);
}
