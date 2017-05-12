package UR::Namespace::Command::Test::Run;

#
# single dash command line params go to perl
# double dash command line params go to the script
#

use warnings;
use strict;
use File::Temp; # qw/tempdir/;
use Path::Class; # qw(file dir);
use DBI;
use Cwd;
use UR;
our $VERSION = "0.46"; # UR $VERSION;
use File::Find;

use TAP::Harness;
use TAP::Formatter::Console;
use TAP::Parser::Aggregator;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
    has => [
        bare_args => { is_optional => 1, is_many => 1, shell_args_position => 1, is_input => 1 },
        recurse           => { is => 'Boolean',
                               doc => 'Run all .t files in the current directory, and in recursive subdirectories.' },
        list              => { is => 'Boolean',
                               doc => 'List the tests, but do not actually run them.' },
        noisy             => { is => 'Boolean',
                               doc => "doesn't redirect stdout",is_optional => 1 },
        perl_opts         => { is => 'String',
                               doc => 'Override options to the Perl interpreter when running the tests (-d:Profile, etc.)', is_optional => 1,
                               default_value => '' },
        lsf               => { is => 'Boolean',
                               doc => 'If true, tests will be submitted as jobs via bsub' },
        color             => { is => 'Boolean',
                               doc => 'Use TAP::Harness::Color to generate color output',
                               default_value => 0 },
        junit             => { is => 'Boolean',
                               doc => 'Run all tests with junit style XML output. (requires TAP::Formatter::JUnit)' },
 ],
    has_optional => [
        'time'            => { is => 'String',
                               doc => 'Write timelog sum to specified file', },
        long              => { is => 'Boolean',
                               doc => 'Run tests including those flagged as long', },
        cover             => { is => 'List',
                               doc => 'Cover only this(these) modules', },
        cover_svn_changes => { is => 'Boolean',
                               doc => 'Cover modules modified in svn status', },
        cover_svk_changes => { is => 'Boolean',
                               doc => 'Cover modules modified in svk status', },
        cover_cvs_changes => { is => 'Boolean',
                               doc => 'Cover modules modified in cvs status', },
        cover_git_changes => { is => 'Boolean',
                               doc => 'Cover modules modified in git status', },
        coverage          => { is => 'Boolean',
                               doc => 'Invoke Devel::Cover', },
        script_opts       => { is => 'String',
                               doc => 'Override options to the test case when running the tests (--dump-sql --no-commit)',
                               default_value => ''  },
        callcount         => { is => 'Boolean',
                               doc => 'Count the number of calls to each subroutine/method', },
        jobs              => { is => 'Number',
                               doc => 'How many tests to run in parallel',
                               default_value => 1, },
        lsf_params        => { is => 'String',
                               doc => 'Params passed to bsub while submitting jobs to lsf',
                               default_value => '-q short -R select[type==LINUX64]' },
        run_as_lsf_helper => { is => 'String',
                               doc => 'Used internally by the test harness', },
        inc               => { is => 'String',
                               doc => 'Additional paths for @INC, alias for -I',
                               is_many => 1, },
     ],
);

sub help_brief { "Run the test suite against the source tree." }

sub help_synopsis {
    return <<'EOS'
cd MyNamespace
ur test run --recurse                   # run all tests in the namespace or under the current directory
ur test run                             # runs all tests in the t/ directory under pwd
ur test run t/mytest1.t My/Class.t      # run specific tests
ur test run -v -t --cover-svk-changes   # run tests to cover latest svk updates
ur test run -I ../some/path/            # Adds ../some/path to perl's @INC through -I
ur test run --junit                     # writes test output in junit's xml format (consumable by Hudson integration system)
EOS
}

sub help_detail {
    return <<EOS
This command is like "prove" or "make test", running the test suite for the
current namespace.

The default behavior is to search for tests by finding directories named 't'
under the current directory, and then find files matching *.t under those
directories.  If the --recurse option is used, then it will search for *.t
files anywhere under the current directory.

It uses many of the TAP:: family of modules, and so the underlying behavior
can be influenced by changing the environment variables they use such
as PERL_TEST_HARNESS_DUMP_TAP and ALLOW_PASSING_TODOS.  These modules include
TAP::Harness, TAP::Formatter::Console, TAP::Formatter::Junit, TAP::Parser
and others.
EOS
}


# We're overriding create() so it'll run in a Namespace directory or
# not.  If run within a namespace dir, then it'll run all the tests under
# the namespace.  If not, it'll run all the tests in the current dir
sub create {
    my $class = shift;

    my $bx = $class->define_boolexpr(@_);
    unless ($bx->specifies_value_for('namespace_name')) {
        my $namespace_name = $class->resolve_namespace_name_from_cwd();
        $namespace_name ||= 'UR';    # Pretend we're running in the UR namespace
        $bx = $bx->add_filter(namespace_name => $namespace_name);
    }
    return $class->SUPER::create($bx);
}


# Override so we'll allow '-I' on the command line
sub _shell_args_getopt_specification {
    my $self = shift;

    my($params_hash, @spec) = $self->SUPER::_shell_args_getopt_specification();

    foreach (@spec) {
        if ($_ eq 'inc=s@') {
            $_ = 'inc|I=s@';
            last;
        }
    }
    return($params_hash, @spec);
}

sub execute {
    my $self = shift;

    #$DB::single = 1;

    my $working_path;
    if ($self->namespace_name ne 'UR') {
        $self->status_message("Running tests within namespace ".$self->namespace_name);
        $working_path = $self->namespace_path;
    } else {
        $self->status_message("Running tests under the current directory");
        $working_path = '.';
    }

    if ($self->run_as_lsf_helper) {
        $self->_lsf_test_worker($self->run_as_lsf_helper);
        exit(0);
    }

    # nasty parsing of command line args
    # this may no longer be needed..
    my @tests = $self->bare_args; 

    if ($self->recurse) {
        if (@tests) {
            $self->error_message("Cannot currently combine the recurse option with a specific test list.");
            return;
        }
        @tests = $self->_find_t_files_under_directory($working_path);
    }
    elsif (not @tests) {
        my @dirs;
        File::Find::find(sub {
                if ($_ eq 't' and -d $_) {
                    push @dirs, $File::Find::name;
                }
            },
            $working_path);

        if (@dirs == 0) {
            $self->error_message("No 't' directories found.  Write some tests.");
            return;
        }
        chomp @dirs;
        for my $dir (@dirs) {
            push @tests, $self->_find_t_files_under_directory($dir);
        }
    }
    else {
        # rely on the @tests list from the cmdline
    }

    # uniqify and sort them
    my %tests = map { $_ => 1 } @tests;
    @tests = sort keys %tests;

    if ($self->list) {
        $self->status_message("Tests:");
        for my $test (@tests) {
            $self->status_message($test);
        }
        return 1;
    }

    if (not @tests) {
        $self->error_message("No tests found under $working_path");
        return;
    }

    my $results = $self->_run_tests(@tests);

    return $results;
}


sub _find_t_files_under_directory {
    my($self,$path) = @_;

    my @tests;
    File::Find::find(sub {
            if (m/\.t$/ and not -d $_) {
                push @tests, $File::Find::name;
            }
        }, $path);
    chomp @tests;
    return @tests;
}

# Run by the test harness when test are scheduled out via LSF
# $master_spec is a string like "host:port"
sub _lsf_test_worker {
    my($self,$master_spec) = @_;

    require IO::Socket;

    open my $saved_stdout, ">&STDOUT"     or die "Can't dup STDOUT: $!";
    open my $saved_stderr, ">&STDERR"     or die "Can't dup STDERR: $!";

    while(1) {
        open STDOUT, ">&", $saved_stdout or die "Can't restore stdout \$saved_stdout: $!";
        open STDERR, ">&", $saved_stderr or die "Can't restore stderr \$saved_stderr: $!";

        my $socket = IO::Socket::INET->new( PeerAddr => $master_spec,
                                            Proto => 'tcp');
        unless ($socket) {
            die "Can't connect to test master: $!";
        }

        $socket->autoflush(1);

        my $line = <$socket>;
        chomp($line);

        if ($line eq '' or $line eq 'EXIT TESTS') {
            # print STDERR "Closing\n";
            $socket->close();
            exit(0);
        }

        # print "Running >>$line<<\n";

        open STDOUT, ">&", $socket or die "Can't redirect stdout: $!";
        open STDERR, ">&", $socket or die "Can't redirect stderr: $!";

        system($line);

        $socket->close();
    }
}


sub _run_tests {
    my $self = shift;    
    my @tests = @_;

    # this ensures that we don't see warnings
    # and error statuses when doing the bulk test
    no warnings;
    local $ENV{UR_TEST_QUIET} = $ENV{UR_TEST_QUIET};
    unless (defined $ENV{UR_TEST_QUIET}) {
        $ENV{UR_TEST_QUIET} = 1;
    }
    use warnings;

    local $ENV{UR_DBI_NO_COMMIT} = 1;

    if($self->long) {
        # Make sure long tests run
        $ENV{UR_RUN_LONG_TESTS}=1;
    }

    my @cover_specific_modules;

    if (my $cover = $self->cover) {
        push @cover_specific_modules, @$cover;
    }

    if ($self->cover_svn_changes) {
        push @cover_specific_modules, get_status_file_list('svn');
    }
    elsif ($self->cover_svk_changes) {
        push @cover_specific_modules, get_status_file_list('svk');
    }
    elsif ($self->cover_git_changes) {
        push @cover_specific_modules, get_status_file_list('git');
    }
    elsif ($self->cover_cvs_changes) {
        push @cover_specific_modules, get_status_file_list('cvs');
    }

    if (@cover_specific_modules) {
        my $dbh = DBI->connect("dbi:SQLite:/gsc/var/cache/testsuite/coverage_metrics.sqlitedb","","");
        $dbh->{PrintError} = 0;
        $dbh->{RaiseError} = 1;
        my %tests_covering_specified_modules;
        for my $module_name (@cover_specific_modules) {
            my $module_test_names = $dbh->selectcol_arrayref(
                "select test_name from test_module_use where module_name = ?",undef,$module_name
            );
            for my $test_name (@$module_test_names) {
                $tests_covering_specified_modules{$test_name} ||= [];
                push @{ $tests_covering_specified_modules{$test_name} }, $module_name;
            }
        }

        if (@tests) {
            # specific tests were listed: only run the intersection of that set and the covering set
            my @filtered_tests;
            for my $test_name (sort keys %tests_covering_specified_modules) {
                my $specified_modules_coverted = $tests_covering_specified_modules{$test_name};
                $test_name =~ s/^(.*?)(\/t\/.*)$/$2/g;
                if (my @matches = grep { $test_name =~ $_ } @tests) {
                    if (@matches > 1) {
                        Carp::confess("test $test_name matches multiple items in the tests on the filesystem: @matches");
                    }
                    elsif (@matches == 0) {
                        Carp::confess("test $test_name matches nothing in the tests on the filesystem!");
                    }
                    else {
                        print STDERR "Running $matches[0] for modules @$specified_modules_coverted.\n";
                        push @filtered_tests, $matches[0];
                    }
                }
            }
            @tests = @filtered_tests;
        }
        else {
            # no tests explicitly specified on the command line: run exactly those which cover the listed modules
            @tests = sort keys %tests_covering_specified_modules;
        }
        print "Running the " . scalar(@tests) . " tests which load the specified modules.\n";
    }
    else {
    }

    use Cwd;
    my $cwd = cwd();
    for (@tests) {
        s/^$cwd\///;
    }

    my $perl_opts = $self->perl_opts;
    if ($self->coverage()) {
        $perl_opts .= ' -MDevel::Cover';
    }
    if ($self->callcount()) {
        $perl_opts .= ' -d:callcount';
    }

    if (UR::Util::used_libs()) {
        $ENV{'PERL5LIB'} = UR::Util::used_libs_perl5lib_prefix() . $ENV{'PERL5LIB'};
    }

    my %harness_args;
    my $formatter;
    if ($self->junit) {
        eval "use TAP::Formatter::JUnit;";
        if ($@) {
            Carp::croak("Couldn't use TAP::Formatter::JUnit for junit output: $@");
        }
        %harness_args = ( formatter_class => 'TAP::Formatter::JUnit',
                          merge => 1,
                          timer => 1,
                        );
    } else {
        $formatter = TAP::Formatter::Console->new( {
                            jobs => $self->jobs,
                            show_count => 1,
                            color => $self->color,
                        } );
        $formatter->quiet();
        %harness_args = ( formatter => $formatter );
    }

    $harness_args{'jobs'} = $self->jobs if ($self->jobs > 1);
    if ($self->script_opts) {
        my @opts = split(/\s+/, $self->script_opts);
        $harness_args{'test_args'} = \@opts;
    }
    $harness_args{'multiplexer_class'} = 'My::TAP::Parser::Multiplexer';
    $harness_args{'scheduler_class'} = 'My::TAP::Parser::Scheduler';
    
    if ($self->perl_opts || $self->inc) {
        $harness_args{'switches'} = [ split(' ', $self->perl_opts),
                                      map { '-I' . Path::Class::Dir->new($_)->absolute } $self->inc];
    }

    my $timelog_sum = $self->time();
    my $timelog_dir;
    if ($timelog_sum) {
        $harness_args{'parser_class'} = 'My::TAP::Parser::Timer';
        $timelog_sum = Path::Class::file($timelog_sum);
        $timelog_dir = Path::Class::dir(File::Temp::tempdir('.timelog.XXXXXX', DIR => '.', CLEANUP => 1));
        My::TAP::Parser::Timer->set_timer_info($timelog_dir,\@tests);
    }

    my $harness = TAP::Harness->new( \%harness_args);

    if ($self->lsf) {
        # There doesn't seem to be a clean way (either by configuring the harness,
        # subclassing the harness or parser, or hooking to a callback) to pass
        # down the user's requested lsf params from here.  So, looks like we
        # need to hack it through here.  This means that multiple 'ur test' commands
        # running concurrently and using lsf will always use the last object's lsf_params.
        # though I doubt anyone would ever really need to do that...
        My::TAP::Parser::IteratorFactory::LSF->lsf_params($self->lsf_params);
        My::TAP::Parser::IteratorFactory::LSF->max_jobs($self->jobs);

        $harness->callback('parser_args',
                           sub {
                               my($args, $job_as_arrayref) = @_;
                               $args->{'iterator_factory_class'} = 'My::TAP::Parser::IteratorFactory::LSF';
                           });


    }

    my $aggregator = TAP::Parser::Aggregator->new();
    
    $aggregator->start();

    my $old_stderr;
    unless ($self->noisy) {
        open $old_stderr ,">&STDERR" or die "Failed to save STDERR";
        open(STDERR,">/dev/null") or die "Failed to redirect STDERR";
    }

    eval { 
        no warnings;
        local %SIG = %SIG; 
        delete $SIG{__DIE__}; 
        $ENV{UR_DBI_NO_COMMIT} = 1;
        #$DB::single = 1;

        $SIG{'INT'} = sub {
                              print "\n\nInterrupt.\nWaiting for running tests to finish...\n\n";
                              
                              $My::TAP::Parser::Iterator::Process::LSF::SHOULD_EXIT = 1;
                              $SIG{'INT'} = 'DEFAULT';
                              #My::TAP::Parser::IteratorFactory::LSF->_kill_running_jobs();
                              #sleep(1);
                              #$aggregator->stop();
                              #$formatter->summary($aggregator);
                              #exit(0);
                          };
 
        #runtests(@tests);
        $harness->aggregate_tests( $aggregator, @tests );
    };

    unless ($self->noisy) {
        open(STDERR,">&", $old_stderr) or die "Failed to restore STDERR";
    }

    $aggregator->stop();
    if ($@) {
        $self->error_message($@);
        return;
    }
    else {
        if ($self->coverage()) {
            # FIXME - is this GSC-specific?
            system("chmod -R g+rwx cover_db");
            system("/gsc/bin/cover | tee > coverage.txt");
        }
        $formatter->summary($aggregator) if ($formatter);
    }

    if ($timelog_sum) {
        $timelog_sum->openw->print(
            sort
            map { $_->openr->getlines }
            $timelog_dir->children
        );
        if (-z $timelog_sum) {
            unlink $timelog_sum;
            warn "Error producing time summary file!";
        }
        $timelog_dir->rmtree;
    }

    return !$aggregator->has_problems;
}


sub get_status_file_list {
    my $tool = shift;

    my @status_data = eval {

        my $orig_cwd = cwd();
        my @words = grep { length($_) } split("/",$orig_cwd);
        while (@words and ($words[-1] ne "GSC")) {
            pop @words;
        }
        unless (@words and $words[-1] eq "GSC") {
            die "Cannot find 'GSC' directory above the cwd.  Cannot auto-run $tool status.\n";
        }
        pop @words;
        my $vcs_dir = "/" . join("/", @words);

        unless (chdir($vcs_dir)) {
            die "Failed to change directories to $vcs_dir!";
        }

        my @lines;
        if ($tool eq "svn" or $tool eq "svk") {
            @lines = IO::File->new("$tool status |")->getlines;
        }
        elsif ($tool eq "cvs") {
            @lines = IO::File->new("cvs -q up |")->getlines;
        } 
        elsif ($tool eq "git") {
            @lines = IO::File->new("git diff --name-status |")->getlines;
        }
        else {
            die "Unknown tool $tool.  Try svn, svk, cvs or git.\n";
        }
        # All these tools have flags or other data with the filename as the last column
        @lines = map { (split(/\s+/))[-1] } @lines;

        unless (chdir($orig_cwd)) {
            die "Error changing directory back to the original cwd after checking file status with $tool.";
        }

        return @lines;
    };

    if ($@) {
        die "Error checking version control status for $tool:\n$@";
    }

    my @modules;
    for my $line (@status_data) {
        my ($status,$file) = ($line =~ /^(.).\s*(\S+)/);
        next if $status eq "?" or $status eq "!";
        print "covering $file\n";
        push @modules, $file;
    }

    unless (@modules) {
        die "Failed to find modified modules via $tool.\n";
    }

    return @modules;
}

package My::TAP::Parser::Multiplexer;
use base 'TAP::Parser::Multiplexer';

sub _iter {
    my $self = shift;

    my $original_iter = $self->SUPER::_iter(@_);
    return sub {
        for(1) {
            # This is a hack...
            # the closure _iter returns does a select() on the subprocess' output handle
            # which returns immediately after you hit control-C with no results, and the
            # existing code in there expects real results from select().  This way, we catch
            # the exception that happens when you do that, and give it a chance to try again
            my @retval = eval { &$original_iter };
            if (index($@, q(Can't use an undefined value as an ARRAY reference))>= 0) {
                redo;
            } elsif ($@) {
                die $@;
            }
            return @retval;
        }
    };
}

package My::TAP::Parser::IteratorFactory::LSF;

use IO::Socket;
use IO::Select;

use base 'TAP::Parser::IteratorFactory';

# Besides being the factory for parser iterators, we're also the factory for 
# LSF jobs

# In the TAP::* code, they mention that the iterator factory is never instantiated,
# but may be in the future.  When that happens, move this state info into the
# object that gets created/initialized
my $state = { 'listen'     => undef, # The listening socket
              'select'     => undef, # select object for the listen socket
              idle_jobs    => [],    # holds a list of file handles of connected workers
              # running_jobs => [],  # we're not tracking workers that are working for now...
              lsf_jobids   => [],    # jobIDs of the worker processes
              lsf_params   => '',    # params when running bsub
              max_jobs     => 0,     # Max number of jobs
            };

sub _kill_running_jobs  {
    # The worker processes should notice when the master goes away,
    # but just in case, we'll kill them off
    foreach my $jobid ( @{$state->{'lsf_jobids'}} ) {
        print "bkilling LSF jobid $jobid\n";
        `bkill $jobid`;
    }
}

END {
    my $exit_code = $?;
    &_kill_running_jobs();
    $? = $exit_code;  # restore the exit code, since the bkill commands set a different exit code
}


sub lsf_params {
    my $proto = shift;

    if (@_) {
        $state->{'lsf_params'} = shift;
    }
    return $state->{'lsf_params'};
}

sub max_jobs {
    my $proto = shift;

    if (@_) {
        $state->{'max_jobs'} = shift;
    }
    return $state->{'max_jobs'};
}


sub make_process_iterator {
    my $proto = shift;

    My::TAP::Parser::Iterator::Process::LSF->new(@_);
}

sub next_idle_worker {
    my $proto = shift;

    $proto->process_events();

    while(! @{$state->{'idle_jobs'}} ) {

        my $did_create_new_worker = 0;
        if (@{$state->{'lsf_jobids'}} < $state->{'max_jobs'}) {
            $proto->create_new_worker();
            $did_create_new_worker = 1;
        }

        sleep(1);

        my $count = $proto->process_events($did_create_new_worker ? 10 : 0);
        if (! $did_create_new_worker and ! $count) {
            unless ($proto->_verify_lsf_jobs_are_still_alive()) {
                print "\n*** The LSF worker jobs are having trouble starting up... Exiting\n";
                kill 'INT', $$;
                sleep 2;
                kill 'INT', $$;
            }
        }
    }

    my $worker = shift @{$state->{'idle_jobs'}};
    return $worker;
}

sub _verify_lsf_jobs_are_still_alive {
    my $alive = 0;
    foreach my $jobid ( @{$state->{'lsf_jobids'}} ) {
        my @output = `bjobs $jobid`;
        next unless $output[1];  # expired jobs only have 1 line of output: Job <xxxx> is not found
        my @stat = split(/\s+/, $output[1]);
        $alive++ if ($stat[2] eq 'RUN' or $stat[2] eq 'PEND');
    }
    return $alive;
}
        

#sub worker_is_now_idle {
#    my($proto, $worker) = @_;
#
#    for (my $i = 0; $i < @{$state->{'running_jobs'}}; $i++) {
#        if ($state->{'running_jobs'}->[$i] eq $worker) {
#            splice(@{$state->{'running_jobs'}}, $i, 1);
#            last;
#        }
#    }
#
#    push @{$state->{'idle_workers'}}, $worker;
#}

sub create_new_worker {
    my $proto = shift;

    my $port = $state->{'listen'}->sockport;

    my $host = $state->{'listen'}->sockhost;
    if ($host eq '0.0.0.0') {
        $host = $ENV{'HOST'};
    }
    $host .= ":$port";
    
    my $lsf_params = $state->{'lsf_params'} || '';
    my $line = `bsub $lsf_params ur test run --run-as-lsf-helper $host`;
    my ($jobid) = $line =~ m/Job \<(\d+)\>/;
    unless ($jobid) {
        Carp::croak("Couldn't parse jobid out of the line: $line");
    }
    push @{$state->{'lsf_jobids'}}, $jobid;
}

sub process_events {
    my $proto = shift;
    my $timeout = shift || 0;

    my $listen = $state->{'listen'};
    unless ($listen) {
        $listen = $state->{'listen'} = IO::Socket::INET->new(Listen => 5,
                                                             Proto => 'tcp');
        unless ($listen) {
            Carp::croak("Unable to create listen socket: $!");
        }
    }

    my $select = $state->{'select'};
    unless ($select) {
        $select = $state->{'select'} = IO::Select->new($listen);
    }

    my $processed_events = 0;
    while(1) {
        my @ready = $select->can_read($timeout);
        last unless (@ready);

        foreach my $handle ( @ready ) {
            $processed_events++;
            if ($handle eq $listen) {
                my $socket = $listen->accept();
                unless ($socket) {
                    Carp::croak("accept: $!");
                }
                $socket->autoflush(1);
                push @{$state->{'idle_jobs'}}, $socket;
    
            } else {
                # shoulnd't get here...
            }
            $timeout = 0;  # just do a poll() next time around
        }
    }
    return $processed_events;
}


package My::TAP::Parser::Timer;

use base 'TAP::Parser';

our $timelog_dir;
our $test_list;

sub set_timer_info {
    my($class,$time_dir,$testlist) = @_;

    $timelog_dir = $time_dir;
    $test_list = $testlist;
}

    
sub make_iterator {
    my $self = shift;

    my $args = $_[0];
    if (ref($args) eq 'HASH') {
        # It's about to make a process iterator.  Prepend the stuff to
        # run the timer, too

        unless (-d $timelog_dir) {
            File::Path::mkpath("$timelog_dir");
        }

        my $timelog_file = $self->_timelog_file_for_command_list($args->{'command'});

        my $format = q('%C %e %U %S %I %K %P');  # yes, that's single quotes inside q()
        unshift @{$args->{'command'}},
                '/usr/bin/time', '-o', $timelog_file, '-a', '-f', $format;
    }
        
    $self->SUPER::make_iterator(@_);
}

sub _timelog_file_for_command_list {
    my($self,$command_list) = @_;

    foreach my $test_file ( @$test_list ) {
        foreach my $cmd_part ( reverse @$command_list ) {
            if ($test_file eq $cmd_part) {
                my $log_file = Path::Class::file($cmd_part)->basename;
                $log_file =~ s/\.t$//;
                $log_file .= sprintf('.%d.%d.time', time(), $$);  # Try to make the name unique
                $log_file = $timelog_dir->file($log_file);
                $log_file->openw->close();

                return $log_file;
            }
        }
    }
    Carp::croak("Can't determine time log file for command line: ",join(' ',@$command_list));
}

package My::TAP::Parser::Scheduler;

use base 'TAP::Parser::Scheduler';

sub get_job {
    my $self = shift;

    if ($My::TAP::Parser::Iterator::Process::LSF::SHOULD_EXIT) {
        our $already_printed;

        unless ($already_printed) {
            print "\n\n  ",$self->{'count'}," Tests not yet run before interrupt\n";
            print "------------------------------------------\n";
            foreach my $job ( $self->get_all ) {
                print $job->{'description'},"\n";
            }
            print "------------------------------------------\n";
            $already_printed = 1;
        }
        return;
    }

    $self->SUPER::get_job(@_);
}


package My::TAP::Parser::Iterator::Process::LSF;

our $SHOULD_EXIT = 0;

use base 'TAP::Parser::Iterator::Process';

sub _initialize {
    my($self, $args) = @_;

    my @command = @{ delete $args->{command} || [] }
      or die "Must supply a command to execute";

    # From TAP::Parser::Iterator::Process
    my $chunk_size = delete $args->{_chunk_size} || 65536;

    if ( my $setup = delete $args->{setup} ) {
        $setup->(@command);
    }

    my $handle = My::TAP::Parser::IteratorFactory::LSF->next_idle_worker();
    # Tell the worker to run the command
    unless($handle->print(join(' ', @command) . "\n")) {
        print "Couldn't send command to worker on host ".$handle->peeraddr." port ".$handle->peerport.": $!\n";
        print "Handle is " . ( $handle->connected ? '' : '_not_' ) . " connected\n";
    }

    $self->{'out'} = $handle;
    $self->{'err'} = '';
    $self->{'sel'} = undef; #IO::Select->new($handle);
    $self->{'pid'} = undef;
    $self->{'chunk_size'} = $chunk_size;
 
    if ( my $teardown = delete $args->{teardown} ) {
        $self->{teardown} = sub {
            $teardown->(@command);
        };
    }

    return $self;
}

sub next_raw {
    my $self = shift;

    My::TAP::Parser::IteratorFactory::LSF->process_events();

    if ($SHOULD_EXIT) {
        #$DB::single = 1;
        if  ($self->{'sel'}) {
            foreach my $h ( $self->{'sel'}->handles ) {
                $h->close;
                $self->{'sel'}->remove($h);
            }
            return "1..0 # Skipped: Interrupted by user";
        } else {
           return;
        }
    }
    $self->SUPER::next_raw(@_);
}

#sub _finish {
#    my $self = shift;
#
#    $self->SUPER::_finish(@_);
#
#    My::TAP::Parser::IteratorFactory::LSF->worker_is_now_idle($handle);
#}

    

1;

=pod

=head1 NAME

ur test run - run one or more test scripts

=head1 SYNOPSIS

 # run everything in a given namespace
 cd my_sandbox/TheNamespace
 ur test run --recurse

 # run only selected tests
 cd my_sandbox/TheNamespace
 ur test run My/Module.t Another/Module.t t/foo.t t/bar.t

 # run only tests which load the TheNamespace::DNA module
 cd my_sandbox/TheNamespace
 ur test run --cover TheNamespace/DNA.pm

 # run only tests which cover the changes you have in Subversion
 cd my_sandbox/TheNamespace
 ur test run --cover-svn-changes

 # run 5 tests in parallel as jobs scheduled via LSF
 cd my_sandbox/TheNamespace
  ur test run --lsf --jobs 5

=head1 DESCRIPTION

Runs a test harness around automated test cases, like "make test" in a 
make-oriented software distrbution, and similar to "prove" run in bulk.  

When run w/o parameters, it looks for "t" directory in the current working 
directory, and runs ALL tests under that directory.

=head1 OPTIONS

=over 4

=item --recurse

 Run all tests in the current directory, and in sub-directories.  Without
 --recurse, it will first recursively search for directories named 't' under
 the current directory, and then recursively seatch for *.t files under those
 directories.

=item --long

 Include "long" tests, which are otherwise skipped in test harness execution

=item -v

 Be verbose, meaning that individual cases will appear instead of just a full-script summary

=item --cover My/Module.pm

 Looks in a special sqlite database which is updated by the cron which runs tests,
 to find all tests which load My/Module.pm at some point before they exit.  Only
 these tests will be run.

* you will still need the --long flag to run long tests.

* if you specify tests on the command-line, only tests in both lists will run

* this can be specified multiple times

=item --cover-TOOL-changes

 TOOL can be svn, svk, or cvs.

 The script will run either "svn status", "svk status", or "cvs -q up" on a parent
 directory with "GSC" in it, and get all of the changes in your perl_modules trunk.
 It will behave as though those modules were listed as individual --cover options.

=item --lsf

 Tests should not be run locally, instead they are submitted as jobs to the
 LSF cluster with bsub.  

=item --lsf-params

 Parameters given to bsub when sceduling jobs.  The default is
 "-q short -R select[type==LINUX64]"

=item --jobs <number>

 This many tests should be run in parallel.  If --lsf is also specified, then
 these parallel tests will be submitted as LSF jobs.

=back

=head1 PENDING FEATURES

=over 4

=item automatic remote execution for tests requiring a distinct hardware platform

=item logging profiling and coverage metrics with each test

=back

=cut


