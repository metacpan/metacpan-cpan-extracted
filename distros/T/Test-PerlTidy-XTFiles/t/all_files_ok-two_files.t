#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::MockModule;
use Test::More 0.88;

use Test::PerlTidy;
use Test::PerlTidy::XTFiles;

use constant CLASS => 'Test::PerlTidy::XTFiles';

chdir 'corpus/dist1' or die "chdir failed:  $!";

{
    my $obj = CLASS()->new( mute => undef );
    isa_ok( $obj, CLASS(), 'new() returns a ' . CLASS() . ' object' );

    my $done_testing = 0;
    my $skip_all     = 0;
    my @tidy_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all',     sub { $skip_all++;     return; } );

    my $tidy = Test::MockModule->new('Test::PerlTidy');
    $tidy->mock( 'is_file_tidy', sub { push @tidy_args, [ $Test::PerlTidy::MUTE, @_ ]; return 1; } );

    test_out('ok 1 - lib/Local/Hello1.pm');
    test_out('ok 2 - lib/Local/Hello2.pm');
    my $rc = $obj->all_files_ok();
    test_test('all_files_ok produces the correct test output');

    is( $rc, 1, '... returned 1' );

    is( $done_testing,     1, '... done_testing was called once' );
    is( $skip_all,         0, '... skip_all was not called' );
    is( scalar @tidy_args, 2, '... is_file_tidy was called twice' );

    is( $tidy_args[0][0],          0,                     'for the first call, MUTE was 0' );
    is( $tidy_args[0][1],          'lib/Local/Hello1.pm', '... correct file name' );
    is( scalar @{ $tidy_args[0] }, 2,                     '... no further argument' );

    is( $tidy_args[1][0],          0,                     'for the second call, MUTE was 0' );
    is( $tidy_args[1][1],          'lib/Local/Hello2.pm', '... correct file name' );
    is( scalar @{ $tidy_args[1] }, 2,                     '... no further argument' );
}

{
    my $obj = CLASS()->new( mute => 'yes, please!', perltidyrc => 'perltidyrc.txt' );
    isa_ok( $obj, CLASS(), 'new() returns a ' . CLASS() . ' object' );

    my $done_testing = 0;
    my $skip_all     = 0;
    my @tidy_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all',     sub { $skip_all++;     return; } );

    my $tidy = Test::MockModule->new('Test::PerlTidy');
    $tidy->mock( 'is_file_tidy', sub { push @tidy_args, [ $Test::PerlTidy::MUTE, @_ ]; return 1; } );

    test_out('ok 1 - lib/Local/Hello1.pm');
    test_out('ok 2 - lib/Local/Hello2.pm');
    my $rc = $obj->all_files_ok();
    test_test('all_files_ok produces the correct test output');

    is( $rc, 1, '... returned 1' );

    is( $done_testing,     1, '... done_testing was called once' );
    is( $skip_all,         0, '... skip_all was not called' );
    is( scalar @tidy_args, 2, '... is_file_tidy was called twice' );

    is( $tidy_args[0][0],          1,                     'for the first call, MUTE was 1' );
    is( $tidy_args[0][1],          'lib/Local/Hello1.pm', '... correct file name' );
    is( $tidy_args[0][2],          'perltidyrc.txt',      '... correct perltidyrc file' );
    is( scalar @{ $tidy_args[0] }, 3,                     '... no further argument' );

    is( $tidy_args[1][0],          1,                     'for the second call, MUTE was 1' );
    is( $tidy_args[1][1],          'lib/Local/Hello2.pm', '... correct file name' );
    is( $tidy_args[1][2],          'perltidyrc.txt',      '... correct perltidyrc file' );
    is( scalar @{ $tidy_args[1] }, 3,                     '... no further argument' );
}

{
    my $obj = CLASS()->new;
    isa_ok( $obj, CLASS(), 'new() returns a ' . CLASS() . ' object' );

    my $done_testing = 0;
    my $skip_all     = 0;
    my @tidy_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all',     sub { $skip_all++;     return; } );

    my $first_call = 1;
    my $tidy       = Test::MockModule->new('Test::PerlTidy');
    $tidy->mock(
        'is_file_tidy',
        sub {
            push @tidy_args, [ $Test::PerlTidy::MUTE, @_ ];
            if ($first_call) {
                $first_call = 0;
                return;
            }
            return 1;
        },
    );

    test_out('not ok 1 - lib/Local/Hello1.pm');
    test_out('ok 2 - lib/Local/Hello2.pm');
    test_fail(+1);
    my $rc = $obj->all_files_ok();
    test_test('all_files_ok produces the correct test output');

    is( $rc, undef, '... returned undef' );

    is( $done_testing,     1, '... done_testing was called once' );
    is( $skip_all,         0, '... skip_all was not called' );
    is( scalar @tidy_args, 2, '... is_file_tidy was called twice' );

    is( $tidy_args[0][0],          0,                     'for the first call, MUTE was 0' );
    is( $tidy_args[0][1],          'lib/Local/Hello1.pm', '... correct file name' );
    is( scalar @{ $tidy_args[0] }, 2,                     '... no further argument' );

    is( $tidy_args[1][0],          0,                     'for the second call, MUTE was 0' );
    is( $tidy_args[1][1],          'lib/Local/Hello2.pm', '... correct file name' );
    is( scalar @{ $tidy_args[1] }, 2,                     '... no further argument' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
