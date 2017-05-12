#! perl -w

use strict;
use warnings;

use lib 't';
require t::make_ini;

use Test::More;

plan tests =>
  +3
  ;

&test01();

sub test01
{
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
			},
			Debug => {
				enable_debug => 1,
				popup_type   => 'single',
			},
		},
		method => 'GET',
		param  => {},
		sub => sub{
			our $TL;
			print "Content-Type: text/plain\r\n\r\n";
			eval { $TL->startCgi(-main=>sub{
				$TL->print(""); # empty string.
				die("die1\n");
			}) };
		},
	});
	SKIP:{
		ok($ret->is_success, "[test1] fetch") or skip("[test1] fetch failed", 3);
		ok($ret->{content}, "[test1] has content");
		ok($ret->{content} =~ /^Content-Type:/m , "[test1] has Content-Type");
	}
}

