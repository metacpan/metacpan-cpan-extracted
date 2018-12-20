#!/usr/bin/perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile ();

Internals::SvREADONLY( $], 0 );

$] = '5.006002';
is( Test::MockFile::_goto_is_available(), 0, "goto isn't available on $]" );

$] = '5.008008';
is( Test::MockFile::_goto_is_available(), 0, "goto isn't available on $]" );

$] = '5.016000';
is( Test::MockFile::_goto_is_available(), 1, "goto was first available on $]" );

$] = '5.018000';
is( Test::MockFile::_goto_is_available(), 1, "goto was available on $]" );

$] = '5.020000';
is( Test::MockFile::_goto_is_available(), 1, "goto was available on $]" );

$] = '5.022001';
is( Test::MockFile::_goto_is_available(), 0, "goto was broken on $] (7bdb4ff0943cf93297712faf504cdd425426e57f)" );

$] = '5.024000';
is( Test::MockFile::_goto_is_available(), 0, "goto was broken on $] (7bdb4ff0943cf93297712faf504cdd425426e57f)" );

$] = '5.026000';
is( Test::MockFile::_goto_is_available(), 0, "goto was broken on $] (7bdb4ff0943cf93297712faf504cdd425426e57f)" );

$] = '5.028000';
is( Test::MockFile::_goto_is_available(), 1, "goto works again for $]" );

$] = '5.030000';
is( Test::MockFile::_goto_is_available(), 1, "goto works on $]" );

done_testing();
exit;
