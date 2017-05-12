#! perl -w

use strict;
use warnings;

use Test::More tests =>
  + 4
;
use lib '.';
require t::make_ini;

&test;

sub test
{
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
				outputbuffering => 1,
			},
		},
		method => 'GET',
		param  => {},
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->setContentFilter('Tripletail::Filter::CSV');
				$TL->print([1]);
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[test1] fetch") or skip("[test1] fetch failed", 3);
		ok($ret->{content}, "[test1] has content");

		is($ret->{content}, "1\r\n", "[test1] valid content");
		is_deeply($ret->{headers}{'Content-Length'}, [3], "[test1] clen: 3");
	}
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
