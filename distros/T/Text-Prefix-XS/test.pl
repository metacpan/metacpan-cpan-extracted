#!/usr/bin/perl
#This is really just a wrapper for perlall, so i can set TEXT_XS_BENCH in
#the environment
#
if($ENV{TEXT_XS_BENCH}) {
    require 'trie.pl';
}

exit(0);
