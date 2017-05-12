#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 5;
use Test::Differences;

use HTTP::Headers;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'WWW::Tracking' ) or exit;
	use_ok ( 'WWW::Tracking::Data' ) or exit;
	use_ok ( 'WWW::Tracking::Data::Plugin::Headers' ) or exit;
}

exit main();

sub grep2(&@){ 
    my $code = shift; 
    map{ 
        my @pair = (shift,shift); 
        $code->( @pair ) ? @pair : ()
    } 0 .. $#_/2 
}

sub main {
	my $td = WWW::Tracking::Data->new();
	my $wt = WWW::Tracking->new();

	can_ok($td, 'from_headers');
	
    $wt->from(
		'headers' => {
			'headers' => HTTP::Headers->new(
				'Cookie'     => 'a=b;__vcid=321;c=d',
				'Host'       => 'example.com',
				'Referer'    => 'http://example2.com/2/example.com',
				'User-Agent' => 'Test-More',
				'Accept-Charset'  => 'UTF-8,*',
				'Accept-Language' => 'en-us,en;q=0.5',
			),
			'request_uri' => '/test',
			'remote_ip'   => '1.2.3.4',
			'visitor_cookie_name' => '__vcid',
		},
    );
    
    eq_or_diff(
    	{
			grep2 { $_[0] ne 'timestamp' }
    		%{$wt->data->as_hash}
    	},
    	{
            'request_uri' => '/test',
            'remote_ip' => '1.2.3.4',
            'user_agent' => 'Test-More',
            'hostname' => 'example.com',
            'browser_language' => 'en-us,en;q=0.5',
            'visitor_id' => '321',
            'referer' => 'http://example2.com/2/example.com',
            'encoding' => 'UTF-8,*'
		},
    	'from_headers()'
    );
    
	return 0;
}
