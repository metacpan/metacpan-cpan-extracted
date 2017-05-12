#!/usr/bin/env perl

use Test::More tests => 6;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
	use_ok( 'WWW::WebDevout::BrowserSupportInfo' );
}

diag( "Testing WWW::WebDevout::BrowserSupportInfo $WWW::WebDevout::BrowserSupportInfo::VERSION, Perl $], $^X" );

use strict;
use warnings;

use WWW::WebDevout::BrowserSupportInfo;

my $wd = WWW::WebDevout::BrowserSupportInfo->new;

isa_ok( $wd, 'WWW::WebDevout::BrowserSupportInfo' );
can_ok( $wd, qw(new fetch error results browser_results what uri_info
make_long_name browser_info browsers long ua_args
) );