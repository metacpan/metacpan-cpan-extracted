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
	plan skip_all => "Needs a Mageia specific patch that introduces Time::ZoneInfo->current_zone() as well as a mirrorlist API server";
    }
}

BEGIN { use_ok 'urpm::cfg' }

need_one_valid_mirror();

need_root_and_prepare();

need_downloader();

urpmi_addmedia('--mirrorlist \$MIRRORLIST core media/core/release');
is(run_urpm_cmd('urpmq sed'), "sed\n", "is sed available");
urpmi_removemedia('core');

urpmi_addmedia('--distrib --mirrorlist \$MIRRORLIST');
is(run_urpm_cmd('urpmq sed'), "sed\n", "is sed available");
if ($ENV{AUTHOR_TESTING}) {
    my $name = 'perl-XML-LibXML';
    urpmi("--auto $name");
    is(`rpm -q --qf '%{name}' --root $::pwd/root $name`, $name, "$name is installed");
}
urpmi_removemedia('-a');

sub need_one_valid_mirror() {
    require urpm;
    require urpm::mirrors;
    my @mirrors = urpm::mirrors::_list(urpm->new, urpm::mirrors::_MIRRORLIST());
    if ($#mirrors == 0 && $mirrors[0]->{url} =~ m!mageia.fis.unb.br/distrib/!) {
        warn ">> Only one unusable mirrors\n";
	exit(0);
    }
}
