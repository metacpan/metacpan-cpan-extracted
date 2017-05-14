package Test::PerlTidy::Concurrent;

use strict;
use warnings;

use parent 'Exporter';

use vars qw( @EXPORT );
@EXPORT = qw( run_tests );

use Test::Builder;
use Test::PerlTidy qw();

=head1 NAME

Test::PerlTidy::Concurrent - Concurrent L<Test::PerlTidy> test executor.

=head1 SYNOPSIS

    # In a file like 't/perltidy.t':

    use Test::PerlTidy::Concurrent;

    run_tests(j => 9);


=cut

my $test = Test::Builder->new;

sub run_tests {
    my %args = @_;

    my $max_pids = defined($args{j}) ? delete($args{j}) : 5;
    if ($max_pids == 0) {
        Test::PerlTidy::run_tests(%args);
    } else {
        $Test::PerlTidy::MUTE = 1;

        # Skip all tests if instructed to.
        $test->skip_all('All tests skipped.') if $args{skip_all};

        # Get files to work with and set the plan.
        my @files = Test::PerlTidy::list_files(%args);
        $test->plan(tests => scalar @files);

        _execute_in_parallel(
            sub {Test::PerlTidy::is_file_tidy($_[0], $_[1])},
            sub {$test->ok($?, "'$_[0]'")},
            [map {[$_ => $args{perltidyrc}]} @files], $max_pids,
        );
    }

    return;
}

sub _execute_in_parallel {
    my ($sub_body, $sub_end, $argument_set, $max_pids) = @_;

    my %pids;
    foreach my $arguments (@$argument_set) {
        unless (keys(%pids) <= $max_pids) {
            my $pid = waitpid(-1, 0);
            $sub_end->(@{delete($pids{$pid})});
        }

        my $pid = fork();
        if ($pid) {
            $pids{$pid} = $arguments;
        } else {
            exit $sub_body->(@$arguments);
        }
    }

    while ((my $pid = waitpid(-1, 0)) != -1) {
        $sub_end->(@{delete($pids{$pid})});
    }
}

1;

=head1 DESCRIPTION

This module does the same work as L<Test::PerlTidy> but in several threads concurrently.

=head2 Differences in regard to L<Test::PerlTidy>:

=over 2

=item run_tests subroutine I<'j' option is added>.

=item run_tests subroutine I<'mute' option is always TRUE> for j != 0.

=back

=head1 IMPLEMENTATION DETAILS

Uses fork for multisequencing.

=head1 SUBROUTINES

=head2 run_tests ( I<%args> )

    run_tests(
        %arguments_of_Test_PerlTidy_run_test,
        j => 9,
    );

=over 1

=item j

Sets max concurrent worker number for test execution.

=back

See other options in L<Test::PerlTidy>.

=head1 SEE ALSO

L<Test::PerlTidy>

=head1 SOURCES

L<The module at github|https://github.com/wtertius/Test-PerlTidy-Concurrent>

=cut
