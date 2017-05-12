#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use IO::All;
use WWW::Lipsum::Chinese;
use Test::More tests => 1;

my $lipsum = WWW::Lipsum::Chinese->new;

my $content = io->catfile('vendor','richyli-com-loremipsum.html')->binmode(":encoding(big5)")->slurp;

$lipsum->_parse($content);
my $text = $lipsum->_to_utf8();

like($text,qr/^上雖原體流金名不影去表/);

