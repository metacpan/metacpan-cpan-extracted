#!/usr/bin/perl

use strict;
use warnings;

use VCfs;

use Date::Parse qw(str2time);
use Date::Format qw(time2str);

my $t = $ARGV[0];
$t or die;
my $vcs = VCfs->new($t);
print join("\n",
	map({"|$_|"}
		map({time2str('%Y-%m-%d', str2time($_))}
			$vcs->get_log_times($t)
			)
		), '');

