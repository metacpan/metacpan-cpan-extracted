#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;




my $inner = "<head></head><body><p>Hi there</p><p>How is life?</p></body>";
my $html = "<html>$inner</html>";

my $j = j($html);

is $j->html, $inner, "html() returns inner html";
is $j->as_html, $html, "as_html() returns element itself";

is $j->find('p')->html('nice')->end->as_html, '<html><head></head><body><p>nice</p><p>nice</p></body></html>';

# html
is j($html)->find('body')->detach->find('p:first-child')->html, 'Hi there', "html() on unbound nodes";

done_testing;
