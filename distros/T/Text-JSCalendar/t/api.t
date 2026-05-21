#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS;
use Text::JSCalendar;

my $testdir = "testdata";

opendir(DH, $testdir);
my @list;
while (my $item = readdir(DH)) {
  next unless $item =~ m/(.*).ics/;
  push @list, $1;
}
closedir(DH);

plan tests => scalar(@list) * 2;

my $jscal = Text::JSCalendar->new();

foreach my $name (@list) {
  my $ical = slurp($name, 'ics');
  my $api = slurp($name, 'je');
  my @idata = $jscal->vcalendarToEvents($ical);
  die JSON::XS->new->pretty(1)->canonical(1)->encode(\@idata) unless $api;
  warn JSON::XS->new->pretty(1)->canonical(1)->encode(\@idata) if $ENV{NOISY};

  my $adata = JSON::XS::decode_json($api);

  is_deeply(\@idata, $adata, $name);

  # round trip it
  my $newical = $jscal->eventsToVCalendar(@idata);
  warn $newical if $ENV{NOISY};
  # and round trip it back again
  my @back = $jscal->vcalendarToEvents($newical);
  # and it's still the same
  is_deeply(\@back, $adata, "$name roundtrip");
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
