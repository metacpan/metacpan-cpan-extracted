#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS;
use Text::JSCalendar;

my $jscal = Text::JSCalendar->new();

my $arg = $ARGV[0];
my $norm = 0;
if ($arg and $arg eq '-n') {
  $norm = 1;
  shift;
}

$/ = undef;
my $ical = <>;
print $ical;
my @idata = $jscal->vcalendarToEvents($ical);
if ($norm) {
  $_ = $jscal->NormaliseEvent($_) for @idata;
}
print JSON::XS->new->pretty(1)->canonical(1)->encode(\@idata);
