use Test::Builder;
use lib '../lib';

use UDCode;

Test::Builder->new->plan(tests => 9);

sub ok_pair {
  my (@c) = @_;
  my %h = map { $_ => 1 } @c;
  my $t = Test::Builder->new;

  my ($a, $b) = ud_pair(@c);
  $t->diag("@$a == @$b\n");

  $t->ok(defined($a) && defined($b), "@c");

  $t->ok(join("", @$a) eq join("", @$b),
         "@c");
  my $bad_word;
  for my $c (@$a, @$b) {
    $bad_word = $c unless $h{$c};
  }
  $t->is_eq($bad_word, undef, "@c");
}

ok_pair("b", "ab", "abba"); # abba,b   ab,b,ab
ok_pair("a", "ab", "b"); # a,b      ab
ok_pair("a", "ab", "ba"); # ab,a    a,ba
