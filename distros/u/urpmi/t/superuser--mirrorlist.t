#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';
BEGIN { use_ok 'urpm::cfg' }
my @dl_helpers = qw(wget curl prozilla aria2c);
my $found;
foreach (@dl_helpers) {
	-e "/bin/$_" and $found = 1;
}
if (!$found) {
        warn "SKIPing because we're missing a downloader. We need one of wget∕curl/prozilla/aria2c";
	#plan skip_all => "*BSD fails those";
	exit 0;
}


need_root_and_prepare();

urpmi_addmedia('--mirrorlist \$MIRRORLIST core media/core/release');
is(run_urpm_cmd('urpmq sed'), "sed\n");
urpmi_removemedia('core');

urpmi_addmedia('--distrib --mirrorlist \$MIRRORLIST');
is(run_urpm_cmd('urpmq sed'), "sed\n");
urpmi_removemedia('-a');
