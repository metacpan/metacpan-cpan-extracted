#!perl
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Test::Mock::LWP::Dispatch');
}

isa_ok($mock_ua, 'LWP::UserAgent');

my $ua = new_ok('LWP::UserAgent');
isa_ok($ua, 'LWP::UserAgent');

