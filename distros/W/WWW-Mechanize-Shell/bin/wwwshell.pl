#!/usr/bin/perl -w
use strict;
use WWW::Mechanize::Shell;

my $shell = WWW::Mechanize::Shell->new("shell");

if (@ARGV) {
  $shell->source_file( @ARGV );
} else {
  $shell->cmdloop;
};
