use strict;
use utf8;

no warnings 'utf8';

use Test::More;
use Test::NoWarnings;

use Unicode::Stringprep;

my @data; while(<DATA>) {
  my @c = map { s/^\s+|\s+$//g;$_; } split m/;/, $_, 3;
  push @data, \@c if $#c > 1;
}

plan tests => ($#data+1) + 2;
ok($#data > 2, 'number of test patterns');

my $func = Unicode::Stringprep->new('3.2', undef, 'KC');

foreach my $d (@data) {
  $d->[2] = sprintf('U+%s - %s', uc($d->[0]), $d->[2]) 
    unless $d->[0] =~ m/\s/;

  $d->[1] ||= $d->[0];

  foreach my $c (0..1) {
    if($d->[$c] =~ m/undef/) {
      $d->[$c] = undef; 
      next;
    }
    $d->[$c] = join '',
      map { chr hex $_ }
	grep { length($_) > 0 }
          split /\s+/, $d->[$c];
  }
  is( eval{ $func->($d->[0]) }, $d->[1], $d->[2] );
};
exit(0);

__DATA__

F951; 964B; Erroneous mapping (Corrigendum 3, corrected in Unicode 3.2)

2F868; 2136A; Erroneous mapping (Corrigendum 4, corrected in Unicode 4.0)
2F874; 5F33; Erroneous mapping (Corrigendum 4, corrected in Unicode 4.0)
2F91F; 43AB; Erroneous mapping (Corrigendum 4, corrected in Unicode 4.0)
2F95F; 7AAE; Erroneous mapping (Corrigendum 4, corrected in Unicode 4.0)
2F9BF; 4D57; Erroneous mapping (Corrigendum 4, corrected in Unicode 4.0)

2047; 3F 3F; DOUBLE QUESTION MARK (added in 3.2)
205F; 20; MEDIUM MATHEMATICAL SPACE (added in 3.2)
30FF; 30B3 30C8; KATAKANA DIGRAPH KOTO (added in 3.2)
2ADC; 2ADD 0338; FORKING (added in 3.2)
1D15E; 1D157 1D165; MUSICAL SYMBOL HALF NOTE (added in 3.1)

213B;; FACSIMILE SIGN (added in 4.0)
1EA5 35D 329;; No reordering for U+035D (added in 4.0)

0B47 0300 0B3E; undef; PR 29 test case 1
1100 0300 1161; undef; PR 29 test case 2
1100 0300 1161 0323; undef; PR 29 test case 2, expanded
