#!/usr/local/bin/perl -w

use strict;

use WWW::Meta::XML::Browser;

my $browser = WWW::Meta::XML::Browser->new(debug => 1);
$browser->process_file('hoerzu.xml');
$browser->process_all_request_nodes();
$browser->merge_subrequests(1, 'program');
$browser->print_request_result($browser->get_request_result(1,0));