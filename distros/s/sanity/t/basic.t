#!/usr/bin/perl
use Test::More tests => 14;

BEGIN {
   use_ok('sanity');
   use_ok('sanity', $_) for (qw(strict warnings feature ex::caution NO:crap latest sane common::sense sanity));
   use_ok('sanity', '-namespace::clean');
   use_ok('sanity', 'Modern::Perl', '-IO::Handle');
   
   isnt(${^WARNING_BITS}, 0, '^WARNING_BITS check');
   isnt($^H,              0, '^H check');
}
