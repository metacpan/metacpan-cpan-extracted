# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-NationalRail.t'

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 15;

BEGIN { use_ok('WWW::NationalRail') };

my $rail;

my $tomorrow = sprintf(
	"%02d/%02d/%02d", sub {($_[3]+1, $_[4]+1, $_[5]%100)}->(localtime)
);

can_ok("WWW::NationalRail", qw(from to via out_date out_type out_hour out_minute
	ret_date ret_type ret_hour ret_minute));
can_ok("WWW::NationalRail", qw(outward_summary return_summary
	outward_detail return_detail error));

# tests against the live system
# one-way
ok ( $rail = WWW::NationalRail->new({
	from		=> 'London',
	to			=> 'Cambridge',
	out_date	=> $tomorrow,
	out_type	=> 'depart',
	out_hour	=> 9,
	out_minute	=> 0,
}), "constuctor");

ok ($rail->search(), "search");

ok ($rail->outward_summary, "outward summary");
is ($rail->return_summary, undef, "return summary");
ok ($rail->outward_detail, "outward detail");
is ($rail->return_detail, undef, "return detail");

# return
ok ( $rail = WWW::NationalRail->new({
	from		=> 'London',
	to			=> 'Cambridge',
	out_date	=> $tomorrow,
	out_type	=> 'depart',
	out_hour	=> 9,
	out_minute	=> 0,
	ret_date	=> $tomorrow,
	ret_type	=> 'depart',
	ret_hour	=> 17,
	ret_minute	=> 0,
}), "constuctor");

ok ($rail->search(), "search");

ok ($rail->outward_summary, "outward summary");
ok ($rail->return_summary, "return summary");
ok ($rail->outward_detail, "outward detail");
ok ($rail->return_detail, "return detail");

# vim:ft=perl
