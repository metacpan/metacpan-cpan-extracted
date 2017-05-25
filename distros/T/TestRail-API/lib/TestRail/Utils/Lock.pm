# ABSTRACT: Pick high priority cases for execution and lock them via the test results mechanism.
# PODNAME: TestRail::Utils::Lock

package TestRail::Utils::Lock;
$TestRail::Utils::Lock::VERSION = '0.040';
use 5.010;

use strict;
use warnings;

use Carp qw{confess cluck};
use Scalar::Util qw{blessed};

use Types::Standard
  qw( slurpy ClassName Object Str Int Bool HashRef ArrayRef Maybe Optional);
use Type::Params qw( compile );

use TestRail::API;
use TestRail::Utils;
use TestRail::Utils::Find;

sub pickAndLockTest {
    state $check = compile( HashRef, Optional [ Maybe [Object] ] );
    my ( $opts, $tr ) = $check->(@_);
    confess("TestRail handle must be provided as argument 2")
      unless blessed($tr) eq 'TestRail::API';

    my ( $project, $plan, $run ) =
      TestRail::Utils::getRunInformation( $tr, $opts );

    my $status_ids;

    # Process statuses
    @$status_ids =
      $tr->statusNamesToIds( $opts->{'lockname'}, 'untested', 'retest' );
    my ( $lock_status_id, $untested_id, $retest_id ) = @$status_ids;

    my $cases = $tr->getTests( $run->{'id'} );

    #Filter by case types
    if ( $opts->{'case-types'} ) {
        my @case_types =
          map { my $cdef = $tr->getCaseTypeByName($_); $cdef->{'id'} }
          @{ $opts->{'case-types'} };
        @$cases = grep {
            my $case_type_id = $_->{'type_id'};
            grep { $_ eq $case_type_id } @case_types
        } @$cases;
    }

    # Limit to only non-locked and open cases
    @$cases = grep {
        my $tstatus = $_->{'status_id'};
        scalar( grep { $tstatus eq $_ } ( $untested_id, $retest_id ) )
    } @$cases;
    @$cases = sort { $b->{'priority_id'} <=> $a->{'priority_id'} }
      @$cases;    #Sort by priority DESC

    # Filter by match options
    @$cases = TestRail::Utils::Find::findTests( $opts, @$cases );

    my ( $title, $test );
    while (@$cases) {
        $test = shift @$cases;
        $title = lockTest( $test, $lock_status_id, $opts->{'hostname'}, $tr );
        last if $title;
    }

    if ( !$title ) {
        warn
          "Failed to lock case!  This probably means you don't have any cases left to lock.";
        return 0;
    }

    return {
        'test'    => $test,
        'path'    => $title,
        'project' => $project,
        'plan'    => $plan,
        'run'     => $run
    };
}

sub lockTest {
    state $check = compile( HashRef, Int, Str, Object );
    my ( $test, $lock_status_id, $hostname, $handle ) = $check->(@_);

    my $res = $handle->createTestResults(
        $test->{id},
        $lock_status_id,
        "Test Locked by $hostname.\n
        If this result is preceded immediately by another lock statement like this, please disregard it;
        a lock collision occurred."
    );

    #If we've got more than 100 lock conflicts, we have big-time problems
    my $results = $handle->getTestResults( $test->{id}, 100 );

    #Remember, we're returned results from newest to oldest...
    my $next_one = 0;
    foreach my $result (@$results) {
        unless ( $result->{'status_id'} == $lock_status_id ) {

            #Clearly no lock conflict going on here if next_one is true
            last if $next_one;

            #Otherwise just skip it until we get to the test we locked
            next;
        }

        if ( $result->{id} == $res->{'id'} ) {
            $next_one = 1;
            next;
        }

        if ($next_one) {

            #If we got this far, a lock conflict occurred. Try the next one.
            warn "Lock conflict detected.  Try again...\n";
            return 0;
        }
    }

    #Prefer full titles (match mode)
    return defined( $test->{'full_title'} )
      ? $test->{'full_title'}
      : $test->{'title'}
      if $next_one;
    return -1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TestRail::Utils::Lock - Pick high priority cases for execution and lock them via the test results mechanism.

=head1 VERSION

version 0.040

=head1 DESCRIPTION

Lock a test case via usage of the test result field.
Has a hard limit of looking for 250 results, which is the only weakness of this locking approach.
If you have other test runners that result in such tremendous numbers of lock collisions,
it will result in 'hard-locked' cases, where manual intervention will be required to free the case.

However in that case, one would assume you could afford to write a reaper script to detect and
correct this condition, or consider altering your run strategy to reduce the probability of lock collisions.

=head2 pickAndLockTest(options,[handle])

Pick and lock a test case in a TestRail Run, and return it if successful, confess() on failure.

testrail-lock's primary routine.

=over 4

=item HASHREF C<OPTIONS> - valid keys/values correspond to the long names of arguments taken by L<testrail-lock>.

=item TestRail::API C<HANDLE> - Instance of TestRail::API, in the case where the caller already has a valid object.

There is a special key, 'mock' in the HASHREF that is used for testing.
The 'hostname' key must also be passed in the options, as it is required by lockTest, which this calls.

Returns a HASHREF with the test, project, run and plan (if any) definition HASHREFs as keys.
Also, a 'path' key will be set which has the full path to the test on disk, if match mode is passed, the case title otherwise.

If the test could not be locked, 0 is returned.

=back

=head2 lockTest(test,lock_status_id,handle)

Lock the specified test, and return it's title (or full_title if it exists).

=over 4

=item HASHREF C<TEST> - Test object returned by getTests, or a similar method.

=item INTEGER C<LOCK_STATUS_ID> - Status used to denote locking of test

=item TestRail::API C<HANDLE> - Instance of TestRail::API

=back

Returns -1 in the event a lock could not occur, and warns & returns 0 on lock collisions.

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
