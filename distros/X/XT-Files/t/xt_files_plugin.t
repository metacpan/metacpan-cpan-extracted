#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Role::Tiny ();

use XT::Files::Plugin;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files::Plugin';

like( exception { CLASS()->new() }, q{/xtf attribute required/}, q{new throws an exception if 'xtf' argument is missing} );

like( exception { CLASS()->new( xtf => 'hello world' ) }, q{/'xtf' is not of class 'XT::Files'/}, q{new throws an exception if 'xtf' argument is not an XT::Files object} );

my $xtf = bless {}, 'XT::Files';

my $obj = CLASS()->new( xtf => $xtf );
isa_ok( $obj,      CLASS(),     'new returned object' );
isa_ok( $obj->xtf, 'XT::Files', 'xtf return object' );
is( $obj->xtf,    $xtf,    '... the one we passed it' );
is( $obj->{name}, CLASS(), '... name is set to class name' );

$obj = CLASS()->new( xtf => $xtf, name => 'hello world' );
isa_ok( $obj,      CLASS(),     'new returned object' );
isa_ok( $obj->xtf, 'XT::Files', 'xtf return object' );
is( $obj->xtf,    $xtf,          '... the one we passed it' );
is( $obj->{name}, 'hello world', '... name is set to arguent' );

ok( Role::Tiny::does_role( $obj, 'XT::Files::Role::Logger' ), 'does role XT::Files::Role::Logger' );
is( $obj->log_prefix,                        'hello world', 'log_prefix returns the name' );
is( CLASS()->new( xtf => $xtf )->log_prefix, CLASS(),       '... or the class name as backup' );

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
