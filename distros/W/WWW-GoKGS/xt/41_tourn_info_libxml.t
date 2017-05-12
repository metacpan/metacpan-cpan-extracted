use strict;
use warnings;
use Test::More;

eval 'use HTML::TreeBuilder::LibXML';
plan skip_all => 'HTML::TreeBuilder::LibXML is required' if $@;

plan skip_all => "TODO: 'description' mismatch, while they are semantically equivalent";
$ENV{WWW_GOKGS_LIBXML} = 1;
do 'xt/40_tourn_info.t';
