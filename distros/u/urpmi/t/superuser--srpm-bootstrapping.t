#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'srpm-bootstrapping';

urpmi_addmedia("$name $::pwd/media/$name");
test("media/SRPMS-$name/$name-*.src.rpm");

urpmi_addmedia("$name-src $::pwd/media/SRPMS-$name");
test("--buildrequires $name");

sub test {
    my ($para) = @_;

    urpmi("--buildrequires --auto $para");
    check_installed_names($name); # check the buildrequires is installed
    #is(run_urpm_cmd('urpmq --auto-orphans'),''); # test for bug #52169

    install_src_rpm($para);
    check_installed_and_remove($name);
}

sub install_src_rpm {
    my ($para) = @_;
    
    system_('mkdir -p root/root/rpmbuild/SOURCES');

    $ENV{HOME} = '/root';
    urpmi("--install-src $para");

    system_("cmp root/root/rpmbuild/SPECS/$name.spec data/SPECS/$name.spec");
    system_('rm -rf root/usr/src/rpm');
}
