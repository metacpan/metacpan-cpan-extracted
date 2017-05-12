#!/usr/bin/perl

use WWW::TinySong;
use Data::Dumper;

print Dumper(WWW::TinySong->scrape("we can work it out", 3));
