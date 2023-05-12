#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

$ms = new_ok('Text::MacroScript');
is $ms->expand("#VSM"), "#VSM";
$ms->define_variable('V', 1); 
$ms->define_script('S', 2); 
$ms->define_macro('M', 3); 
is $ms->expand("#VSM"), "123";

$ms->undefine_variable('V'); 
$ms->undefine_script('S'); 
$ms->undefine_macro('M'); 
is $ms->expand("#VSM"), "#VSM";

$ms->undefine_variable('V'); 
$ms->undefine_script('S'); 
$ms->undefine_macro('M'); 
is $ms->expand("#VSM"), "#VSM";

done_testing;
