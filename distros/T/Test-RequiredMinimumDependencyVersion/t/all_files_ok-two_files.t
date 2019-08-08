#!perl

use 5.006;
use strict;
use warnings;

use Test::MockModule;
use Test::More 0.88;

use Test::RequiredMinimumDependencyVersion;

use constant CLASS => 'Test::RequiredMinimumDependencyVersion';

{
    chdir 'corpus/dist2' or die "chdir failed: $!";

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my @file_ok_args;
    my $tpl = Test::MockModule->new( CLASS() );
    $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return 1; } );

    my $obj = CLASS()->new( module => { 'Local::XYZ' => '0.001' } );
    is( $obj->all_files_ok(), 1, 'all_files_ok returned 1' );
    is( $done_testing,        1, '... done_testing was called once' );
    is( $skip_all,            0, '... skip_all was never called' );
    is( scalar @file_ok_args, 2, 'file_ok was called twice' );
    my @expected = map { [$_] } sort 'lib/Local/Hello_1.pm', 'lib/Local/Hello_2.pm';
    is_deeply( [@file_ok_args], [@expected], '... with the correct filenames' );

}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
