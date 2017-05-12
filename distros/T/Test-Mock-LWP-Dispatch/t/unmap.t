#!perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Mock::LWP::Dispatch ();

my $ua = LWP::UserAgent->new;
my $index1 = $ua->map('http://a.ru', HTTP::Response->new(200));
my $index2 = $ua->map('http://b.ru', HTTP::Response->new(201));

is($ua->get('http://a.ru')->code, 200, 'before unmap');
is($ua->get('http://b.ru')->code, 201, 'before unmap');

$ua->unmap($index1);
is($ua->get('http://a.ru')->code, 404, 'unmap one mapping');
is($ua->get('http://b.ru')->code, 201, 'unmap one mapping');

$ua->unmap_all;
is($ua->get('http://a.ru')->code, 404, 'unmap all');
is($ua->get('http://b.ru')->code, 404, 'unmap all');

