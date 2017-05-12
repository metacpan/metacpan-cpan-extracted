#!perl -T
use strict;
use Test::More;

my @modules = qw(
    Win32::Mock
    Win32
    Win32CORE
    Win32::Console
    Win32::Daemon
    Win32::EventLog
    Win32::File
    Win32::Process
    Win32::Service
);

plan tests => scalar @modules;

for my $module (@modules) {
    use_ok( $module );
}

diag( "Testing Win32::Mock $Win32::Mock::VERSION, Perl $], $^X" );
