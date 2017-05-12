#!/usr/bin/perl
#
# testcase for bug #50666
#
# a-1
# a-2
# b-1 requires c
# b-2 requires c
# c-1 requires a-1
# c-2 requires d
# d does not exist
#
# user has a-1, b-1, c-1 installed
# trying to upgrade a has to remove b, c
#
#
# testcase for bug #57224
#
# a-1
# a-2
# e-1 requires f
# e-2 requires f
# f1.x86_64 provides f, requires a-1
# f1.i586 provides f
# f2 provides f, conflicts a-2
#
# user has a-1, e-1, f1.x86_64 installed
# trying to upgrade a and e ( = auto-select) has to remove e, f1
# the additional f1.i586 and f2 should not confuse urpmi
# 
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'failing-promotion';
urpmi_addmedia("$name $::pwd/media/$name");

# bug #50666
urpmi("--auto a-1 c-1 b-1");
check_installed_fullnames("a-1-1", "c-1-1", "b-1-1");
urpmi_partial("--auto a");
check_installed_fullnames_and_remove("a-2-1");

# bug #57224
urpmi("--auto --ignorearch a-1 e-1 f1-1-1.x86_64");
check_installed_fullnames("a-1-1", "e-1-1", "f1-1-1");
# disabled until fixed
#urpmi("--auto --ignorearch --strict-arch --auto-select");
#check_installed_fullnames_and_remove("a-2-1");

