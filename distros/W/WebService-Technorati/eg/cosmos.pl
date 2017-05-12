#!/usr/bin/perl

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../blib/lib");
}
use strict;
use Data::Dumper;
use WebService::Technorati;
use XML::XPath;
use XML::Parser;
use constant DEBUG => 1;

my $parser = new XML::Parser(NoLWP => 1);
my $apiKey = 'XXXX_api_key_XXXX';
my $url = 'http://www.arachna.com/roller/page/spidaman';
my $t = WebService::Technorati->new(key => $apiKey);
my $q = $t->getCosmosApiQuery($url);
if (DEBUG) {
    my $result_xp = XML::XPath->new(
        parser => $parser,
        filename => "$Bin/../t/testdata/cosmos.xml");
    $q->readResults($result_xp);
} else {
    $q->execute;
}
my $blog = $q->getLinkQuerySubject();
print "blog: $blog\n";
print Dumper($blog);
my @links = $q->getInboundLinks();

for my $link (@links) {
    print Dumper($link);
}

if (DEBUG) {
    my $result_xp = XML::XPath->new(
        parser => $parser,
        filename => "$Bin/../t/testdata/cosmos-nonblog.xml");
    $q->readResults($result_xp);
}
my $linkquery = $q->getLinkQuerySubject();
print "subject: $linkquery\n";
print Dumper($linkquery);
@links = $q->getInboundLinks();
for my $link (@links) {
    print Dumper($link);
}
print "link subject has " . $linkquery->getInboundlinks() . " inboundlinks\n";
