#!/usr/bin/perl

use strict;
use warnings;
use lib qw(lib);

use WWW::NationalRail;

my $rail;

my $tomorrow = sprintf("%02d/%02d/%02d",
    sub {($_[3]+1, $_[4]+1, $_[5]%100)}->(localtime));

# tests against the live system
# one-way
$rail = WWW::NationalRail->new({
	from		=> 'London',
	to			=> 'Cambridge',
	out_date	=> $tomorrow,
	out_type	=> 'depart',
	out_hour	=> 9,
	out_minute	=> 0,
});

$rail->search();

writefile ("t/data/oneway_summary.html", $rail->{_summary});
writefile ("t/data/oneway_detail.html", $rail->{_detail});

# return
$rail = WWW::NationalRail->new({
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
});

$rail->search();

writefile ("t/data/return_summary.html", $rail->{_summary});
writefile ("t/data/return_detail.html", $rail->{_detail});

sub writefile {
    my ($filename, $content) = @_;
    open FILE, ">", $filename or die "can't open '$filename' for write: $!";
    print FILE $content;
    close FILE;
}
