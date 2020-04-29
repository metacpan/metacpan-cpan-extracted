#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Config;
use Test::More;

if ($Config{archname} =~ /bsd/) {
    plan skip_all => "we cannot build rpm-query-in-scriptlet on FreeBSD due to cpio failure";
} else {
    plan 'no_plan';
}


my $name = 'rpm-query-in-scriptlet';

need_root_and_prepare();
system_('mkdir -p root/var/lib/rpm');
test_rpm_query_in_scriptlet();
done_testing();

sub test_rpm_query_in_scriptlet {
    system_("rpm --root $::pwd/root -i media/$name/$name*.rpm --nodeps");
    check_installed_names($name);
    rebuilddb();
    check_installed_names($name);
}

sub rebuilddb {
    # testing rebuilddb (could be done elsewhere, but here is 
    system_("rpm --root $::pwd/root --rebuilddb");
    my @dirs = glob("$::pwd/root/var/lib/rpmrebuilddb*");
    is($dirs[0], undef, "@dirs should not be there");
}
