#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';
BEGIN { use_ok 'urpm::cfg' }

need_root_and_prepare();

try1();
try2();

sub try1 {
    urpmi_addmedia("--distrib $::pwd");
    check_urpmi('various', 'various2');

    urpmi_update('--ignore Various');
    check_conf('Various' => { ignore => 1 });
    test_urpmi_fail('--auto various');

    check_conf('Various Debug' => { ignore => 1 });
    test_urpmi_fail('various-debug');

    urpmi_update('--no-ignore "Various Debug"');
    urpmi_update('"Various Debug"');
    check_conf('Various Debug' => { ignore => undef });
    check_urpmi('various-debug');

    urpmi_removemedia('-a');
}
# same as above, except urpmi.update is done before urpmi.update --no-ignore
sub try2 {
    my ($want, $want3, $options) = @_;

    urpmi_addmedia("--distrib $::pwd");

    urpmi_update('"Various Debug"');
    check_conf('Various Debug' => { ignore => 1 });
    test_urpmi_fail('various-debug');

    urpmi_update('--no-ignore "Various Debug"');
    check_conf('Various Debug' => { ignore => undef });
    check_urpmi('various-debug');

    urpmi_removemedia('-a');
}

sub check_conf {
    my (%want) = @_;
    my $config = urpm::cfg::load_config("root/etc/urpmi/urpmi.cfg");
    my %media = map { $_->{name} => $_ } @{$config->{media}};
    foreach my $name (keys %want) {
	foreach my $field (keys %{$want{$name}}) {
	    my $val = $want{$name}{$field};
	    is($media{$name}{$field}, $want{$name}{$field}, "$name:$field");
	}
    }
}

sub check_urpmi {
    my (@names) = @_;
    urpmi(join(' ', @names));
    check_installed_and_remove(@names);
}
