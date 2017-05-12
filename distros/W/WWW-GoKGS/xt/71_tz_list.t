use strict;
use warnings;
use Test::More;

eval 'use HTML::TreeBuilder::LibXML';
plan skip_all => 'HTML::TreeBuilder::LibXML is required' if $@;

$ENV{WWW_GOKGS_LIBXML} = 1;
do 'xt/70_tz_list.t';
