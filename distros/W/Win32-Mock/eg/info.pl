#!/usr/bin/perl
use strict;
use Win32::Mock;
use Win32;

printf "This is Perl $] (build %s) on %s, running on host %s\n", 
    Win32::BuildNumber(), ~~Win32::GetOSName(), Win32::NodeName();
