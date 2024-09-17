#!perl -w

use strict;
use Test::More;
use Test::Vars;
use File::Spec::Functions qw( catfile );

my $file;

$file = catfile( qw( lib Test Vars.pm ) );
vars_ok($file);
vars_ok('Test::Vars');
vars_ok($file, ignore_vars => { '$self' => 1 });

done_testing;
