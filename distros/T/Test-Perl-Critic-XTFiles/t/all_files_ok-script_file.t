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

chdir 'corpus/dist3' or die "chdir failed: $!";

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
    $pc->violation('bin/hello');

    $obj->critic( Local::Perl::Critic->new );
    $obj->critic_script($pc);

    test_out('ok 1 - Perl::Critic for "bin/hello"');
    my $rc = $obj->all_files_ok;
    test_test('correct test output');

    is( $rc, 1, 'all_files_ok returned 1' );

    is( $done_testing, 1, '... done_testing was called once' );
    is( $skip_all,     0, '... skip_all was not called' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
