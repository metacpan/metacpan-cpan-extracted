# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl YVDHOVE-String.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('YVDHOVE::String', qw(:all)) };

#########################

my $string = "  \t  Hello world!   ";

my $result01 = ltrim($string);
my $result02 = rtrim($string);
my $result03 = trim($string);

is($result01, "Hello world!   ", 'ltrim()');
is($result02, "  \t  Hello world!", 'rtrim()');
is($result03, "Hello world!", 'trim()');
