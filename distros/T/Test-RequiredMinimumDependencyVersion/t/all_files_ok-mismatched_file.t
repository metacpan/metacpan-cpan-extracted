#!perl

use 5.006;
use strict;
use warnings;

use Test::MockModule;
use Test::More 0.88;

use Test::RequiredMinimumDependencyVersion;

use constant CLASS => 'Test::RequiredMinimumDependencyVersion';

{
    chdir 'corpus/dist3' or die "chdir failed: $!";

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my @file_ok_args;
    my $tpl = Test::MockModule->new( CLASS() );
    $tpl->mock( 'file_ok', sub { my $self = shift; push @file_ok_args, [@_]; return; } );

    my $obj = CLASS()->new( module => { 'Local::XYZ' => '0.002' } );
    is( $obj->all_files_ok(), undef, 'all_files_ok returned undef' );
    is( $done_testing,        1,     '... done_testing was called once' );
    is( $skip_all,            0,     '... skip_all was never called' );
    is( scalar @file_ok_args, 1,     'file_ok was called once' );

    is_deeply( [@file_ok_args], [ ['lib/Local/Mismatched.pm'] ], '... with the correct filenames' );

}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
