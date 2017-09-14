#!perl
use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More tests => 4;

use URL::Search qw($URL_SEARCH_RE extract_urls partition_urls);

my @results = (
    [TEXT => 'Check out '],
    [URL => 'http://example.com/1'],
    [TEXT => ', '],
    [URL => 'https://example.com?page[id]=2'],
    [TEXT => ", and\n"],
    [URL => 'http://127.1:8080/cgi-bin/render.dll?index#query'],
    [TEXT => '. More: '],
    [URL => 'ftp://host/dir/file.tar.gz'],
    [TEXT => ".\nClick here"],
    [URL => 'http://A4.paper'],
    [TEXT => "\n("],
    [URL => 'Http://user@site/?a=b&c=d;e=f'],
    [TEXT => ' and '],
    [URL => 'http://en.wikipedia.org/wiki/Mayonnaise_(instrument)'],
    [TEXT => ")\n<"],
    [URL => 'https://a.#b'],
    [TEXT => '> ('],
    [URL => 'http://c/d'],
    [TEXT => ') ['],
    [URL => 'http://[::1]/sweet-home'],
    [TEXT => "]\n"],
    [URL => 'http://déjà-vu/€?utf8=✓'],
    [TEXT => ' - '],
    [URL => 'https://en.wikipedia.org/wiki/Hornbostel–Sachs'],
    [TEXT => ' '],
    [URL => 'http://موقع.وزارة-الأتصالات.مصر/最近更改'],
    [TEXT => "\netc."],
    [URL => 'http://поддомен.example.com/déjà-vu?utf8=✓'],
    [TEXT => "\n"],
    [URL => 'https://grep.metacpan.org/search?size=20&q=map\s*\{\s*\%24_\s*\}&qd=&qft='],
    [TEXT => '   # incidentally'],
);

my $corpus = join '', map $_->[1], @results;

#diag $corpus;

is_deeply [partition_urls $corpus], \@results;

is_deeply [extract_urls $corpus], [map $_->[0] eq 'URL' ? $_->[1] : (), @results];

ok $corpus =~ /$URL_SEARCH_RE/;

is substr($corpus, $-[0], $+[0] - $-[0]), $results[1][1];
