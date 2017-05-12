#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib', 't';
#use TestTools;

use XML::Compile::Dumper;

use Test::More tests => 7;

my $testfile = 't/dump.pm';
my $package  = 't::dump';

unlink $testfile;

my $save = XML::Compile::Dumper->new
 ( filename => $testfile
 , package  => $package
 );

my $x = 'earth';
$save->freeze
 ( aap  => sub {42}    # simple
 , noot => sub {$x}    # closure
 );

$save->close;
ok(-f $testfile, 'dumpfile created');
cmp_ok(-s $testfile, '>', 290, 'some contents found');

eval "require $package";
is("$@", '', 'no parse errors');

$package->import;
{
   no strict 'refs';
   ok(defined *{"main::aap" }{CODE}, 'found aap');
   ok(defined *{"main::noot"}{CODE}, 'found noot');
}

cmp_ok(aap(),  "==",  42,      'call aap' );
cmp_ok(noot(), "cmp", 'world', 'call noot');

unlink $testfile;
