#!/usr/bin/perl

use warnings;
use strict;

use Devel::Size qw(total_size);
use Tree::Easy;

my $root = Tree::Easy->new;
$root->data('+');

$root->push_new('1');
my $times = $root->push_new('*');

$root->push_new('1');

$times->push_new('2');
my $minus = $times->push_new('-');
$minus->push_new('5');
$minus->push_new('1');

$root->dumper;

my @stuff;
$root->traverse( sub { push @stuff, shift->data } );
my $eq = join( ' ', @stuff );
printf "%s = %s\n", $eq, eval "$eq";

printf "Tree size: %d bytes\n", total_size($root);
