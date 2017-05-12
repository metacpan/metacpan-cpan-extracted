#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests=> 2;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT; 
class URT::Foo { has => [qw/a b c/]}; 

my @p1a = (-order_by => [qw/b/], -group_by => [qw/b a/]); 
my $bx1 = URT::Foo->define_boolexpr(@p1a);
my @p1b = $bx1->params_list;
is(Data::Dumper::Dumper(\@p1a),Data::Dumper::Dumper(\@p1b), "params list is symmetrical for an expression with two constant values");

my $bx2 = $bx1->normalize;
my @p2a = (-group_by => [qw/b a/], -order_by => [qw/b/]);
my @p2b = $bx2->params_list;
is(Data::Dumper::Dumper(\@p2a),Data::Dumper::Dumper(\@p2b), "params list is symmetrical for an expression with two constant values after normalize");
 


