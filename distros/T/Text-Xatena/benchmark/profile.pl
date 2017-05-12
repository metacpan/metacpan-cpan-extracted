#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Benchmark qw(:all) ;

my $text = <<EOS;
* This is a head

foobar

barbaz

:foo:bar
:foo:bar

- list1
- list1
- list1

+ list1
+ list1
+ list1

>|perl|
test code
||<

ok?

>||
<!--
test
-->
||<

<!--

>||
test
||<

-->

>>
foobar
<<

EOS

use Text::Xatena;
BEGIN { $ENV{NYTPROF} = 'start=no:file=nytprof.out' }
use Devel::NYTProf;


DB::enable_profile;
for (1..1000) {
	my $thx = Text::Xatena->new;
	my $html = $thx->format($text);
}
DB::finish_profile;

system('nytprofhtml');
system('open nytprof/index.html');

