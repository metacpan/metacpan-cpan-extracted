#!/usr/bin/perl

# (mdvbz#40842)
#
# a-1 provides aa
# a-2 does not provide aa anymore
#
# b conflicts with a < 2
# b requires aa
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'dropped-provides';
urpmi_addmedia("$name $::pwd/media/$name");    

urpmi('a-1');
check_installed_fullnames('a-1-1');

urpmi('--auto b');
check_installed_and_remove('b', 'a', 'aa');
