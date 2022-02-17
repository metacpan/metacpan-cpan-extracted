#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Tools::Exception qw< lives >;
use Test2::Plugin::NoWarnings;
use Test::MockFile;
use IO::Handle;

my $handle = IO::Handle->new();
isa_ok( $handle, 'IO::Handle' );

my $file = Test::MockFile->file( '/foo', '' );
$! = 0;
ok( open( $handle, '<', '/foo' ), 'Succesfully opened file' );
is( "$!",   '', 'No error (string)' );
is( $! + 0, 0,  'No error (code)' );

isa_ok( $handle, 'IO::File' );

$! = 0;
ok( close($handle), 'Successfully closed handle' );
is( "$!",   '', 'No error (string)' );
is( $! + 0, 0,  'No error (code)' );

done_testing();
exit;
