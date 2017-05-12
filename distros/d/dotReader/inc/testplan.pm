package main; # because Test::More needs caller
# yeah, we should test::builder::whatever or something

require Test::More;

=head1 Usage

It is a switch you can flip.  The first argument is true or false.  If
it is true, your number of tests is the second argument.

  use inc::testplan(1, 50);

  use inc::testplan(0, 50);

=cut

my $has_plan;
my $tests;
my $done = 0;
my $pid; # to play nice with forks
sub inc::testplan::import {
  my $who = shift;
  ($has_plan, $tests) = @_;
  Test::More->import(($has_plan ? (tests => $tests) : ('no_plan')));
  $pid = $$;
}

sub done () {
  ($$ == $pid) or return;
  if($has_plan) {
    my $self = Test::More->builder;
    ($self->{Curr_Test} < $tests) and
      warn "\n\n  called done before plan finished\n\n  ";
  }
  $done = 1;
}
END {
  if(defined($pid) and ($$ == $pid)) {
    unless($has_plan) {
      $done or die "\n  unplanned exit";
    }
  }
}
# vim:ts=2:sw=2:et:sta
1;
