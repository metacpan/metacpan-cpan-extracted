#! perl -w

use strict;
use warnings;

use lib 't';
require t::make_ini;

use Test::More;

plan tests =>
  +2
  ;

&test01();

sub test01
{
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
			},
			Debug => {
			},
		},
		method => 'GET',
		param  => {},
		sub => sub{
			our $TL;
			eval { $TL->startCgi(-main=>sub{
				my $count = 0;
				$TL->dispatch("xxx",
					onerror => sub{
						++ $count;
					},
				);
				$TL->print("count=$count\n");
			}) };
		},
	});
	SKIP:{
		ok($ret->is_success, "[test1] fetch") or skip("[test1] fetch failed", 3);
		is($ret->{content}, "count=1\n", "[test1] content is [count=1]");
	}
}

