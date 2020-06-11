#!/usr/bin/perl -w

##-- dtatw-trim-decode.perl : restore troublesome input extracted by dtatw-trim-encode.perl
use utf8;
use open qw(:std :utf8);
use strict;

##-- guts
while (<>) {
  s{<!--DTATW\.TRIM:(.*?)-->}{$1}g;
  print;
}
