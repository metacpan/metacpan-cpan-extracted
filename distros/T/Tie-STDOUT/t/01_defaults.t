#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Config;
use File::Temp;

local $/ = undef;
my $tempfile = File::Temp::tempnam('.', 'tie-stdout-test-');
my $preamble = $Config{perlpath}." -Ilib -e \"";
my $postamble = "\" >$tempfile";

system($preamble.q{ use Tie::STDOUT; print qq{foo\n}; print qq{bar\n}; printf qq{%s %d\n}, qq{foo}, 20; syswrite STDOUT, qq{gibberish}, 5, 2; }.$postamble);

open(FILE, $tempfile);
ok(<FILE> eq "foo\nbar\nfoo 20\nbberi", "defaults work OK");
unlink($tempfile);
