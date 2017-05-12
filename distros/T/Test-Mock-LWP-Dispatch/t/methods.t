#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Mock::LWP::Dispatch ();

my $ua = LWP::UserAgent->new;
can_ok($ua, qw(map unmap unmap_all get));
isa_ok($ua, 'LWP::UserAgent', 'check that we mocked LWP::UserAgent');

