#!/usr/bin/perl

use strict;
use WWW::HtmlUnit::Sweet;

my $agent = WWW::HtmlUnit::Sweet->new(
  version => 'FIREFOX_3',
  url => 'http://google.com/'
);

# For some reason we must send \n separately for google
$agent->type("HtmlUnit");
$agent->type("\n");

print "Result:\n" . $agent->asXml . "\n\n";

