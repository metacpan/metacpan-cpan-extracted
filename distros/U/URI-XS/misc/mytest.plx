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
use Devel::Peek;

say "START";

die "usage $1 test_name" unless @ARGV;

my $time = (grep { $_ eq '--profile' } @ARGV) ? -100 : -1;
for (@ARGV) {
    say;
    my $sub = main->can($_);
    $sub->();
}

sub parse {
    my $big = "http://jopa.dev.crazypanda.ru/my/very/long/path?param1=val1&params2=val2&param3=val3&param4=val4#myverybigfuckinghash";
    my $mid = "http://www.crazypanda.ru/my/path?a=b";
    my $sml = "http://crazypanda.ru";
    my $enc = "http://y%20a.%20r%20u/a/b?c=d#e=f";
    my $min = "/";
    my $ex1 = 'http://jopa.com?"key"="val"&param={"key","val"}';
    my $ex2 = 'http://jopa.com?key11=val11&param=keyvalkeyval1';
    URI::XS::test_parse($enc);
    
    timethese(-1, {
        big => sub { URI::XS::bench_parse($big) },
        mid => sub { URI::XS::bench_parse($mid) },
        mid_ex => sub { URI::XS::bench_parse($mid, ALLOW_EXTENDED_CHARS) },
        sml => sub { URI::XS::bench_parse($sml) },
        enc => sub { URI::XS::bench_parse($enc) },
        min => sub { URI::XS::bench_parse($min) },
        min_ex => sub { URI::XS::bench_parse($min, ALLOW_EXTENDED_CHARS) },
        ex1 => sub { URI::XS::bench_parse($ex1, ALLOW_EXTENDED_CHARS) },
        ex2 => sub { URI::XS::bench_parse($ex2, ALLOW_EXTENDED_CHARS) },
    });
};

sub parse_query {
    my $big = "asflhdsljfhdsf=dasfjasdjkfhdk&daskjfdsakjfhdkjs=adsfjkhdfkjhdas&dsfdsf=dsfdf&dasfdsf=dfdfgf&fagfg=fdsfd&dsf&df=&=dsfds";
    my $mid = "user=syber&password=1234567890&action=delete&session=asdkjfhdasfhdaskfhdjsfkjdsf";
    my $sml = "a=b&c=d";
    my $min = "a=1";
    my $enc = "user=s%20y%20b%20e%20r&text=%20%21%22%23%34%25%26%27%28%29%30&action=view";
    
    timethese(-1, {
        big => sub { URI::XS::bench_parse_query($big) },
        mid => sub { URI::XS::bench_parse_query($mid) },
        min => sub { URI::XS::bench_parse_query($min) },
        sml => sub { URI::XS::bench_parse_query($sml) },
        enc => sub { URI::XS::bench_parse_query($enc) },
    });
}

sub encdec_uric {
    my $big = "01234567890123456789012345678901234567890123456789%01%02%03%04%05%06%07%08%09%10%11%12%13%14%15%16%17%18%19%20";
    my $sml = "hi%20i%20m%20here";
    say URI::XS::decode_uri_component($big);
    timethese(-1, {
        encbig => sub { URI::XS::bench_encode_uri_component($big) },
        encsml => sub { URI::XS::bench_encode_uri_component($sml) },
        decbig => sub { URI::XS::bench_decode_uri_component($big) },
        decsml => sub { URI::XS::bench_decode_uri_component($sml) },
    });
}

exit;

my $u = URI::XS->new("http://ya.ru/");
my $u2 = URI::XS->new("http://ya.ru/");
my $o = bless {}, 'JSON::XS';
timethis(-1, sub { $u eq $u2});

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
