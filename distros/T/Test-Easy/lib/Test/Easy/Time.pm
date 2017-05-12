package Test::Easy::Time;
use base qw(Exporter);

use strict;
use warnings;

require Test::Easy;
use Test::Easy::equivalence;

our @EXPORT = qw(time_nearly);

my @_formatters = ({
  _description => 'output of localtime',
  format_epoch_seconds => sub {
    return scalar(localtime($_));
  },
});

sub add_format { shift; push @_formatters, +{@_} }

sub time_nearly {
  my ($got, $expected, $epsilon) = @_;

  my ($low, $high) = ($expected - $epsilon, $expected + $epsilon);
  my $guess;
  local $_;

  my @testers = map {
    my $formatter = $_;
    Test::Easy::equivalence->new(
      test => sub {
        local $_ = shift;
        return $formatter->{format_epoch_seconds}->() eq $got;
      },
    );
  } @_formatters;

  SAMPLE: foreach my $try ($low .. $high) {
    foreach my $tester (@testers) {
      if ($tester->check_value($try)) {
        $guess = $try;
        last SAMPLE;
      }
    }
  }

  return 0 unless defined $guess;
  return Test::Easy::nearly($guess, $expected, $epsilon);
}

1;
