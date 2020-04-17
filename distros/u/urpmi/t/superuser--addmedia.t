#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';
BEGIN { use_ok 'urpm::cfg' }

need_root_and_prepare();

my $name = 'various';
my $name2 = 'various2';
my $name3 = 'various3';
my @names = ($name, $name2, $name3, 'debug');

my @fields = qw(hdlist synthesis with_synthesis media_info_dir no-media-info list virtual ignore);

test_reconfig();

try_medium({}, '');


try_medium_({ 'no-media-info' => 1 }, { 'no-media-info' => 1 }, 
	    '--probe-rpms', '--probe-rpms');


try_medium({},
	   '--probe-hdlist');
try_medium({},
	   'with media_info/hdlist.cz');
try_medium({ 
	     with_synthesis => "../media_info/synthesis.hdlist_$name.cz",
	     with_synthesis2 => "../media_info/synthesis.hdlist_$name2.cz" },
	   "with ../media_info/hdlist_$name.cz",
	   "with ../media_info/hdlist_$name2.cz",
       );

try_medium({},
	   '--probe-synthesis');
try_medium({},
	   'with media_info/synthesis.hdlist.cz');
try_medium({ 
	     with_synthesis => "../media_info/synthesis.hdlist_$name.cz",
	     with_synthesis2 => "../media_info/synthesis.hdlist_$name2.cz" },
	   "with ../media_info/synthesis.hdlist_$name.cz",
	   "with ../media_info/synthesis.hdlist_$name2.cz");

try_distrib({}, '');
try_distrib({}, 
	    '--probe-hdlist');
try_distrib({},
	    '--probe-synthesis');
try_distrib_removable({}, '');
try_distrib_removable({}, '--probe-hdlist');
try_distrib_removable({}, '--probe-synthesis');

try_use_distrib();

sub try_medium {
    my ($want, $options, $o_options2) = @_;
    my $want2 = { %$want, with_synthesis => $want->{with_synthesis2} || $want->{with_synthesis} };

    try_medium_($want, $want2, $options, ($o_options2 || $options));

    $want2->{virtual} = $want->{virtual} = 1;
    try_medium_($want, $want2, '--virtual ' . $options, '--virtual ' . ($o_options2 || $options));
}

sub try_distrib {
    my ($want, $options) = @_;
    my $want3 = { %$want, ignore => 1 };

    try_distrib_($want, $want3, $options);

    $want3->{virtual} = $want->{virtual} = 1;
    try_distrib_($want, $want3, '--virtual ' . $options);
}

sub try_distrib_removable {
    my ($want, $options) = @_;

    my @want_list = map {
	{ %$want, with_synthesis => "../..//media/media_info/synthesis.hdlist_$_.cz" };
    } @names;
    $want_list[2]{ignore} = 1;
    $want_list[3]{ignore} = 1;

    try_distrib_removable_(\@want_list, $options);

    $_->{virtual} = 1 foreach @want_list;
    try_distrib_removable_(\@want_list, '--virtual ' . $options);
}

sub try_medium_ {
    my ($want, $want2, $options, $options2) = @_;

    urpmi_addmedia("$name $::pwd/media/$name $options");
    check_conf($want);
    check_urpmi($name);
    {
	urpmi_addmedia("$name2 $::pwd/media/$name2 $options2");
	check_conf($want, $want2);
	check_urpmi($name, $name2);
	urpmi_removemedia($name2);
    }
    urpmi_removemedia($name);
}

sub try_distrib_ {
    my ($want, $want3, $options) = @_;

    urpmi_addmedia("--distrib $name $::pwd $options");
    check_conf($want, $want, $want3, $want3);
    check_urpmi($name, $name2);
    urpmi_removemedia('-a');
}

sub try_use_distrib {
    urpmi("--use-distrib $::pwd $name $name2");
    check_installed_and_remove($name, $name2);
}

sub try_distrib_removable_ {
    my ($want_list, $options) = @_;

    urpmi_addmedia("--distrib $name $::pwd $options --use-copied-hdlist");
    check_conf(@$want_list);
    check_urpmi($name, $name2);
    urpmi_removemedia('-a');
}

sub check_conf {
    my (@want) = @_;
    my $config = urpm::cfg::load_config("root/etc/urpmi/urpmi.cfg");
    is(int(@{$config->{media}}), int(@want), 'have wanted number');
    foreach my $i (0 .. $#want) {
	my ($medium, $want) = ($config->{media}[$i], $want[$i]);
	foreach my $field (@fields) {
	    is($medium->{$field}, $want->{$field}, $field);
	}
    }
}
sub check_urpmi {
    my (@names) = @_;
    urpmi(join(' ', @names));
    check_installed_and_remove(@names);
}

sub test_reconfig {
    urpmi_addmedia("reconfig $::pwd/media/reconfig");
    check_conf({ name => 'reconfig', url => "$::pwd/media/$name" });
    check_urpmi($name);
    urpmi_removemedia('-a');   
}
