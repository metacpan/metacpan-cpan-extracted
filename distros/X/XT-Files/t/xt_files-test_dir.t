#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use XT::Files;

delete $ENV{XT_FILES_DEFAULT_CONFIG_FILE};

use constant CLASS => 'XT::Files';

chdir 'corpus/dist1' or die "chdir failed: $!";

is( CLASS()->_is_initialized, undef, 'singleton is not initialized' );

my $obj = CLASS()->new( -config => undef );

is( $obj->bin_dir('bin'),    undef, 'bin_dir returns undef' );
is( $obj->module_dir('lib'), undef, 'module_dir returns undef' );
is( $obj->test_dir('t'),     undef, 'test_dir returns undef' );

my %file = %{ $obj->{_file} };
my @keys = keys %file;

is( scalar @keys, 5, '... now we have 5 files' );
for my $i ( 0 .. $#keys ) {
    my $name = $keys[$i];
    my $file = $file{$name};

    if ( $name =~ m{ ^ bin / }x ) {
        isa_ok( $file, 'XT::Files::File' );
        is( $file->name, $file{$name}, "... with name '$name'" );
        ok( !$file->is_module, 'is_module is false' );
        ok( !$file->is_pod,    'is_pod is false' );
        ok( $file->is_script,  'is_script is true' );
        ok( !$file->is_test,   'is_test is false' );
    }
    elsif ( $name =~ m { ^ lib / .* [.] pm $ }x ) {
        isa_ok( $file, 'XT::Files::File' );
        is( $file->name, $file{$name}, "... with name '$name'" );
        ok( $file->is_module,  'is_module is true' );
        ok( !$file->is_pod,    'is_pod is false' );
        ok( !$file->is_script, 'is_script is false' );
        ok( !$file->is_test,   'is_test is false' );
    }
    elsif ( $name =~ m { ^ lib / .* [.] pod $ }x ) {
        isa_ok( $file, 'XT::Files::File' );
        is( $file->name, $file{$name}, "... with name '$name'" );
        ok( !$file->is_module, 'is_module is false' );
        ok( $file->is_pod,     'is_pod is true' );
        ok( !$file->is_script, 'is_script is false' );
        ok( !$file->is_test,   'is_test is false' );
    }
    elsif ( $name =~ m { ^ t / }x ) {
        isa_ok( $file, 'XT::Files::File' );
        is( $file->name, $file{$name}, "... with name '$name'" );
        ok( !$file->is_module, 'is_module is false' );
        ok( !$file->is_pod,    'is_pod is false' );
        ok( $file->is_script,  'is_script is true' );
        ok( $file->is_test,    'is_test is true' );
    }
    else {
        ok( 0, "unexpected file $file{$name}" );
    }
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
