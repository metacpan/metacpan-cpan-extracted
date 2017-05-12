#!/usr/bin/perl

use strict;
use warnings;
use utf8 ();

use Test::More tests => 2;
use XML::Char;

my $str = "\xC3";
is( XML::Char->valid($str), !!1, "accept U+00C3 with UTF8 flag off" );

utf8::upgrade($str);
is( XML::Char->valid($str), !!1, "accept U+00C3 with UTF8 flag on" );
