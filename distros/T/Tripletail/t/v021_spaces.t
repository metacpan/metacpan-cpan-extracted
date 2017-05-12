## ----------------------------------------------------------------------------
#  t/v21_ifilter.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YMIRLINK, Inc.
# -----------------------------------------------------------------------------
# $Id: v021_spaces.t 4241 2007-09-04 04:24:48Z hio $
# -----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Config;
use lib '.';
use t::test_server;

&setup;
plan tests => 2*5 + 1;

&test01_test;   #2*5.
&test02_multiline_header;  #1;

# -----------------------------------------------------------------------------
# shortcut.
# 
sub check_requires() { &t::test_server::check_requires; }
sub start_server()   { &t::test_server::start_server; }
sub request_post(@)   { &t::test_server::request_post; }
sub rupload($)
{
	my $send = shift;
	
	my $boundary = '----------cHbWOwLyInYcpSVJXPQxBp';
	my $content = '';
	$content .= qq{--$boundary\r\n};
	$content .= qq{Content-Disposition: form-data; name="data"\r\n};
	$content .= qq{\r\n};
	$content .= qq{$send\r\n};
	$content .= qq{--$boundary--\r\n};
	
	request_post(
		script => q{
			my $recv = $CGI->get('data') || '(no data)';
			"ok [$recv]";
		},
		stdin => $content,
		params => [
			'Content-Type' => qq{multipart/form-data; boundary="$boundary"},
		],
	);
}

# -----------------------------------------------------------------------------
# setup.
# 
sub setup
{
	my $failmsg = check_requires();
	if( $failmsg )
	{
		plan skip_all => $failmsg;
	}
	
	&start_server;
}

# -----------------------------------------------------------------------------
# test.
# 
sub test01_test
{
	foreach (
		{ name=>'simple',  send=>'simple text', },
		{ name=>'space',   send=>' ',           },
		{ name=>'space2',  send=>' x',          },
		{ name=>'tab',     send=>"\t",          },
		{ name=>'text',    send=>"last text"    },
	)
	{
		my $name = $_->{name};
		my $send = $_->{send};
		SKIP:
		{
			my $res = eval{ rupload("$send") };
			my $succ = is( "$@", '', "[test.$name] request suceeded");
			if( !$succ )
			{
				skip "[test.$name] request failed" => 1;
			}
			is( $res, "ok [$send]", "[test.$name] result is valid");
		}
	}
}

# -----------------------------------------------------------------------------
# multiline header.
# 
sub test02_multiline_header
{
	{
		my $send = "mmm";
		
		my $boundary = '----------cHbWOwLyInYcpSVJXPQxBp';
		my $content = '';
		$content .= qq{--$boundary\r\n};
		$content .= qq{Content-Disposition:\r\n form-data;\r\n\tname="data"\r\n};
		$content .= qq{\r\n};
		$content .= qq{$send\r\n};
		$content .= qq{--$boundary--\r\n};
		
		my $res = request_post(
			script => q{
				my $recv = $CGI->get('data') || '(no data)';
				"ok [$recv]";
			},
			stdin => $content,
			params => [
				'Content-Type' => qq{multipart/form-data; boundary="$boundary"},
			],
		);
		is($res, "ok [$send]", "[test02] multiline header");
	}
}
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
