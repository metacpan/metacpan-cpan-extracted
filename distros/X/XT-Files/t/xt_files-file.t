#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::Fatal;
use Test::More 0.88;

use XT::Files;
use XT::Files::File;

use constant CLASS => 'XT::Files';

note('file');

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->file('hello'), undef, 'file returns undef if the file does not exist' );

$obj->{_file}->{'hello'} = 'world';
is( $obj->file('hello'), 'world', 'file returns the file obj if it does exist' );

is( $obj->file( 'hello', undef ), undef, 'file(name, undef) removes an entry' );
is( $obj->file('hello'), undef, 'file returns undef if the file does not exist' );
ok( exists $obj->{_file}->{'hello'}, q{entry for file 'hello' still exists} );

my $file_obj = XT::Files::File->new( name => 'hello' );

is( $obj->file( 'hello', $file_obj ), $file_obj, 'file(name, obj) inserts an entry' );
isa_ok( $obj->file('hello'), 'XT::Files::File' );

test_out( '# [' . CLASS() . q{] File is not of class 'XT::Files::File'} );
my $exception = exception { $obj->file( 'hello', bless {}, 'Local::Something' ) };
test_test();

like( $exception, qr{File is not of class 'XT::Files::File'}, 'file(name, obj) throws an error if obj is not from class XT::Files::File' );

done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
