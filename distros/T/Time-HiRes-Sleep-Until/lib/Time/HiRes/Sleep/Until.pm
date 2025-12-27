package Time::HiRes::Sleep::Until;
use strict;
use warnings;
use base qw{Package::New};
use Time::HiRes qw{};
use Math::Round qw{}; 

our $VERSION = '0.10';

=head1 NAME

Time::HiRes::Sleep::Until - Provides common ways to sleep until...

=head1 SYNOPSIS

  use Time::HiRes::Sleep::Until;
  my $su    = Time::HiRes::Sleep::Until->new;
  my $slept = $su->epoch($epoch); # epoch is a calculated time + $seconds
  my $slept = $su->mark(20);      # sleep until 20 second mark of the clock :00, :20, or :40
  my $slept = $su->second(45);    # sleep until 45 seconds after the minute


=head1 DESCRIPTION

Sleep Until provides sleep wrappers for sleep functions that I commonly need.  These methods are simply wrappers around L<Time::HiRes> and L<Math::Round>.

We use this package to make measurements at the same time within the minute for integration with RRDtool.

=head1 USAGE

  use strict;
  use warnings;
  use DateTime;
  use Time::HiRes::Sleep::Until;
  my $su = Time::HiRes::Sleep::Until->new;
  do {
    print DateTime->now, "\n"; #make a measurment three times a minute
  } while ($su->mark(20));

Perl One liner

  perl -MTime::HiRes::Sleep::Until -e 'printf "Slept: %s\n", Time::HiRes::Sleep::Until->new->top'

=head1 CONSTRUCTOR

=head2 new

  use Time::HiRes::Sleep::Until;
  my $su = Time::HiRes::Sleep::Until->new;

=head1 METHODS

=head2 epoch

Sleep until provided epoch in float seconds.

  while ($CONTINUE) {
    my $sleep_epoch = $su->time + 60/8;
    do_work();                #run process that needs to run back to back but not more than 8 times per minute
    $su->epoch($sleep_epoch); #sleep(7.5 - runtime). if runtime > 7.5 seconds does not sleep
  }

=cut

sub epoch {
  my $self  = shift;
  my $epoch = shift || 0; #default is 1970-01-01 00:00
  my $sleep = $epoch - Time::HiRes::time();
  return $sleep <= 0 ? 0 : Time::HiRes::sleep($sleep);
}

=head2 mark

Sleep until next second mark;

  my $slept = $su->mark(20); # 20 second mark, i.e.  3 times a minute on the 20s
  my $slept = $su->mark(10); # 10 second mark, i.e.  6 times a minute on the 10s
  my $slept = $su->mark(6);  #  6 second mark, i.e. 10 times a minute on 0,6,12,...

=cut

sub mark {
  my $time  = Time::HiRes::time();
  my $self  = shift;
  my $mark  = shift || 0;
  die("Error: mark requires parameter to be greater than zero.") unless $mark > 0;
  my $epoch = Math::Round::nhimult($mark => $time); #next mark
  return $self->epoch($epoch);
}

=head2 second

Sleep until the provided seconds after the minute

  my $slept = $su->second(0);  #sleep until top of minute
  my $slept = $su->second(30); #sleep until bottom of minute

=cut

sub second {
  my $time     = Time::HiRes::time();
  my $self     = shift;
  my $second   = shift || 0; #default is top of the minute
  my $min_next = Math::Round::nhimult(60 => $time);
  my $min_last = $min_next - 60;
  return $time < $min_last + $second
           ? $self->epoch($min_last + $second)
           : $self->epoch($min_next + $second);
}

=head2 top

Sleep until the top of the minute

  my $slept = $su->top; #alias for $su->second(0);

=cut

sub top {
  my $self = shift;
  return $self->second(0);
}

=head2 time

Method to access Time::HiRes time without another import.

=cut

sub time {return Time::HiRes::time()};

=head2 sleep

Method to access Time::HiRes sleep without another import.

=cut

sub sleep {
  my $self = shift;
  return @_ ? Time::HiRes::sleep($_[0]) : CORE::sleep();
}

=head1 LIMITATIONS

The mathematics add a small amount of delay for which we do not account.  Testing routinely passes with 100th of a second accuracy and typically with millisecond accuracy.

=head1 BUGS

Please log on GitHub

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT

MIT License

Copyright (c) 2025 Michael R. Davis

=head1 SEE ALSO

L<Time::HiRes>, L<Math::Round>

=cut

1;
