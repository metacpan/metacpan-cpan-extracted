#!/usr/bin/perl
use WWW::Dict::Leo::Org;

# configure access to dict.leo.org
my $leo = new WWW::Dict::Leo::Org(
                                  -UserAgent      => 'IE 19',
                                  #-Proxy         => 'http://127.0.0.1:3128',
                                  #-ProxyUser     => 'me',
                                  #-ProxyPass     => 'pw',
                                  -Debug          => 0,
                                  -SpellTolerance => 'on',
                                  -Morphology     => 'standard',
                                  -CharTolerance  => 'relaxed',
                                  -Language       => 'de2ru'
                                 );

# fetch matches
my @matches = $leo->translate(shift || die "Usage: $0 <term>\n");

# print the first, if any
if (@matches && $leo->lines() >= 1) {
  printf "%s\n", $matches[0]->{data}->[0]->{left};
}
else {
  print "fail\n";
}
