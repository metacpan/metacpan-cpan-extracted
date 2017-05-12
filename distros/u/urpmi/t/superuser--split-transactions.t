#!/usr/bin/perl

# packages "a" and "b" require each other, and so must installed in same transaction
# package "c" requires "a" and can be installed later on
# package "d" has no deps and can be installed alone in its transaction, with no particular timing
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'split-transactions';
urpmi_addmedia("$name $::pwd/media/$name");    

test_urpmi("--auto --split-length 1 c d", <<'EOF', <<'EOF');
Preparing...
      1/4: a
      2/4: b
Preparing...
      3/4: c
Preparing...
      4/4: d
EOF
Preparing...
      1/4: b
      2/4: a
Preparing...
      3/4: c
Preparing...
      4/4: d
EOF
check_installed_names('a', 'b', 'c', 'd');

sub test_urpmi {
    my ($para, $wanted_a, $wanted_b) = @_;
    my $s = run_urpm_cmd("urpmi $para");
    print $s;

    $s =~ s/\s*#{40}#*//g;
    $s =~ s/^installing .*//gm;
    $s =~ s/^SECURITY.*//gm;
    $s =~ s/^\n//gm;

    ok($s eq $wanted_a || $s eq $wanted_b, "$wanted_a in $s");
}
