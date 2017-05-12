#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Win32::RunAsAdmin;

plan tests => 2; # OK, this is lame, but seriously - I can't pop up a UAC box during testing! That would be rude!

my $check = Win32::RunAsAdmin::check;
ok ($check == 0 || $check == 1, 'check returns a sane value');

my @TEST = ('hi', 'hi"', 'spaced arg');
is (Win32::RunAsAdmin::escape_args(@TEST), '"hi" "hi\\"" "spaced arg"', 'argument escaping');