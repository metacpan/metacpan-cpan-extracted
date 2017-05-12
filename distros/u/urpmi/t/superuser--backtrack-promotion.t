#!/usr/bin/perl
#
# testcase for bug #52105
#
# a.x86_64 provides b
# a.i586 does not provide b
# c conflicts with b
# d requires a
#
# user has a.x86_64, d installed
# trying to install c has to remove a, d
#
# Original problem:
# urpmi tries to promote a.i586 for d, but strict-arch does not allow it;
# backtracking finds a.i586 as well and tries it again; it still does not
# work, but urpmi already forgot the promotion and does not remove d
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'backtrack-promotion';
urpmi_addmedia("$name $::pwd/media/$name");

urpmi("--auto --ignorearch a-1-1.x86_64 d");
check_installed_fullnames("a-1-1", "d-1-1");
urpmi("--auto --ignorearch --strict-arch c");
check_installed_fullnames("c-1-1");

