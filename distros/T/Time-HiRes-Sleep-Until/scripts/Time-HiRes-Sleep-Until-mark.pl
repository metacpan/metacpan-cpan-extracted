#!/usr/bin/perl
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
use Time::HiRes qw{time};
use Time::HiRes::Sleep::Until;

my $mark           = shift || 5;
my $su             = Time::HiRes::Sleep::Until->new;
my $formatter      = DateTime::Format::Strptime->new(pattern=>q{%FT%T.%3N});
local $SIG{'INT'}  = \&_signal;
local $SIG{'TERM'} = \&_signal;
our $CONTINUE      = 1;
my $loop           = 0;

while ($CONTINUE) {
  $loop++;
  my $slept = $su->mark($mark);
  my $epoch = time;
  printf "%s (%0.3f): Loop: %s, Slept: %0.3f\n", DateTime->from_epoch(epoch=>$epoch, formatter=>$formatter), $epoch,  $loop, $slept;
}

sub _signal {
  $CONTINUE = 0;
  my $epoch = time;
  printf "\n%s (%0.3f): Exiting...\n", DateTime->from_epoch(epoch=>$epoch, formatter=>$formatter), $epoch;
}

__END__

=head1 NAME

Time-HiRes-Sleep-Until-mark.pl - Time::HiRes::Sleep::Until second mark of the clock

=cut
