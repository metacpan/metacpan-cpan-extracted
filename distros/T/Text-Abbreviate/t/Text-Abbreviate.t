# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Abbreviate.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 27 };
use Text::Abbreviate;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $abbrev = Text::Abbreviate->new(qw( this that and the other thing often OFF ));

for (0 .. 1) {
  $abbrev->folding($_);
  my %a;

  for my $term (qw( this off OTTO )) {
    for my $l (1 .. length($term)) {
      $a{substr($term, 0, $l)} = $abbrev->expand(substr($term, 0, $l));
    }
  }

  ok(@{ $a{t} } == 4);
  ok(@{ $a{th} } == 4);
  ok(@{ $a{thi} } == 2);
  ok(@{ $a{this} } == 1);
  ok(@{ $a{o} } == ($_ ? 3 : 2));
  ok(@{ $a{of} } == ($_ ? 2 : 1));
  ok(@{ $a{off} } == ($_ ? 1 : 0));
  ok(@{ $a{O} } == ($_ ? 3 : 1));
  ok(@{ $a{OT} } == ($_ ? 1 : 0));
  ok(@{ $a{OTT} } == 0);
  ok(@{ $a{OTTO} } == 0);

  my $un = $abbrev->unambiguous;
  ok($un->{often}[0] eq ($_ ? "oft" : "of"));
  ok($un->{OFF}[0] eq ($_ ? "OFF" : "O"));
}
