# PODNAME: TestRail::Utils::Find
# ABSTRACT: Find runs and tests according to user specifications.

package TestRail::Utils::Find;
$TestRail::Utils::Find::VERSION = '0.039';
use strict;
use warnings;

use Carp qw{confess cluck};
use Scalar::Util qw{blessed};
use List::Util qw{any first};
use List::MoreUtils qw{uniq};

use File::Find;
use Cwd qw{abs_path};
use File::Basename qw{basename};

use Hash::Merge qw{merge};
use MCE::Loop;

use TestRail::Utils;

sub findRuns {
    my ( $opts, $tr ) = @_;
    confess("TestRail handle must be provided as argument 2")
      unless blessed($tr) eq 'TestRail::API';

    my ($status_labels);

    #Process statuses
    if ( $opts->{'statuses'} ) {
        @$status_labels = $tr->statusNamesToLabels( @{ $opts->{'statuses'} } );
    }

    my $project = $tr->getProjectByName( $opts->{'project'} );
    confess("No such project '$opts->{project}'.\n") if !$project;

    my $pconfigs = [];
    @$pconfigs =
      $tr->translateConfigNamesToIds( $project->{'id'}, @{ $opts->{configs} } )
      if $opts->{'configs'};

    my ( $runs, $plans, $planRuns, $cruns, $found ) = ( [], [], [], [], 0 );
    $runs = $tr->getRuns( $project->{'id'} )
      if ( !$opts->{'configs'} )
      ;    # If configs are passed, global runs are not in consideration.
    $plans = $tr->getPlans( $project->{'id'} );
    @$plans = map { $tr->getPlanByID( $_->{'id'} ) } @$plans;
    foreach my $plan (@$plans) {
        $cruns = $tr->getChildRuns($plan);
        next if !$cruns;
        foreach my $run (@$cruns) {
            next if scalar(@$pconfigs) != scalar( @{ $run->{'config_ids'} } );

            #Compare run config IDs against desired, invalidate run if all conditions not satisfied
            $found = 0;
            foreach my $cid ( @{ $run->{'config_ids'} } ) {
                $found++ if grep { $_ == $cid } @$pconfigs;
            }
            $run->{'created_on'}   = $plan->{'created_on'};
            $run->{'milestone_id'} = $plan->{'milestone_id'};
            push( @$planRuns, $run )
              if $found == scalar( @{ $run->{'config_ids'} } );
        }
    }

    push( @$runs, @$planRuns );

    if ( $opts->{'statuses'} ) {
        @$runs = $tr->getRunSummary(@$runs);
        @$runs = grep { defined( $_->{'run_status'} ) }
          @$runs;    #Filter stuff with no results
        foreach my $status (@$status_labels) {
            @$runs = grep { $_->{'run_status'}->{$status} }
              @$runs;    #If it's positive, keep it.  Otherwise forget it.
        }
    }

    #Sort FIFO/LIFO by milestone or creation date of run
    my $sortkey = 'created_on';
    if ( $opts->{'milesort'} ) {
        @$runs = map {
            my $run = $_;
            $run->{'milestone'} =
              $tr->getMilestoneByID( $run->{'milestone_id'} )
              if $run->{'milestone_id'};
            my $milestone =
              $run->{'milestone'} ? $run->{'milestone'}->{'due_on'} : 0;
            $run->{'due_on'} = $milestone;
            $run
        } @$runs;
        $sortkey = 'due_on';
    }

    #Suppress 'no such option' warnings
    @$runs = map { $_->{$sortkey} //= ''; $_ } @$runs;
    if ( $opts->{'lifo'} ) {
        @$runs = sort { $b->{$sortkey} cmp $a->{$sortkey} } @$runs;
    }
    else {
        @$runs = sort { $a->{$sortkey} cmp $b->{$sortkey} } @$runs;
    }

    return $runs;
}

sub getTests {
    my ( $opts, $tr ) = @_;
    confess("TestRail handle must be provided as argument 2")
      unless blessed($tr) eq 'TestRail::API';

    my ( undef, undef, $run ) =
      TestRail::Utils::getRunInformation( $tr, $opts );
    my ( $status_ids, $user_ids );

    #Process statuses
    @$status_ids = $tr->statusNamesToIds( @{ $opts->{'statuses'} } )
      if $opts->{'statuses'};

    #Process assignedto ids
    @$user_ids = $tr->userNamesToIds( @{ $opts->{'users'} } )
      if $opts->{'users'};

    my $cases = $tr->getTests( $run->{'id'}, $status_ids, $user_ids );
    return ( $cases, $run );
}

sub findTests {
    my ( $opts, @cases ) = @_;

    confess "Error! match and no-match options are mutually exclusive.\n"
      if ( $opts->{'match'} && $opts->{'no-match'} );
    confess "Error! match and orphans options are mutually exclusive.\n"
      if ( $opts->{'match'} && $opts->{'orphans'} );
    confess "Error! no-match and orphans options are mutually exclusive.\n"
      if ( $opts->{'orphans'} && $opts->{'no-match'} );
    my @tests = @cases;
    my (@realtests);
    my $ext = $opts->{'extension'} // '';

    if ( $opts->{'match'} || $opts->{'no-match'} || $opts->{'orphans'} ) {
        my @tmpArr = ();
        my $dir =
            ( $opts->{'match'} || $opts->{'orphans'} )
          ? ( $opts->{'match'} || $opts->{'orphans'} )
          : $opts->{'no-match'};
        confess "No such directory '$dir'" if !-d $dir;

        if ( ref( $opts->{finder} ) eq 'CODE' ) {
            @realtests = $opts->{finder}->( $dir, $ext );
        }
        else {
            if ( !$opts->{'no-recurse'} ) {
                File::Find::find(
                    sub {
                        push( @realtests, $File::Find::name )
                          if -f && m/\Q$ext\E$/;
                    },
                    $dir
                );
            }
            else {
                @realtests = glob("$dir/*$ext");
            }
        }
        foreach my $case (@cases) {
            foreach my $path (@realtests) {
                next unless $case->{'title'} eq basename($path);
                $case->{'path'} = $path;
                push( @tmpArr, $case );
                last;
            }
        }
        @tmpArr = grep {
            my $otest = $_;
            !( grep { $otest->{'title'} eq $_->{'title'} } @tmpArr )
        } @tests if $opts->{'orphans'};
        @tests = @tmpArr;
        @tests = map { { 'title' => $_ } } grep {
            my $otest = basename($_);
            scalar( grep { basename( $_->{'title'} ) eq $otest } @tests ) == 0
        } @realtests if $opts->{'no-match'};    #invert the list in this case.
    }

    @tests = map { abs_path( $_->{'path'} ) } @tests
      if $opts->{'match'} && $opts->{'names-only'};
    @tests = map { $_->{'full_title'} = abs_path( $_->{'path'} ); $_ } @tests
      if $opts->{'match'} && !$opts->{'names-only'};
    @tests = map { $_->{'title'} } @tests
      if !$opts->{'match'} && $opts->{'names-only'};

    return @tests;
}

sub getCases {
    my ( $opts, $tr ) = @_;
    confess("First argument must be instance of TestRail::API")
      unless blessed($tr) eq 'TestRail::API';

    my $project = $tr->getProjectByName( $opts->{'project'} );
    confess "No such project '$opts->{project}'.\n" if !$project;

    my $suite =
      $tr->getTestSuiteByName( $project->{'id'}, $opts->{'testsuite'} );
    confess "No such testsuite '$opts->{testsuite}'.\n" if !$suite;
    $opts->{'testsuite_id'} = $suite->{'id'};

    my $section;
    $section =
      $tr->getSectionByName( $project->{'id'}, $suite->{'id'},
        $opts->{'section'} )
      if $opts->{'section'};
    confess "No such section '$opts->{section}.\n"
      if $opts->{'section'} && !$section;

    my $section_id;
    $section_id = $section->{'id'} if ref $section eq "HASH";

    my $type_ids;
    @$type_ids = $tr->typeNamesToIds( @{ $opts->{'types'} } )
      if ref $opts->{'types'} eq 'ARRAY';

    #Above will confess if anything's the matter

    #TODO Translate opts into filters
    my $filters = {
        'section_id' => $section_id,
        'type_id'    => $type_ids
    };

    return $tr->getCases( $project->{'id'}, $suite->{'id'}, $filters );
}

sub findCases {
    my ( $opts, @cases ) = @_;

    confess('testsuite_id parameter mandatory in options HASHREF')
      unless defined $opts->{'testsuite_id'};
    confess('Directory parameter mandatory in options HASHREF.')
      unless defined $opts->{'directory'};
    confess( 'No such directory "' . $opts->{'directory'} . "\"\n" )
      unless -d $opts->{'directory'};

    my $ret = { 'testsuite_id' => $opts->{'testsuite_id'} };
    if ( !$opts->{'no-missing'} ) {
        my $mopts = {
            'no-match'   => $opts->{'directory'},
            'names-only' => 1,
            'extension'  => $opts->{'extension'}
        };
        my @missing = findTests( $mopts, @cases );
        $ret->{'missing'} = \@missing;
    }
    if ( $opts->{'orphans'} ) {
        my $oopts = {
            'orphans'   => $opts->{'directory'},
            'extension' => $opts->{'extension'}
        };
        my @orphans = findTests( $oopts, @cases );
        $ret->{'orphans'} = \@orphans;
    }
    if ( $opts->{'update'} ) {
        my $uopts = {
            'match'     => $opts->{'directory'},
            'extension' => $opts->{'extension'}
        };
        my @updates = findTests( $uopts, @cases );
        $ret->{'update'} = \@updates;
    }
    return $ret;
}

sub getResults {
    my ( $tr, $opts, @cases ) = @_;
    my $res      = {};
    my $projects = $tr->getProjects();

    my ( @seenRunIds, @seenPlanIds );

    my @results;

    #TODO obey status filtering
    #TODO obey result notes text grepping
    foreach my $project (@$projects) {
        next
          if $opts->{projects}
          && !( grep { $_ eq $project->{'name'} } @{ $opts->{'projects'} } );
        my $runs = $tr->getRuns( $project->{'id'} );
        push( @seenRunIds, map { $_->{id} } @$runs );

        #Translate plan names to ids
        my $plans = $tr->getPlans( $project->{'id'} ) || [];
        push( @seenPlanIds, map { $_->{id} } @$plans );

        #Filter out plans which do not match our filters to prevent a call to getPlanByID
        if ( $opts->{'plans'} ) {
            @$plans = grep {
                my $p = $_;
                any { $p->{'name'} eq $_ } @{ $opts->{'plans'} }
            } @$plans;
        }

        #Filter out runs which do not match our filters
        if ( $opts->{'runs'} ) {
            @$runs = grep {
                my $r = $_;
                any { $r->{'name'} eq $_ } @{ $opts->{'runs'} }
            } @$runs;
        }

        #Filter out prior plans
        if ( $opts->{'plan_ids'} ) {
            @$plans = grep {
                my $p = $_;
                !any { $p->{'id'} eq $_ } @{ $opts->{'plan_ids'} }
            } @$plans;
        }

        #Filter out prior runs
        if ( $opts->{'run_ids'} ) {
            @$runs = grep {
                my $r = $_;
                !any { $r->{'id'} eq $_ } @{ $opts->{'run_ids'} }
            } @$runs;
        }

        $opts->{'runs'} //= [];
        foreach my $plan (@$plans) {
            $plan = $tr->getPlanByID( $plan->{'id'} );
            my $plan_runs = $tr->getChildRuns($plan);
            push( @$runs, @$plan_runs ) if $plan_runs;
        }

        my $configs = $tr->getConfigurations( $project->{id} );
        my %config_map;
        @config_map{ map { $_->{'id'} } @$configs } =
          map { $_->{'name'} } @$configs;

        MCE::Loop::init {
            max_workers => 'auto',
            chunk_size  => 'auto'
        };

        push(
            @results,
            mce_loop {
                my $runz = $_;
                my $res  = {};
                foreach my $run (@$runz) {

                    #Translate config ids to names, also remove any gone configs
                    my @run_configs =
                      grep { defined $_ }
                      map  { $config_map{$_} } @{ $run->{config_ids} };
                    next
                      if scalar( @{ $opts->{runs} } )
                      && !( grep { $_ eq $run->{'name'} }
                        @{ $opts->{'runs'} } );

                    if ( $opts->{fast} ) {
                        my @csz = @cases;
                        @csz = grep { ref($_) eq 'HASH' } map {
                            my $cname = basename($_);
                            my $c = $tr->getTestByName( $run->{id}, $cname );
                            $c->{config_ids} = \@run_configs;
                            $c->{name} = $cname if $c;
                            $c
                        } @csz;
                        next unless scalar(@csz);

                        my $results = $tr->getRunResults( $run->{id} );
                        foreach my $c (@csz) {
                            $res->{ $c->{name} } //= [];
                            my $cres =
                              first { $c->{id} == $_->{test_id} } @$results;
                            return unless $cres;

                            $c->{results} = [$cres];
                            $c = _filterResults( $opts, $c );

                            push( @{ $res->{ $c->{name} } }, $c )
                              if scalar( @{ $c->{results} } );
                        }
                        next;
                    }

                    foreach my $case (@cases) {
                        my $c =
                          $tr->getTestByName( $run->{'id'}, basename($case) );
                        next unless ref $c eq 'HASH';

                        $res->{$case} //= [];
                        $c->{results} =
                          $tr->getTestResults( $c->{'id'},
                            $tr->{'global_limit'}, 0 );
                        $c->{config_ids} = \@run_configs;
                        $c = _filterResults( $opts, $c );

                        push( @{ $res->{$case} }, $c )
                          if scalar( @{ $c->{results} } )
                          ;    #Make sure they weren't filtered out
                    }
                }
                return MCE->gather( MCE->chunk_id, $res );
            }
            @$runs
        );
    }

    foreach my $result (@results) {
        $res = merge( $res, $result );
    }

    return ( $res, \@seenPlanIds, \@seenRunIds );
}

sub _filterResults {
    my ( $opts, $c ) = @_;

    #Filter by provided pattern, if any
    if ( $opts->{'pattern'} ) {
        my $pattern = $opts->{pattern};
        @{ $c->{results} } =
          grep { my $comment = $_->{comment} || ''; $comment =~ m/$pattern/i }
          @{ $c->{results} };
    }

    #Filter by the provided case IDs, if any
    if ( ref( $opts->{'defects'} ) eq 'ARRAY'
        && scalar( @{ $opts->{defects} } ) )
    {
        @{ $c->{results} } = grep {
            my $defects = $_->{defects};
            any {
                my $df_case = $_;
                any { $df_case eq $_ } @{ $opts->{defects} };
            }
            @$defects
        } @{ $c->{results} };
    }

    #Filter by the provided versions, if any
    if ( ref( $opts->{'versions'} ) eq 'ARRAY'
        && scalar( @{ $opts->{versions} } ) )
    {
        @{ $c->{results} } = grep {
            my $version = $_->{version};
            any { $version eq $_ } @{ $opts->{versions} };
        } @{ $c->{results} };
    }

    return $c;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TestRail::Utils::Find - Find runs and tests according to user specifications.

=head1 VERSION

version 0.039

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 findRuns

Find runs based on the options HASHREF provided.
See the documentation for L<testrail-runs>, as the long argument names there correspond to hash keys.

The primary routine of testrail-runs.

=over 4

=item HASHREF C<OPTIONS> - flags acceptable by testrail-tests

=item TestRail::API C<HANDLE> - TestRail::API object

=back

Returns ARRAYREF of run definition HASHREFs.

=head2 getTests(opts,testrail)

Get the tests specified by the options passed.

=over 4

=item HASHREF C<OPTS> - Options for getting the tests

=over 4

=item STRING C<PROJECT> - name of Project to look for tests in

=item STRING C<RUN> - name of Run to get tests from

=item STRING C<PLAN> (optional) - name of Plan to get run from

=item ARRAYREF[STRING] C<CONFIGS> (optional) - names of configs run must satisfy, if part of a plan

=item ARRAYREF[STRING] C<USERS> (optional) - names of users to filter cases by assignee

=item ARRAYREF[STRING] C<STATUSES> (optional) - names of statuses to filter cases by

=back

=back

Returns ARRAYREF of tests, and the run in which they belong.

=head2 findTests(opts,case1,...,caseN)

Given an ARRAY of tests, find tests meeting your criteria (or not) in the specified directory.

=over 4

=item HASHREF C<OPTS> - Options for finding tests:

=over 4

=item STRING C<MATCH> - Only return tests which exist in the path provided, and in TestRail.  Mutually exclusive with no-match, orphans.

=item STRING C<NO-MATCH> - Only return tests which are in the path provided, but not in TestRail.  Mutually exclusive with match, orphans.

=item STRING C<ORPHANS> - Only return tests which are in TestRail, and not in the path provided.  Mutually exclusive with match, no-match

=item BOOL C<NO-RECURSE> - Do not do a recursive scan for files.

=item BOOL C<NAMES-ONLY> - Only return the names of the tests rather than the entire test objects.

=item STRING C<EXTENSION> (optional) - Only return files ending with the provided text (e.g. .t, .test, .pl, .pm)

=item CODE  C<FINDER> (optional) - Use the provided sub to get the list of files on disk.  Provides the directory & extension based on above options as arguments.  Must return list of tests.

=back

=item ARRAY C<CASES> - Array of cases to translate to pathnames based on above options.

=back

Returns tests found that meet the criteria laid out in the options.
Provides absolute path to tests if match is passed; this is the 'full_title' key if names-only is false/undef.
Dies if mutually exclusive options are passed.

=head2 getCases

Get cases in a testsuite matching your parameters passed

=head2 findCases(opts,@cases)

Find orphan, missing and needing-update cases.
They are returned as the hash keys 'orphans', 'missing', and 'updates' respectively.
The testsuite_id is also returned in the output hashref.

Option hash keys for input are 'no-missing', 'orphans', and 'update'.

Returns HASHREF.

=head2 getResults(options, @cases)

Get results for tests by name, filtered by the provided options, and skipping any runs found in the provided ARRAYREF of run IDs.

Probably should have called this findResults, but we all prefer to get results right?

Returns ARRAYREF of results, and an ARRAYREF of seen plan IDs

Valid Options:

=over 4

=item B<plans> - ARRAYREF of plan names to check.

=item B<runs> - ARRAYREF of runs names to check.

=item B<plan_ids> - ARRAYREF of plan IDs to NOT check.

=item B<run_ids> - ARRAYREF of run IDs to NOT check.

=item B<pattern> - Pattern to filter case results on.

=item B<defects> - ARRAYREF of defects of which at least one must be present in a result.

=item B<fast> - Whether to get only the latest result from the test in your run(s).  This can significantly speed up operations when gathering metrics for large numbers of tests.

=back

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
