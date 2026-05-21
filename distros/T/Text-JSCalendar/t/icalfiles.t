#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS;
use Text::JSCalendar;

my $testdir = "testdata/icalendar";

opendir(DH, $testdir);
my @list;
while (my $item = readdir(DH)) {
  next unless $item =~ m/(.*).ics/;
  my $name = $1;
  next if ($ENV{TESTNAME} and $name ne $ENV{TESTNAME});
  push @list, $name;
}
closedir(DH);

plan tests => scalar(@list);

my $jscal = Text::JSCalendar->new();

foreach my $name (@list) {
  my $ical = slurp($name, 'ics');
  warn $ical if $ENV{NOISY};
  my @idata = $jscal->vcalendarToEvents($ical);
  $_ = $jscal->NormaliseEvent($_) for @idata;
  warn JSON::XS->new->pretty(1)->canonical(1)->encode(\@idata) if $ENV{NOISY};

  # round trip it
  my $newical = $jscal->eventsToVCalendar(@idata);
  warn $newical if $ENV{NOISY};
  # and round trip it back again
  my @back = $jscal->vcalendarToEvents($newical);
  # and it's still the same
  $_ = $jscal->NormaliseEvent($_) for @back;
  warn JSON::XS->new->pretty(1)->canonical(1)->encode(\@back) if $ENV{NOISY};
  is_deeply(\@back, \@idata, "$name roundtrip");
}

sub slurp {
  my $name = shift;
  my $ext = shift;
  open(FH, "<$testdir/$name.$ext") || return;
  local $/ = undef;
  my $data = <FH>;
  close(FH);
  return $data;
}
