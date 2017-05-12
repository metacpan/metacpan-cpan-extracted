# -*- perl -*-

# t/002_rdc.t - check module ability to regex on datacenters include/exclude

use Test::More tests => 3;
use Data::Dumper;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $matcher = Text::XmlMatch->new('extras/config.xml');
my $results = $matcher->findMatch('nandc-7204-1-b-h.ndc.na.testdomain.com');

if ($results->{'RDC-Nashville'} eq 'facility') {
  pass('RDC Include');
} else {
  fail('RDC Include');
}


if ($results->{'RDC-Nashville-Non-7204'}) {
  fail('RDC Exclusion');
} else {
  pass('RDC Inclusion');
}  
