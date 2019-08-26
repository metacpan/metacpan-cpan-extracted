#!perl

use 5.006;
use strict;
use warnings;

use Test::Builder::Tester;
use Test::MockModule;
use Test::More 0.88;

use Perl::Critic::Violation;

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Perl::Critic;

use Test::Perl::Critic::XTFiles;

use constant CLASS => 'Test::Perl::Critic::XTFiles';

chdir 'corpus/dist2' or die "chdir failed: $!";

note('successful Perl::Critic');
{

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my $obj = CLASS()->new;

    my $pc = Local::Perl::Critic->new;
    $pc->violation('lib/Local/Hello.pm');

    $obj->critic( Local::Perl::Critic->new );
    $obj->critic_module($pc);

    test_out('ok 1 - Perl::Critic for "lib/Local/Hello.pm"');
    my $rc = $obj->all_files_ok;
    test_test('correct test output');

    is( $rc, 1, 'all_files_ok returned 1' );

    is( $done_testing, 1, '... done_testing was called once' );
    is( $skip_all,     0, '... skip_all was not called' );
}

note('with violation');
{

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my $obj = CLASS()->new;

    my $pc = Local::Perl::Critic->new;
    $pc->violation( 'lib/Local/Hello.pm', 'hello world violation' );

    $obj->critic( Local::Perl::Critic->new );
    $obj->critic_module($pc);

    test_out('not ok 1 - Perl::Critic for "lib/Local/Hello.pm"');
    test_fail(+3);
    test_diag(q{});
    test_diag('  hello world violation');
    my $rc = $obj->all_files_ok;
    test_test('correct test output');

    is( $rc, undef, 'all_files_ok returned undef' );

    is( $done_testing, 1, '... done_testing was called once' );
    is( $skip_all,     0, '... skip_all was not called' );
}

note('with three violations');
{

    Perl::Critic::Violation::set_format(1);
    my $format = Perl::Critic::Violation::get_format;

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my $obj = CLASS()->new;

    my $pc = Local::Perl::Critic->new;
    $pc->violation( 'lib/Local/Hello.pm', 'hello world violation' );
    $pc->violation( 'lib/Local/Hello.pm', 'violation2' );
    $pc->violation( 'lib/Local/Hello.pm', 'the third violation' );

    $pc->config->verbose(5);

    ok( $format eq Perl::Critic::Violation::get_format(), 'violation format is unchanged' );

    $obj->critic( Local::Perl::Critic->new );
    $obj->critic_module($pc);

    test_out('not ok 1 - Perl::Critic for "lib/Local/Hello.pm"');
    test_fail(+5);
    test_diag(q{});
    test_diag('  hello world violation');
    test_diag('  violation2');
    test_diag('  the third violation');
    my $rc = $obj->all_files_ok;
    test_test('correct test output');

    is( $rc, undef, 'all_files_ok returned undef' );

    ok( $format ne Perl::Critic::Violation::get_format(), 'violation format is changed' );

    is( $done_testing, 1, '... done_testing was called once' );
    is( $skip_all,     0, '... skip_all was not called' );
}

note('Perl::Critic throws an exception');
{

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->mock( 'done_testing', sub { $done_testing++; return; } );
    $module->mock( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my $obj = CLASS()->new;

    $obj->critic( Local::Perl::Critic->new );

    test_out('not ok 1 - Perl::Critic for "lib/Local/Hello.pm"');
    test_fail(+4);
    test_diag(q{});
    test_diag('Perl::Critic had errors in "lib/Local/Hello.pm":');
    test_diag("\tFile not found: lib/Local/Hello.pm");
    my $rc = $obj->all_files_ok;
    test_test('correct test output');

    is( $rc, undef, 'all_files_ok returned undef' );

    is( $done_testing, 1, '... done_testing was called once' );
    is( $skip_all,     0, '... skip_all was not called' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
