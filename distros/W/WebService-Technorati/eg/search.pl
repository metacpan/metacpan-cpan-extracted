#!/usr/bin/perl

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../blib/lib");
}
use strict;
use Data::Dumper;
use WebService::Technorati;
use XML::XPath;
use constant DEBUG => 1;


my $apiKey = 'XXXX_api_key_XXXX';
my $keyword = 'http://www.arachna.com/roller/page/spidaman';
my $t = WebService::Technorati->new(key => $apiKey);
my $q = $t->getSearchApiQuery($keyword);
if (DEBUG) {
    my $result_xp = XML::XPath->new(filename => "$Bin/../t/testdata/search.xml");
    $q->readResults($result_xp);
} else {
    $q->execute;
}
my $term = $q->getSubjectSearchTerm();
print "term: $term\n";
print Dumper($term);
my @matches = $q->getSearchMatches();

for my $match (@matches) {
    print Dumper($match);
}
