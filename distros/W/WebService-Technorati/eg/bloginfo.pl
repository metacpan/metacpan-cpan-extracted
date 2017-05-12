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
my $url = 'http://www.arachna.com/roller/page/spidaman';
my $t = WebService::Technorati->new(key => $apiKey);
my $q = $t->getBloginfoApiQuery($url);
if (DEBUG) {
    my $result_xp = XML::XPath->new(filename => "$Bin/../t/testdata/bloginfo.xml");
    $q->readResults($result_xp);
} else {
    $q->execute;
}
my $blog = $q->getSubjectBlog();
print "blog: $blog\n";
print Dumper($blog);
