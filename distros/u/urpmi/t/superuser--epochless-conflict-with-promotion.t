#!/usr/bin/perl

# a-1 does not have epoch
# a-2 has epoch 1
#
# b conflicts with a <= 2
#
# RPM does not consider this a conflict with a-2, so urpmi should promote it.
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'epochless-conflict-with-promotion';
urpmi_addmedia("$name $::pwd/media/$name");    

urpmi('a-1');
check_installed_fullnames('a-1-1');

urpmi('--auto b');
check_installed_and_remove('a', 'b');
