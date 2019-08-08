#!/usr/bin/perl
use strict;
use lib 'blib/lib', 'blib/arch';
use feature 'say';
use Benchmark qw/timethis timethese/;
use URI::XS qw/uri encode_uri_component encodeURIComponent decodeURIComponent :const/;
use Data::Dumper qw/Dumper/;
use Storable qw/freeze thaw dclone/;
use JSON::XS;
use URI;
say "START";

use Devel::Peek;

sub tst {
    my $s = shift;
    my $uri = URI::XS->new($s);
    #$uri->query;
}

timethese(-1, {
    short  => sub { URI::XS->new("http://ya.ru/") },
    medium => sub { URI::XS->new("http://ya.ru/my/path?a=b&c=d#jjj") },
    long   => sub { URI::XS->new("http://jopa.dev.crazypanda.ru/my/very/long/path?param1=val1&params2=val2&param3=val3&param4=val4#myverybigfuckinghash") },
});

exit;

my $u = URI::XS->new("http://ya.ru/path?a=b&c=d#jjj");
my $uu = URI->new("http://ya.ru/path?a=b&c=d#jjj");
my $us = URI::XS::http->new("http://jopa.ru");

my $qn = {};
my $qs = {a => "1", b => "2"};
my $qm = {a => "1", b => "2", c => "3", d => "4", abcd => 'dsfdsf'};
my $qb = {map {$_ => "$_"} 1..100};
my $qa = {a => [1,2,3,4]};

timethese(-1, {
    objret_common => sub { URI::XS::ttt($u); },
    objret_strict => sub { URI::XS::ttt($us); },
});
exit();

while (1) {
    my $uri = uri("http://ya.ru");
}

my $uri = uri("http://ya.ru/path?a=b&c=d#jjj");
my $f = freeze($uri);
my $c = thaw($f);


say "END";
