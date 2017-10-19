#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';
BEGIN { use_ok 'urpm::cfg' }

need_root_and_prepare();

urpmi_addmedia('--mirrorlist http://192.168.0.10/mageia/stable/x86_64 core media/core/release');
is(run_urpm_cmd('urpmq sed'), "sed\n");
urpmi_removemedia('core');

urpmi_addmedia('--distrib --mirrorlist http://192.168.0.10/mageia/stable/x86_64');
is(run_urpm_cmd('urpmq sed'), "sed\n");
urpmi_removemedia('-a');
