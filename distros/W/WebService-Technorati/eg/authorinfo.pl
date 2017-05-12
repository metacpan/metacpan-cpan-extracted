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
my $username = 'spidaman';
my $t = WebService::Technorati->new(key => $apiKey);
my $q = $t->getAuthorinfoApiQuery($username);
if (DEBUG) {
    my $result_xp = XML::XPath->new(filename => "$Bin/../t/testdata/getinfo.xml");
    $q->readResults($result_xp);
} else {
    $q->execute;
}
my $author = $q->getSubjectAuthor();
print "author: $author\n";
print Dumper($author);

my @blogs = $q->getClaimedBlogs();
for my $blog (@blogs) {
    print Dumper($blog);
}
