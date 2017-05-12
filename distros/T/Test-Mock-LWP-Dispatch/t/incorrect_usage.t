#!perl
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use Test::Mock::LWP::Dispatch ();
use HTTP::Response;

my $ua = LWP::UserAgent->new;
dies_ok { $ua->map } 'no params';
dies_ok { $ua->map('a') } 'one param';

my $resp = HTTP::Response->new(200);

dies_ok { $ua->map(undef, $resp) } 'only second param';
dies_ok { $ua->map([], $resp) } 'improper type of first param';
dies_ok { $ua->map('a', []) } 'improper type of second param';

