#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';


set_path();
need_root_and_prepare();
various();
urpmq_various();
urpmi_force_skip_unknown();
rpm_v3();

sub various {
    my $name = 'various';
    foreach my $medium_name ('various', 'various_nohdlist', 'various nohdlist', 'various_no_subdir') {
	urpmi_addmedia("'$medium_name' '$::pwd/media/$medium_name'");
	urpmi($name);
	check_installed_fullnames("$name-1-1");
	urpme($name);
	urpmi_removemedia("'$medium_name'");
    }
}

sub urpmq_various {
    foreach my $medium_name ('various', 'various2', 'various3') {
	urpmi_addmedia("'$medium_name' '$::pwd/media/$medium_name'");
    }
    is(run_urpm_cmd('urpmq --fuzzy v'), "various\nvarious2\nvarious3\n");

    is(run_urpm_cmd('urpmq --list'), "various\nvarious2\nvarious3\n");

    urpmi_removemedia('-a');    
}

sub urpmi_force_skip_unknown {
    my $name = 'various';
    urpmi_addmedia("$name $::pwd/media/$name");

    urpmi($name);
    check_installed_and_remove($name);

    test_urpmi_fail("$name unknown-pkg");

    urpmi("--force $name unknown-pkg");
    check_installed_and_remove($name);

    urpmi_removemedia($name);    
}

sub rpm_v3 {
    my @names = qw(libtermcap nls p2c);

    require urpm::select;
    my $noverify_opt = urpm::select::_rpm_version() ge 4.14.2 ? '--noverify' : '';
    system_("rpm $noverify_opt --root $::pwd/root -i --ignorearch --noscripts media/rpm-v3/*.i386.rpm");
    check_installed_names(@names);

    foreach ('/lib/libtermcap.so.2.0.8', '/usr/lib/libp2c.so.1.2.0', '/usr/X11R6/lib/X11/nls/C') {
	ok(-e "root$_", "root$_ should exist");
	ok(-s "root$_", "root$_ should not be empty");
    }

    system_("rpm --root $::pwd/root -e --noscripts " . join(' ', @names));
    is(`rpm -qa --root $::pwd/root`, '');    

    foreach my $medium_name ('rpm-v3', 'rpm-v3_nohdlist', 'rpm-v3_no_subdir') {
	urpmi_addmedia("$medium_name $::pwd/media/$medium_name");
	urpmi('--no-verify-rpm --noscripts ' . join(' ', @names));
	check_installed_names(@names);
	urpme('-a --auto --noscripts');
	is(`rpm -qa --root $::pwd/root`, '');    
	urpmi_removemedia($medium_name);
    }

    foreach my $src_rpm (glob('media/rpm-v3/*.rpm')) {
	my ($wanted_arch) = $src_rpm =~ /(\w+)\.rpm$/;
	chomp(my $fullname = run_urpm_cmd("urpmq -f $src_rpm"));
	my ($arch) = $fullname =~ /(\w+)$/;

	is($arch, $wanted_arch, "$fullname should have arch $wanted_arch (found $arch)");
    }
}
