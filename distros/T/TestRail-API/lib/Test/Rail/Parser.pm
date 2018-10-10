# ABSTRACT: Upload your TAP results to TestRail
# PODNAME: Test::Rail::Parser

package Test::Rail::Parser;
$Test::Rail::Parser::VERSION = '0.044';
use strict;
use warnings;
use utf8;

use parent qw/TAP::Parser/;
use Carp qw{cluck confess};
use POSIX qw{floor strftime};
use Clone qw{clone};

use TestRail::API;
use TestRail::Utils;
use Scalar::Util qw{reftype};

use File::Basename qw{basename};

sub new {
    my ( $class, $opts ) = @_;
    $opts = clone $opts;  #Convenience, if we are passing over and over again...

    #Load our callbacks
    $opts->{'callbacks'} = {
        'test'    => \&testCallback,
        'comment' => \&commentCallback,
        'unknown' => \&unknownCallback,
        'bailout' => \&bailoutCallback,
        'EOF'     => \&EOFCallback,
        'plan'    => \&planCallback,
    };

    my $tropts = {
        'apiurl'       => delete $opts->{'apiurl'},
        'user'         => delete $opts->{'user'},
        'pass'         => delete $opts->{'pass'},
        'debug'        => delete $opts->{'debug'},
        'browser'      => delete $opts->{'browser'},
        'run'          => delete $opts->{'run'},
        'project'      => delete $opts->{'project'},
        'project_id'   => delete $opts->{'project_id'},
        'step_results' => delete $opts->{'step_results'},
        'plan'         => delete $opts->{'plan'},
        'configs'      => delete $opts->{'configs'} // [],
        'testsuite_id' => delete $opts->{'testsuite_id'},
        'testsuite'    => delete $opts->{'testsuite'},
        'encoding'     => delete $opts->{'encoding'},
        'sections'     => delete $opts->{'sections'},
        'autoclose'    => delete $opts->{'autoclose'},
        'config_group' => delete $opts->{'config_group'},

        #Stubs for extension by subclassers
        'result_options'        => delete $opts->{'result_options'},
        'result_custom_options' => delete $opts->{'result_custom_options'},
        'test_bad_status'       => delete $opts->{'test_bad_status'},
        'max_tries'             => delete $opts->{'max_tries'} || 1,
    };

    confess("plan passed, but no run passed!")
      if !$tropts->{'run'} && $tropts->{'plan'};

    #Allow natural confessing from constructor
    #Force-on POST redirects for maximum compatibility
    my $tr =
      TestRail::API->new( $tropts->{'apiurl'}, $tropts->{'user'},
        $tropts->{'pass'}, $tropts->{'encoding'}, $tropts->{'debug'}, 1,
        $tropts->{max_tries} );
    $tropts->{'testrail'} = $tr;
    $tr->{'browser'}      = $tropts->{'browser'}
      if defined( $tropts->{'browser'} );    #allow mocks
    $tr->{'debug'} = 0;                      #Always suppress in production

    #Get project ID from name, if not provided
    if ( !defined( $tropts->{'project_id'} ) ) {
        my $pname = $tropts->{'project'};
        $tropts->{'project'} = $tr->getProjectByName($pname);
        confess("Could not list projects! Shutting down.")
          if ( $tropts->{'project'} == -500 );
        if ( !$tropts->{'project'} ) {
            confess(
                "No project (or project_id) provided, or that which was provided was invalid!"
            );
        }
    }
    else {
        $tropts->{'project'} = $tr->getProjectByID( $tropts->{'project_id'} );
        confess("No such project with ID $tropts->{project_id}!")
          if !$tropts->{'project'};
    }
    $tropts->{'project_id'} = $tropts->{'project'}->{'id'};

    #Discover possible test statuses
    $tropts->{'statuses'} = $tr->getPossibleTestStatuses();
    my @ok     = grep { $_->{'name'} eq 'passed' } @{ $tropts->{'statuses'} };
    my @not_ok = grep { $_->{'name'} eq 'failed' } @{ $tropts->{'statuses'} };
    my @skip   = grep { $_->{'name'} eq 'skip' } @{ $tropts->{'statuses'} };
    my @todof = grep { $_->{'name'} eq 'todo_fail' } @{ $tropts->{'statuses'} };
    my @todop = grep { $_->{'name'} eq 'todo_pass' } @{ $tropts->{'statuses'} };
    my @retest = grep { $_->{'name'} eq 'retest' } @{ $tropts->{'statuses'} };
    my @tbad;
    @tbad =
      grep { $_->{'name'} eq $tropts->{test_bad_status} }
      @{ $tropts->{'statuses'} }
      if $tropts->{test_bad_status};
    confess("No status with internal name 'passed' in TestRail!")
      unless scalar(@ok);
    confess("No status with internal name 'failed' in TestRail!")
      unless scalar(@not_ok);
    confess("No status with internal name 'skip' in TestRail!")
      unless scalar(@skip);
    confess("No status with internal name 'todo_fail' in TestRail!")
      unless scalar(@todof);
    confess("No status with internal name 'todo_pass' in TestRail!")
      unless scalar(@todop);
    confess("No status with internal name 'retest' in TestRail!")
      unless scalar(@retest);
    confess(
        "No status with internal name '$tropts->{test_bad_status}' in TestRail!"
    ) unless scalar(@tbad) || !$tropts->{test_bad_status};

    #Map in all the statuses
    foreach my $status ( @{ $tropts->{'statuses'} } ) {
        $tropts->{ $status->{'name'} } = $status;
    }

    #Special aliases
    $tropts->{'ok'}     = $ok[0];
    $tropts->{'not_ok'} = $not_ok[0];

    confess "testsuite and testsuite_id are mutually exclusive"
      if ( $tropts->{'testsuite_id'} && $tropts->{'testsuite'} );

    #Grab testsuite by name if needed
    if ( $tropts->{'testsuite'} ) {
        my $ts = $tr->getTestSuiteByName( $tropts->{'project_id'},
            $tropts->{'testsuite'} );
        confess( "No such testsuite '" . $tropts->{'testsuite'} . "' found!" )
          unless $ts;
        $tropts->{'testsuite_id'} = $ts->{'id'};
    }

    #Grab run
    my ( $run, $plan, $config_ids );

    # See if we have to create a configuration
    my $configz2create = $tr->getConfigurations( $tropts->{'project_id'} );
    @$configz2create = grep {
        my $c = $_;
        ( grep { $_ eq $c->{'name'} } @{ $tropts->{'configs'} } )
    } @$configz2create;
    if ( scalar(@$configz2create) && $tropts->{'config_group'} ) {
        my $cgroup =
          $tr->getConfigurationGroupByName( $tropts->{project_id},
            $tropts->{'config_group'} );
        unless ( ref($cgroup) eq 'HASH' ) {
            print "# Adding Configuration Group $tropts->{config_group}...\n";
            $cgroup =
              $tr->addConfigurationGroup( $tropts->{project_id},
                $tropts->{'config_group'} );
        }
        confess(
            "Could neither find nor create the provided configuration group '$tropts->{config_group}'"
        ) unless ref($cgroup) eq 'HASH';
        foreach my $cc (@$configz2create) {
            print "# Adding Configuration $cc->{name}...\n";
            $tr->addConfiguration( $cgroup->{'id'}, $cc->{'name'} );
        }
    }

    #check if configs passed are defined for project.  If we can't get all the IDs, something's hinky
    @$config_ids = $tr->translateConfigNamesToIds( $tropts->{'project_id'},
        @{ $tropts->{'configs'} } );
    confess("Could not retrieve list of valid configurations for your project.")
      unless ( reftype($config_ids) || 'undef' ) eq 'ARRAY';
    my @bogus_configs = grep { !defined($_) } @$config_ids;
    my $num_bogus = scalar(@bogus_configs);
    confess(
        "Detected $num_bogus bad config names passed.  Check available configurations for your project."
    ) if $num_bogus;

    if ( $tropts->{'plan'} ) {

        #Attempt to find run, filtered by configurations
        $plan =
          $tr->getPlanByName( $tropts->{'project_id'}, $tropts->{'plan'} );
        confess(
            "Test plan provided is completed, and spawning was not indicated")
          if ( ref $plan eq 'HASH' )
          && $plan->{'is_completed'}
          && ( !$tropts->{'testsuite_id'} );
        if ( $plan && !$plan->{'is_completed'} ) {
            $tropts->{'plan'} = $plan;
            $run =
              $tr->getChildRunByName( $plan, $tropts->{'run'},
                $tropts->{'configs'} );    #Find plan filtered by configs

            if ( defined($run) && ( reftype($run) || 'undef' ) eq 'HASH' ) {
                $tropts->{'run'}    = $run;
                $tropts->{'run_id'} = $run->{'id'};
            }
        }
        else {
            #Try to make it if spawn is passed
            $tropts->{'plan'} = $tr->createPlan( $tropts->{'project_id'},
                $tropts->{'plan'}, "Test plan created by TestRail::API" )
              if $tropts->{'testsuite_id'};
            confess("Could not find plan "
                  . $tropts->{'plan'}
                  . " in provided project, and spawning failed (or was not indicated)!"
            ) if !$tropts->{'plan'};
        }
    }
    else {
        $run = $tr->getRunByName( $tropts->{'project_id'}, $tropts->{'run'} );
        confess(
            "Test run provided is completed, and spawning was not indicated")
          if ( ref $run eq 'HASH' )
          && $run->{'is_completed'}
          && ( !$tropts->{'testsuite_id'} );
        if (   defined($run)
            && ( reftype($run) || 'undef' ) eq 'HASH'
            && !$run->{'is_completed'} )
        {
            $tropts->{'run'}    = $run;
            $tropts->{'run_id'} = $run->{'id'};
        }
    }

    #If spawn was passed and we don't have a Run ID yet, go ahead and make it
    if ( $tropts->{'testsuite_id'} && !$tropts->{'run_id'} ) {
        print "# Spawning run\n";
        my $cases = [];
        if ( $tropts->{'sections'} ) {
            print "# with specified sections\n";

            #Then translate the sections into an array of case IDs.
            confess("Sections passed to spawn must be ARRAYREF")
              unless ( reftype( $tropts->{'sections'} ) || 'undef' ) eq 'ARRAY';
            @{ $tropts->{'sections'} } = $tr->sectionNamesToIds(
                $tropts->{'project_id'},
                $tropts->{'testsuite_id'},
                @{ $tropts->{'sections'} }
            );
            foreach my $section ( @{ $tropts->{'sections'} } ) {

                #Get the child sections, and append them to our section list so we get their cases too.
                my $append_sections = $tr->getChildSections(
                    $tropts->{'project_id'},
                    {
                        'id'       => $section,
                        'suite_id' => $tropts->{'testsuite_id'}
                    }
                );
                @$append_sections = grep {
                    my $sc = $_;
                    !scalar( grep { $_ == $sc->{'id'} }
                          @{ $tropts->{'sections'} } )
                  } @$append_sections
                  ;    #de-dup in case the user added children to the list
                @$append_sections = map { $_->{'id'} } @$append_sections;
                push( @{ $tropts->{'sections'} }, @$append_sections );

                my $section_cases = $tr->getCases(
                    $tropts->{'project_id'},
                    $tropts->{'testsuite_id'},
                    { 'section_id' => $section }
                );
                push( @$cases, @$section_cases )
                  if ( reftype($section_cases) || 'undef' ) eq 'ARRAY';
            }
        }

        if ( scalar(@$cases) ) {
            @$cases = map { $_->{'id'} } @$cases;
        }
        else {
            $cases = undef;
        }

        if ( $tropts->{'plan'} ) {
            print "# inside of plan\n";
            $plan = $tr->createRunInPlan(
                $tropts->{'plan'}->{'id'},
                $tropts->{'testsuite_id'},
                $tropts->{'run'}, undef, $config_ids, $cases
            );
            $run = $plan->{'runs'}->[0]
              if exists( $plan->{'runs'} )
              && ( reftype( $plan->{'runs'} ) || 'undef' ) eq 'ARRAY'
              && scalar( @{ $plan->{'runs'} } );
            if ( defined($run) && ( reftype($run) || 'undef' ) eq 'HASH' ) {
                $tropts->{'run'}    = $run;
                $tropts->{'run_id'} = $run->{'id'};
            }
        }
        else {
            $run = $tr->createRun(
                $tropts->{'project_id'},
                $tropts->{'testsuite_id'},
                $tropts->{'run'},
                "Automatically created Run from TestRail::API",
                undef,
                undef,
                $cases
            );
            if ( defined($run) && ( reftype($run) || 'undef' ) eq 'HASH' ) {
                $tropts->{'run'}    = $run;
                $tropts->{'run_id'} = $run->{'id'};
            }
        }
        confess("Could not spawn run with requested parameters!")
          if !$tropts->{'run_id'};
        print "# Success!\n";
    }
    confess(
        "No run ID provided, and no run with specified name exists in provided project/plan!"
    ) if !$tropts->{'run_id'};

    my $self = $class->SUPER::new($opts);
    if ( defined( $self->{'_iterator'}->{'command'} )
        && reftype( $self->{'_iterator'}->{'command'} ) eq 'ARRAY' )
    {
        $self->{'file'} = $self->{'_iterator'}->{'command'}->[-1];
        print "# PROCESSING RESULTS FROM TEST FILE: $self->{'file'}\n";
        $self->{'track_time'} = 1;
    }
    else {
        #Not running inside of prove in real-time, don't bother with tracking elapsed times.
        $self->{'track_time'} = 0;
    }

    #Make sure the step results field passed exists on the system
    my $sr_name = $tropts->{'step_results'};
    $tropts->{'step_results'} =
      $tr->getTestResultFieldByName( $tropts->{'step_results'},
        $tropts->{'project_id'} )
      if defined $tropts->{'step_results'};
    confess(
        "Invalid step results value '$sr_name' passed. Check the spelling and confirm that your project can use the '$sr_name' custom result field."
    ) if ref $tropts->{'step_results'} ne 'HASH' && $sr_name;

    $self->{'tr_opts'} = $tropts;
    $self->{'errors'}  = 0;

    #Start the shot clock
    $self->{'starttime'} = time();

    #Make sure we get the time it took to get to each step from the last correctly
    $self->{'lasttime'}   = $self->{'starttime'};
    $self->{'raw_output'} = "";

    return $self;
}

# Look for file boundaries, etc.
sub unknownCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    #Unofficial "Extensions" to TAP
    my ($status_override) = $line =~ m/^% mark_status=([a-z|_]*)/;
    if ($status_override) {
        cluck "Unknown status override"
          unless defined $self->{'tr_opts'}->{$status_override}->{'id'};
        $self->{'global_status'} =
          $self->{'tr_opts'}->{$status_override}->{'id'}
          if $self->{'tr_opts'}->{$status_override};
        print "# Overriding status to $status_override ("
          . $self->{'global_status'}
          . ")...\n"
          if $self->{'global_status'};
    }

    #XXX I'd love to just rely on the 'name' attr in App::Prove::State::Result::Test, but...
    #try to pick out the filename if we are running this on TAP in files, where App::Prove is uninvolved
    my $file = TestRail::Utils::getFilenameFromTapLine($line);
    $self->{'file'} = $file if !$self->{'file'} && $file;
    return;
}

# Register the current suite or test desc for use by test callback, if the line begins with the special magic words
sub commentCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    if ( $line =~ m/^#TESTDESC:\s*/ ) {
        $self->{'tr_opts'}->{'test_desc'} = $line;
        $self->{'tr_opts'}->{'test_desc'} =~ s/^#TESTDESC:\s*//g;
    }
    return;
}

sub testCallback {
    my ($test) = @_;
    my $self = $test->{'parser'};

    if ( $self->{'track_time'} ) {

        #Test done.  Record elapsed time.
        my $tm = time();
        $self->{'tr_opts'}->{'result_options'}->{'elapsed'} =
          _compute_elapsed( $self->{'lasttime'}, $tm );
        $self->{'elapse_display'} =
          defined( $self->{'tr_opts'}->{'result_options'}->{'elapsed'} )
          ? $self->{'tr_opts'}->{'result_options'}->{'elapsed'}
          : "0s";
        $self->{'lasttime'} = $tm;
    }

    my $line  = $test->as_string;
    my $tline = $line;
    $tline = "["
      . strftime( "%H:%M:%S %b %e %Y", localtime( $self->{'lasttime'} ) )
      . " ($self->{elapse_display})] $line"
      if $self->{'track_time'};
    $self->{'raw_output'} .= "$tline\n";

    #Don't do anything if we don't want to map TR case => ok or use step-by-step results
    if ( !$self->{'tr_opts'}->{'step_results'} ) {
        print
          "# step_results not set.  No action to be taken, except on a whole test basis.\n"
          if $self->{'tr_opts'}->{'debug'};
        return 1;
    }

    $line =~ s/^(ok|not ok)\s[0-9]*\s-\s//g;
    my $test_name = $line;

    print "# Assuming test name is '$test_name'...\n"
      if $self->{'tr_opts'}->{'debug'} && !$self->{'tr_opts'}->{'step_results'};

    my $todo_reason;

    #Setup args to pass to function
    my $status      = $self->{'tr_opts'}->{'not_ok'}->{'id'};
    my $status_name = 'NOT OK';
    if ( $test->is_actual_ok() ) {
        $status      = $self->{'tr_opts'}->{'ok'}->{'id'};
        $status_name = 'OK';
        if ( $test->has_skip() ) {
            $status      = $self->{'tr_opts'}->{'skip'}->{'id'};
            $status_name = 'SKIP';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# skip //gi;
            print "# '$test_name'\n";
        }
        if ( $test->has_todo() ) {
            $status      = $self->{'tr_opts'}->{'todo_pass'}->{'id'};
            $status_name = 'TODO PASS';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# todo & skip //gi;    #handle todo_skip
            $test_name =~ s/# todo\s(.*)$//gi;
            $todo_reason = $test->explanation();
        }
    }
    else {
        if ( $test->has_todo() ) {
            $status      = $self->{'tr_opts'}->{'todo_fail'}->{'id'};
            $status_name = 'TODO FAIL';
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# todo & skip //gi;    #handle todo_skip
            $test_name =~ s/# todo\s(.*)$//gi;
            $todo_reason = $test->explanation();
        }
    }

    #XXX much of the above code would be unneeded if $test->description wasn't garbage
    $test_name =~ s/\s+$//g;

    #If this is a TODO, set the reason in the notes
    $self->{'tr_opts'}->{'test_notes'} .= "\nTODO reason: $todo_reason\n"
      if $todo_reason;

    my $sr_sys_name = $self->{'tr_opts'}->{'step_results'}->{'name'};
    $self->{'tr_opts'}->{'result_custom_options'} = {}
      if !defined $self->{'tr_opts'}->{'result_custom_options'};
    $self->{'tr_opts'}->{'result_custom_options'}->{$sr_sys_name} = []
      if !defined $self->{'tr_opts'}->{'result_custom_options'}->{$sr_sys_name};

    #TimeStamp every particular step

    $line = "["
      . strftime( "%H:%M:%S %b %e %Y", localtime( $self->{'lasttime'} ) )
      . " ($self->{elapse_display})] $line"
      if $self->{'track_time'};

    #XXX Obviously getting the 'expected' and 'actual' from the tap DIAGs would be ideal
    push(
        @{ $self->{'tr_opts'}->{'result_custom_options'}->{$sr_sys_name} },
        TestRail::API::buildStepResults( $line, "OK", $status_name, $status )
    );
    print "# Appended step results.\n" if $self->{'tr_opts'}->{'debug'};
    return 1;
}

sub bailoutCallback {
    my ($test) = @_;
    my $self   = $test->{'parser'};
    my $line   = $test->as_string;
    $self->{'raw_output'} .= "$line\n";

    if ( $self->{'tr_opts'}->{'step_results'} ) {
        my $sr_sys_name = $self->{'tr_opts'}->{'step_results'}->{'name'};

        #Handle the case where we die right off
        $self->{'tr_opts'}->{'result_custom_options'}->{$sr_sys_name} //= [];
        push(
            @{ $self->{'tr_opts'}->{'result_custom_options'}->{$sr_sys_name} },
            TestRail::API::buildStepResults(
                "Bail Out!.",       "Continued testing",
                $test->explanation, $self->{'tr_opts'}->{'not_ok'}->{'id'}
            )
        );
    }
    $self->{'is_bailout'} = 1;
    return;
}

sub EOFCallback {
    my ($self) = @_;

    if ( $self->{'track_time'} ) {

        #Test done.  Record elapsed time.
        $self->{'tr_opts'}->{'result_options'}->{'elapsed'} =
          _compute_elapsed( $self->{'starttime'}, time() );
    }

    #Fail if the file is not set
    if ( !defined( $self->{'file'} ) ) {
        cluck(
            "ERROR: Cannot detect filename, will not be able to find a Test Case with that name"
        );
        $self->{'errors'}++;
        return 0;
    }

    my $run_id    = $self->{'tr_opts'}->{'run_id'};
    my $test_name = basename( $self->{'file'} );

    my $status      = $self->{'tr_opts'}->{'ok'}->{'id'};
    my $todo_failed = $self->todo() - $self->todo_passed();
    $status = $self->{'tr_opts'}->{'not_ok'}->{'id'} if $self->has_problems();
    if (   !$self->tests_run()
        && !$self->is_good_plan()
        && $self->{'tr_opts'}->{test_bad_status} )
    {  #No tests were run, no plan, code is probably bad so allow custom marking
        $status =
          $self->{'tr_opts'}->{ $self->{'tr_opts'}->{test_bad_status} }->{'id'};
    }
    $status = $self->{'tr_opts'}->{'todo_pass'}->{'id'}
      if $self->todo_passed()
      && !$self->failed()
      && $self->is_good_plan();    #If no fails, but a TODO pass, mark as TODOP
    $status = $self->{'tr_opts'}->{'todo_fail'}->{'id'}
      if $todo_failed
      && !$self->failed()
      && $self->is_good_plan()
      ;    #If no fails, but a TODO fail, prefer TODOF to TODOP
    $status = $self->{'tr_opts'}->{'skip'}->{'id'}
      if $self->skip_all();    #Skip all, whee

    #Global status override
    $status = $self->{'global_status'} if $self->{'global_status'};

    #Notify user about bad plan a bit better, supposing we haven't bailed
    if (   !$self->is_good_plan()
        && !$self->{'is_bailout'}
        && defined $self->tests_run
        && defined $self->tests_planned )
    {
        $self->{'raw_output'} .=
            "\n# ERROR: Bad plan.  You ran "
          . $self->tests_run
          . " tests, but planned "
          . $self->tests_planned . ".";
        if ( $self->{'tr_opts'}->{'step_results'} ) {
            my $sr_sys_name = $self->{'tr_opts'}->{'step_results'}->{'name'};

            #Handle the case where we die right off
            $self->{'tr_opts'}->{'result_custom_options'}->{$sr_sys_name} //=
              [];
            push(
                @{
                    $self->{'tr_opts'}->{'result_custom_options'}
                      ->{$sr_sys_name}
                },
                TestRail::API::buildStepResults(
                    "Bad Plan.",
                    $self->tests_planned . " Tests",
                    $self->tests_run . " Tests",
                    $status
                )
            );
        }
    }

    #Optional args
    my $notes          = $self->{'raw_output'};
    my $options        = $self->{'tr_opts'}->{'result_options'};
    my $custom_options = $self->{'tr_opts'}->{'result_custom_options'};

    print "# Setting results...\n";
    my $cres =
      $self->_set_result( $run_id, $test_name, $status, $notes, $options,
        $custom_options );
    $self->_test_closure();
    $self->{'global_status'} = $status;

    undef $self->{'tr_opts'} unless $self->{'tr_opts'}->{'debug'};

    return $cres;
}

sub planCallback {
    my ($plan) = @_;
    my $self = $plan->{'parser'};
    $self->{raw_output} .= $plan->as_string if $plan->as_string;
}

sub _set_result {
    my ( $self, $run_id, $test_name, $status, $notes, $options,
        $custom_options ) = @_;
    my $tc;

    print "# Test elapsed: " . $options->{'elapsed'} . "\n"
      if $options->{'elapsed'};

    print "# Attempting to find case by title '"
      . $test_name
      . "' in run $run_id...\n";
    $tc =
      $self->{'tr_opts'}->{'testrail'}->getTestByName( $run_id, $test_name );
    if ( !defined($tc) || ( reftype($tc) || 'undef' ) ne 'HASH' ) {
        cluck("ERROR: Could not find test case: $tc");
        $self->{'errors'}++;
        return 0;
    }

    my $xid = $tc ? $tc->{'id'} : '???';

    my $cres;

    #Set test result
    if ($tc) {
        print
          "# Reporting result of case $xid in run $self->{'tr_opts'}->{'run_id'} as status '$status'...";

        # createTestResults(test_id,status_id,comment,options,custom_options)
        $cres =
          $self->{'tr_opts'}->{'testrail'}
          ->createTestResults( $tc->{'id'}, $status, $notes, $options,
            $custom_options );
        print "# OK! (set to $status)\n"
          if ( reftype($cres) || 'undef' ) eq 'HASH';
    }
    if ( !$tc || ( ( reftype($cres) || 'undef' ) ne 'HASH' ) ) {
        print "# Failed!\n";
        print "# No Such test case in TestRail ($xid).\n";
        $self->{'errors'}++;
    }

}

#Compute the expected testrail date interval from 2 unix timestamps.
sub _compute_elapsed {
    my ( $begin, $end ) = @_;
    my $secs_elapsed  = $end - $begin;
    my $mins_elapsed  = floor( $secs_elapsed / 60 );
    my $secs_remain   = $secs_elapsed % 60;
    my $hours_elapsed = floor( $mins_elapsed / 60 );
    my $mins_remain   = $mins_elapsed % 60;

    my $datestr = "";

    #You have bigger problems if your test takes days
    if ($hours_elapsed) {
        $datestr .= "$hours_elapsed" . "h $mins_remain" . "m";
    }
    else {
        $datestr .= "$mins_elapsed" . "m";
    }
    if ($mins_elapsed) {
        $datestr .= " $secs_remain" . "s";
    }
    else {
        $datestr .= " $secs_elapsed" . "s";
    }
    undef $datestr if $datestr eq "0m 0s";
    return $datestr;
}

sub _test_closure {
    my ($self) = @_;
    return unless $self->{'tr_opts'}->{'autoclose'};
    my $is_plan = $self->{'tr_opts'}->{'plan'} ? 1 : 0;
    my $id =
        $self->{'tr_opts'}->{'plan'}
      ? $self->{'tr_opts'}->{'plan'}->{'id'}
      : $self->{'tr_opts'}->{'run'};

    if ($is_plan) {
        my $plan_summary =
          $self->{'tr_opts'}->{'testrail'}->getPlanSummary($id);

        return
          if ( $plan_summary->{'totals'}->{'Untested'} +
            $plan_summary->{'totals'}->{'Retest'} );
        print "# No more outstanding cases detected.  Closing Plan.\n";
        $self->{'plan_closed'} = 1;
        return $self->{'tr_opts'}->{'testrail'}->closePlan($id);
    }

    my ($run_summary) = $self->{'tr_opts'}->{'testrail'}->getRunSummary($id);
    return
      if ( $run_summary->{'run_status'}->{'Untested'} +
        $run_summary->{'run_status'}->{'Retest'} );
    print "# No more outstanding cases detected.  Closing Run.\n";
    $self->{'run_closed'} = 1;
    return $self->{'tr_opts'}->{'testrail'}
      ->closeRun( $self->{'tr_opts'}->{'run_id'} );
}

sub make_result {
    my ( $self, @args ) = @_;
    my $res = $self->SUPER::make_result(@args);
    $res->{'parser'} = $self;
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Rail::Parser - Upload your TAP results to TestRail

=head1 VERSION

version 0.044

=head1 DESCRIPTION

A TAP parser which will upload your test results to a TestRail install.
Has several options as to how you might want to upload said results.

Subclass of L<TAP::Parser>, see that for usage past the constructor.

You should probably use L<App::Prove::Plugin::TestRail> or the bundled program testrail-report for day-to-day usage...
unless you need to subclass this.  In that case a couple of options have been exposed for your convenience.

=head1 CONSTRUCTOR

=head2 B<new(OPTIONS)>

Get the TAP Parser ready to talk to TestRail, and register a bunch of callbacks to upload test results.

=over 4

=item B<OPTIONS> - HASHREF -- Keys are as follows:

=over 4

=item B<apiurl> - STRING: Full URI to your TestRail installation.

=item B<user> - STRING: Name of your TestRail user.

=item B<pass> - STRING: Said user's password, or one of their valid API keys (TestRail 4.2 and above).

=item B<debug> - BOOLEAN: Print a bunch of extra messages

=item B<browser> - OBJECT: Something like an LWP::UserAgent.  Useful for mocking.

=item B<run> - STRING: name of desired run.

=item B<plan> - STRING (semi-optional): Name of test plan to use, if your run provided is a child of said plan.

=item B<configs> - ARRAYREF (optional): Configurations to filter runs in plan by.  Runs can have the same name, yet with differing configurations in a plan; this handles that odd case.

=item B<project> - STRING (optional): name of project containing your desired run.  Required if project_id not passed.

=item B<project_id> - INTEGER (optional): ID of project containing your desired run.  Required if project not passed.

=item B<step_results> - STRING (optional): 'internal name' of the 'step_results' type field available for your project.

=item B<result_options> - HASHREF (optional): Extra options to set with your result.  See L<TestRail::API>'s createTestResults function for more information.

=item B<custom_options> - HASHREF (optional): Custom options to set with your result.  See L<TestRail::API>'s createTestResults function for more information.  step_results will be set here, if the option is passed.

=item B<testsuite> - STRING (optional): Attempt to create a run based on the testsuite identified by the name passed here.  If plan/configs are passed, create it as a child of said plan with the listed configs.  If the run exists, use it and disregard this option.  If the containing plan does not exist, create it too.  Mutually exclusive with 'testsuite_id'.

=item B<testsuite_id> - INTEGER (optional): Attempt to create a run based on the testsuite identified by the ID passed here.  If plan/configs are passed, create it as a child of said plan with the listed configs.  If the run exists, use it and disregard this option.  If the plan does not exist, create it too.  Mutually exclusive with 'testsuite'.

=item B<sections> - ARRAYREF (optional): Restrict a spawned run to cases in these particular sections.

=item B<autoclose> - BOOLEAN (optional): If no cases in the run/plan are marked 'Untested' or 'Retest', go ahead and close the run.  Default false.

=item B<encoding> - STRING (optional): Character encoding of TAP to be parsed and the various inputs parameters for the parser.  Defaults to UTF-8, see L<Encode::Supported> for a list of supported encodings.

=item B<test_bad_status> - STRING (optional): 'internal' name of whatever status you want to mark compile failures & no plan + no assertion tests.

=item B<max_tries> - INTEGER (optional): number of times to try failing requests.  Defaults to 1 (don't re-try).

=back

=back

In both this mode and step_results, the file name of the test is expected to correspond to the test name in TestRail.

This module also attempts to calculate the elapsed time to run each test if it is run by a prove plugin rather than on raw TAP.

The constructor will terminate if the statuses 'pass', 'fail', 'retest', 'skip', 'todo_pass', and 'todo_fail' are not registered as result internal names in your TestRail install.

The purpose of the retest status is somewhat special, as there is no way to set a test back to 'untested' in TestRail, and we use this to allow automation to pick back up if
something needs re-work for whatever reason.

The global status of the case will be set according to the following rules:

    1. If there are no issues whatsoever besides TODO failing tests & skips, mark as PASS
    2. If there are any non-skipped or TODOed fails OR a bad plan (extra/missing tests), mark as FAIL
    3. If there are only SKIPs (e.g. plan => skip_all), mark as SKIP
    4. If the only issues with the test are TODO tests that pass, mark as TODO PASS (to denote these TODOs for removal).
    5. If no tests are run at all, and no plan made (such as a compile failure), the cases will be marked as failures unless you provide a test_bad status name in your testrailrc.

Step results will always be whatever status is relevant to the particular step.

=head1 TAP Extensions

=head2 Forcing status reported

A line that begins like so:

% mark_status=

Will allow you to force the status of a test case to whatever is on the right hand side of the = expression.

Example (force test to retest in event of tool failure):

    my $failed = do_something_possibly_causing_tool_failure();
    print "% mark_status=retest" if $failed;

Bogus statuses will cluck, but otherwise be ignored.  Valid statuses are any of the required internal names in your TestRail install (see above).

Multiple instances of this will ignore all but the latest valid status.

=head1 PARSER CALLBACKS

=head2 unknownCallback

Called whenever we encounter an unknown line in TAP.  Only useful for prove output, as we might pick a filename out of there.
Stores said filename for future use if encountered.

=head2 commentCallback

Grabs comments preceding a test so that we can include that as the test's notes.
Especially useful when merge=1 is passed to the constructor.

=head2 testCallback

If we are using step_results, append it to the step results array for use at EOF.
Otherwise, do nothing.

=head2 bailoutCallback

If bail_out is called, note it and add step results.

=head2 EOFCallback

If we are running in step_results mode, send over all the step results to TestRail.
Otherwise, upload the overall results of the test to TestRail.

=head2 planCallback

Used to record test planning messages.

=head2 make_result

make_result has been overridden to make the parser object available to callbacks.

=head1 NOTES

When using SKIP: {} (or TODO skip) blocks, you may want to consider naming your skip reasons the same as your test names when running in test_per_ok mode.

=head1 SEE ALSO

L<TestRail::API>

L<TAP::Parser>

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
