#!/usr/bin/perl -wT
use strict; use diagnostics; use warnings;

# usage:  perl get_patent.pl US6123456 > US6123456.pdf 

use WWW::Patent::Page;

my $agent = WWW::Patent::Page->new();

my $request = shift;

my $response = $agent->get_page($request);

print $response->content;

__END__

