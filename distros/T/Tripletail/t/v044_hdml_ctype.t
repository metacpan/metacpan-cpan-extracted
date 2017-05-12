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
		},
		method => 'GET',
		param  => {},
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->setContentFilter(
					"Tripletail::Filter::MobileHTML",
					contenttype => 'text/x-hdml; charset=Shift_JIS',
				);
				$TL->print("print1\n");
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[test1] fetch") or skip("[test1] fetch failed", 3);
		ok($ret->{content}, "[test1] has content");
		is($ret->{headers}{'Content-Type'}[0], 'text/x-hdml; charset=Shift_JIS', "[test1] hdml content-type");
	}
}
