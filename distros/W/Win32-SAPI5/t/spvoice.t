#!/usr/bin/perl -w
use Win32::SAPI5;
use Test::More tests => 1;

my $s = Win32::SAPI5::SpVoice->new();
warn "You don't seem to have installed the Microsoft Speech API 5 runtime, therefore this test failed" unless defined $s;
isa_ok ($s, 'Win32::SAPI5::SpVoice');
