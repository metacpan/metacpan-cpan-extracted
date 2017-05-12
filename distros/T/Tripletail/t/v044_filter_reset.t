#! perl -w

use strict;
use warnings;

use lib 't';
require t::make_ini;

use Test::More;

plan tests =>
  +4
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
				$TL->print("print1\n");
				$TL->log("log1\n");
				die("die1\n");
			}) };
			eval { $TL->startCgi(-main=>sub{
				#$TL->print("print2\n");
				$TL->log("log2\n");
				die("die2\n");
			}) };
		},
	});
	SKIP:{
		#ok($ret->is_success, "[test1] fetch") or skip("[test1] fetch failed", 3);
		ok($ret->{content}, "[test1] has content");
		$ret->{content} =~ s{(?<=<br />)}{\n}g;

		ok($ret->{content} =~ /die1/, "[test1] contains die1");
		ok($ret->{content} =~ /die2/, "[test1] contains die2");
		ok($ret->{content} =~ /<html/, "[test1] contains '<html'");
	}
}
