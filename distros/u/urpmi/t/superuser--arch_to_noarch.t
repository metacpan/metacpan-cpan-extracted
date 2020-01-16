#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'arch_to_noarch';

foreach my $nb (1 .. 4) {
    my $medium_name = "${name}_$nb";
    urpmi_addmedia("$medium_name $::pwd/media/$medium_name");
    urpmi("$name");
    check_installed_fullnames("$name-$nb-1");
}
