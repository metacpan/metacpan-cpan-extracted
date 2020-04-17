#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More;
# Must be done before 'use urpm::cfg' else we got:
# '1..0 # SKIP Needs a Mageia specific patch that introduces Time::ZoneInfo->current_zone()'
BEGIN {
    if (is_mageia()) {
	plan 'no_plan';
    } else {
	plan skip_all => "Needs a Mageia specific patch that introduces Time::ZoneInfo->current_zone()";
    }
}

BEGIN { use_ok 'urpm::cfg' }

need_root_and_prepare();

need_downloader();

urpmi_addmedia('--mirrorlist \$MIRRORLIST core media/core/release');
is(run_urpm_cmd('urpmq sed'), "sed\n", "is sed available");
urpmi_removemedia('core');

urpmi_addmedia('--distrib --mirrorlist \$MIRRORLIST');
is(run_urpm_cmd('urpmq sed'), "sed\n", "is sed available");
urpmi_removemedia('-a');
