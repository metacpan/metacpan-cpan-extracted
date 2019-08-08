#!perl

use 5.006;
use strict;
use warnings;

use Test::MockModule;
use Test::More 0.88;

use Test::RequiredMinimumDependencyVersion;

use constant CLASS => 'Test::RequiredMinimumDependencyVersion';

{
    chdir 'corpus/empty' or die "chdir failed: $!";

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my $obj = CLASS()->new( module => { 'Local::XYZ' => '0.001' } );
    is( $obj->all_files_ok,    1, 'all_files_ok returned 1' );
    is( $done_testing,         0, '... done_testing was not called' );
    is( $skip_all,             1, '... skip_all was called once' );
    is( scalar @skip_all_args, 2, '... with the correct number of arguments' );
    isa_ok( $skip_all_args[0], 'Test::Builder', '... a Test::Builder object' );
    is( $skip_all_args[1], "No files found\n", '... and a message' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
