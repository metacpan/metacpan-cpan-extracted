#!/usr/bin/perl

use WWW::TinySong qw(search);
use Data::Dumper;

print Dumper search("three little birds", 3);
