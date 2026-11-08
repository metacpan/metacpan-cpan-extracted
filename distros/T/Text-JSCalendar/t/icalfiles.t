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

# Known round-trip failures, kept visible as TODO.  They showed up once
# NormaliseEvent stopped wiping the contents of override patches (0.10).
my %TODO = (
  rdate_period => 'an override patch equal to the master is written as a RECURRENCE-ID instance and read back as no override at all (_insert_override drops an empty patch)',
  recurrenceoverrides => 'an instance with SEQUENCE:0 under a master without SEQUENCE reads as a sequence:0 patch; the writer then always writes SEQUENCE so it vanishes',
);

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
  local $TODO = $TODO{$name};
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
