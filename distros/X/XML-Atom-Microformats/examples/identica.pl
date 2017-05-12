#!/usr/bin/perl

use 5.010;
use strict;
use utf8;
use XML::Atom::Microformats 0 qw();
use LWP::Simple 0 qw(get);

my $xml  = get('http://identi.ca/api/statuses/user_timeline/36737.atom');
my $xamf = XML::Atom::Microformats->new_feed($xml, "http://identi.ca/api/statuses/user_timeline/36737.atom");
$xamf->assume_profile('hCard');
print $xamf->json(pretty=>1,canonical=>1);
