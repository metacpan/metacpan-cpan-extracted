#!/usr/bin/perl
use lib 'lib';
use XML::DOM::Lite ('Parser', ':constants');
use Time::HiRes qw(gettimeofday tv_interval);

my $xmldata .= q{
  <item attrrib="value">
    <child>child text</child>
  </item>} x 25000;

$xmldata = "<root>$xmldata</root>";

my $parser = Parser->new(whitespace => 'strip');
my $t0 = [gettimeofday];
my $doc = $parser->parse($xmldata);
my $t1 = [gettimeofday];

my $elapsed = tv_interval ( $t0, $1 );

print "ELAPSED => $elapsed, TOTAL NODES => ".($doc->documentElement->childNodes->length * 4)."\n";

