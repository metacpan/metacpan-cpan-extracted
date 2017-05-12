#! perl -w

use strict;
use warnings;

use Test::More tests => 5+5;
use lib '.';
require t::make_ini;

&test01_default; # 5.
&test02_modify;  # 5.

sub test01_default
{
	# GET is not affected by TL/maxrequestsize.
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
				$TL->print("isConst: ".($TL->CGI->isConst?"yes":"no")."\n");
				eval{ $TL->CGI->set(x=>1) };
				my $err = $@;
				chomp $err;
				$TL->print("set: <$err>\n");
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[test1] fetch") or skip("[test1] fetch failed", 4);
		ok($ret->{content}, "[test1] has content");

		my ($parse_ok, $is_const, $set) = $ret->{content} =~ /^(isConst: (yes|no)\nset: <(.*)>\n)\z/s;
		is($parse_ok, $ret->{content}, "[test1] valid result");
		is($is_const, "yes", "[test1] isConst = yes");
		like($set, qr/^\Q[error] message: Tripletail::Form#set: This instance is a const object. \E/, "[test1] set is prevented");
	}
}

sub test02_modify
{
	# GET is not affected by TL/maxrequestsize.
	my $ret = t::make_ini::tltest({
		ini => {
			TL => {
				allow_mutable_input_cgi_object => 1,
			},
		},
		method => 'GET',
		param  => {},
		sub => sub{
			our $TL;
			$TL->startCgi(-main=>sub{
				$TL->print("isConst: ".($TL->CGI->isConst?"yes":"no")."\n");
				eval{ $TL->CGI->set(x=>1) };
				my $err = $@;
				chomp $err;
				$TL->print("set: <$err>\n");
			});
		},
	});
	SKIP:{
		ok($ret->is_success, "[test2] fetch") or skip("[test2] fetch failed", 4);
		ok($ret->{content}, "[test2] has content");

		my ($parse_ok, $is_const, $set) = $ret->{content} =~ /^(isConst: (yes|no)\nset: <(.*)>\n)\z/s;
		is($parse_ok, $ret->{content}, "[test2] valid result");
		is($is_const, "no", "[test2] isConst = no");
		like($set, qr/^\z/, "[test2] set is accepted");
	}
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
