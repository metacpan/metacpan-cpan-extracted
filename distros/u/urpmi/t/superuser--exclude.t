#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';

BEGIN { use_ok 'urpm::cfg' }
BEGIN { use_ok 'urpm::download' }

need_root_and_prepare();

my $name = 'various';

my @want = `rpm -qpl media/$name/$name-1-1.*.rpm`;

urpmi_addmedia("$name $::pwd/media/$name");

set_install_langs_macro('fr');

foreach ([ '', \@want ],
	 [ '--excludedocs', [ grep { !m!^/usr/share/doc! } @want ] ],
	 [ '--excludepath /usr', [ grep { !m!^/usr! } @want ] ],
     ) {
    my ($option, $want) = @$_;

    test_rpm_cmdline($option, 'fr', $want);
    test_urpmi_cmdline($option, $want);
    test_urpmi_through_urpmi_cfg($option, $want);
}

{
    set_install_langs_macro('en');
    my $want = [ grep { !m!^/usr/share/locale/! } @want ];
    test_rpm_cmdline('', 'en', $want);

    test_urpmi_cmdline('', $want);
}

sub set_install_langs_macro {
    my ($langs) = @_;
    mkdir "$::pwd/root/etc/rpm";
    my $macros_file = "$::pwd/root/etc/rpm/macros";
    system("echo \%_install_langs $langs > $macros_file");
    ok(-e $macros_file, "macros file exists");
}

sub test_rpm_cmdline {
    my ($option, $lang, $want) = @_;

    $option = "$option --define='_install_langs $lang'";
    system_("rpm --root $::pwd/root -i $option media/$name/$name-1-1.*.rpm");
    check("rpm -i $option", $want);
    system_("rpm --root $::pwd/root -e $name");
    check('rpm -e', []);
}
sub test_urpmi_cmdline {
    my ($option, $want) = @_;

    urpmi("$option $name");
    check("urpmi $option", $want), "have $want";
    urpme($name);
    check('rpm -e', []);
}
sub test_urpmi_through_urpmi_cfg {
    my ($option, $want) = @_;

    set_urpmi_cfg_global_options(cmdline2hash($option));
    urpmi($name);
    check("urpmi ($option in urpmi.cfg)", $want);
    urpme($name);
    check('rpm -e', []);
    set_urpmi_cfg_global_options({});
}

sub check {
    my ($kind, $want) = @_;
    my @got_all = filter_urpmi_rpm_files(`find root  | sed 's/^root//'`);
    my @got_no_dirs = filter_urpmi_rpm_files(`find root ! -type d | sed 's/^root//'`);
    is(join('', difference2(\@got_no_dirs, $want)), '', "too many files ($kind)");
    is(join('', difference2($want, \@got_all)), '', "missing files ($kind)");
}

sub cmdline2hash {
    my ($option) = @_;
    $option =~ /--(\S+)\s*(\S*)/ ? { $1 => $2 } : {};
}


sub filter_urpmi_rpm_files {
    grep { !m!^(/dev/null|/etc/urpmi|/etc/rpm/macros|/var/(cache|lib)/(urpmi|rpm))! } @_;
}

sub difference2 { my %l; @l{@{$_[1]}} = (); grep { !exists $l{$_} } @{$_[0]} }
