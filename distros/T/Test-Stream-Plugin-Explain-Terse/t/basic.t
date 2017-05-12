use strict;
use warnings;

use Test::Stream::Plugin::Core qw( can_ok done_testing ok );
use Test::Stream::Plugin::Compare qw( is );
use Test::Stream::Plugin::Explain::Terse qw( explain_terse );

# ABSTRACT: Basic self-test

can_ok( __PACKAGE__, 'explain_terse' );

ok( defined( explain_terse("") ), "explain_terse must return a defined value" );

is( explain_terse("Hello"), '"Hello"', 'short values dump-pass through OK' );

done_testing;

