# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Test Framework Library
#
# >>Copyright::
# Copyright (c) 1992-1997, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 17-Mar-97 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides a general framework
# for running regression tests.
#
# >>Description::
#
# >>Limitations::
# This really should be ported to a Perl5 module, asap. :-(
#
# The way of executing a test needs to be configurable, e.g.
# a command might be a block of Perl code rather than a system command.
# Furthermore, the result code returned from system and/or its
# equivalent should be made available for checking.
#
# Each test needs to support optional initialisation and finalisation
# routines. These could be placed in an optional file called run.pl, say.
# The routines would be useful for things like:
#
# * deleting unwanted files
# * initialising data structures (when executing Perl routines)
# * checking that no existing files were changed
# * checking that additional files were not generated.
#

!require "ctime.pl";

######### Constants #########

#
# >>Description::
# {{TESTS_DEFAULT_LOG}} is the default log file.
#
$TESTS_DEFAULT_LOG = 'runtests.log';

# Usage message
@_TESTS_USAGE = (
    "runtests            - output usage",
    "runtests all        - run all tests",
    "runtests test1 ...  - run the nominated testcases",
);

######### Variables #########

# Starting time for tests
# (This is initialised after the log file is opened)
$_Tests_Start = 0;

# Counter to ensure log streams are unique
$_Tests_Cntr = 0;

# Collected stats on test counts, cases and failures
%_Tests_Count = ();
%_Tests_Cases = ();
%_Tests_Fails = ();

#
# >>Description::
# {{Y:Tests}} defines the set of available tests and the command
# to run for each test.
#
%Tests = ();

#
# >>Description::
# {{Y:Tests_Verify_Fn}} defines the function used to verify that
# each test succeeded. The function interface is:
#
# =  $failures = &$verify_fn($test)
#
$Tests_Verify_Fn = 'verify_files';

#
#
# >>Description::
# The following variables are initialised by {{Y:tests_init}}:
#
# * {{@Tests_Order}} - the list of tests to run
# * {{$Tests_Group}} - the name of this group of tests
# * {{$Tests_Strm}} - the stream to output diagnostics to
# * {{$Tests_Verbose}} - diagnostics level.
#
@Tests_Order = ();
$Tests_Group = '';
$Tests_Strm = '';
$Tests_Verbose = 0;
$Tests_Web = 0;
$Tests_No_Logging = 0;

######### Routines #########

#
# >>Description::
#
sub runtests {
#   local() = @_;
#   local();

    &_tests_init() || &_tests_exit();
    &_tests_run();
    &_tests_report();
    &_tests_exit();
}

#
# >>Description::
# {{Y:addtests}} adds a set of tests.
# {{%tests}} contains the mapping of names to commands.
#
sub addtests {
    local(%tests) = @_;
#   local();

    %Tests = %tests;
}

#
# >>Description::
# {{Y:gentests}} builds a set of tests from a rule and list of names.
# {{rule}} contains a %s to indicate where the test name goes in the command.
#
sub gentests {
    local($rule, @names) = @_;
#   local();
    local($test);

    for $test (@names) {
        $Tests{$test} = sprintf($rule, $test);
    }
}

#
# >>Description::
#
sub nestedtests {
#   local() = @_;
#   local();
    local($opts);
    local($dir, $file);
    local($test);

    # Get the options as we need them to build the nested tests
    &_tests_get_options();
    $opts = "";
    $opts .= " -v$Tests_Verbose" if $Tests_Verbose;
    $opts .= " -w"               if $Tests_Html;

    # Change the verify function
    $Tests_Verify_Fn = 'verify_logs';

    # Get the nested tests
    for $test (<*/runtests>) {
        ($dir, $file) = split(/\//, $test);
        $Tests{$dir} = "cd $dir;./$file -g$Tests_Group$dir$opts all;cd ..";
    }
}

#
# >>Description::
# {{Y:tests_msg}} outputs a diagnostics message.
# All diagnostics are output to the current logging stream.
# If {level}} is greater than {{Tests_Verbose}},
# the message is {{not}} echoed on standard error.
#
sub tests_msg {
    local($msg, $level) = @_;
#   local();

    print STDERR      "$msg\n" if $level <= $Tests_Verbose;
    print $Tests_Strm "$msg\n" unless $Tests_No_Logging;
}

#
# >>_Description::
# {{Y:_tests_get_options}} processes command line options.
#
sub _tests_get_options {
#   local() = @_;
#   local();
    local($opt, $param);

    while ($ARGV[0] =~ /^\-(\w)/) {
        $opt = $1;
        $param = $';
        shift(@ARGV);

        # Get the diagnostics level, if any
        if ($opt eq 'v') {
            $Tests_Verbose = $param eq '' ? 1 : $param;
        }

        # Get the group name, if any
        if ($opt eq 'g') {
            $Tests_Group = "$param:";
        }

        # Get the other options
        if ($opt eq 'n') {
            $Tests_No_Logging = 1;
        }
        if ($opt eq 'w') {
            $Tests_Web = 1;
        }
    }
}

#
# >>_Description::
# {{Y:_tests_init}} processes the command line and
# initialises the test variables.
#
sub _tests_init {
#   local() = @_;
    local($ok);
    local($log_file);
    local($pwd);
    local($now);

    # Get the options
    &_tests_get_options();

    # Check the command line
    unless (@ARGV) {
        printf "usage is:\n%s\n", join("\n", @_TESTS_USAGE);
        return 0;
    }

    # Open the diagnostics stream, if any
    $Tests_Strm = "TESTS" . $_Tests_Cntr++;
    $log_file   = $TESTS_DEFAULT_LOG;
    if ($Tests_No_Logging) {
        # do nothing
    }
    else {
        # Save the existing log file, if a logs directory exists
        if (-f $log_file) {
            # TO BE COMPLETED
        }

        # open the log file
        unless (open($Tests_Strm, ">$log_file")) {
            print STDERR "fatal: unable to open log file '$log_file':$!";
            return 0;
        }
    }

    # Get the list of tests to run
    if ($ARGV[0] eq 'all') {
        @Tests_Order = sort keys %Tests;
    }
    else {
        @Tests_Order = @ARGV;
    }

    # Output some diagnostics
    $_Tests_Start = time;
    $now = &ctime($_Tests_Start);
    chop($now);
    &tests_msg("start time: $now", 2);

    # Return result
    return 1;
}

#
# >>_Description::
# {{Y:_tests_run}} runs the list of tests named in {{@Tests_Order}}.
#
sub _tests_run {
#   local();
#   local();
    local($verify_fn);
    local($test, $cmd);
    local($test_count);
    local($case_count);

    # Get the verify function
    $verify_fn = $Tests_Verify_Fn;

    # Output some diagnostics
    &tests_msg(sprintf("about to run: %s", join(" ", @Tests_Order)), 2);
    &tests_msg("verify function: $verify_fn", 2);

    # Check the verify function exists
    unless (defined &$verify_fn) {
        &tests_msg("verify function '$verify_fn' not defined");
    }

    # Run the requested tests
    for $test (@Tests_Order) {
        $ARGV = $test;
        $cmd = $Tests{$test};
        if ($cmd) {
            &tests_msg("running $test: command is '$cmd'", 2);
            system($cmd);
        }
        else {
            &tests_msg("unknown test '$test'");
            $_Tests_Count{$test}++;
            $_Tests_Cases{$test}++;
            $_Tests_Fails{$test}++;
            next;
        }

        # Verify the outputs
        $case_count = 1;
        $test_count = 1;
        if (defined &$verify_fn) {
            $_Tests_Fails{$test} += &$verify_fn($test, *case_count, *test_count);
        }
        else {
            $_Tests_Fails{$test}++;
        }
        $_Tests_Count{$test} += $test_count;
        $_Tests_Cases{$test} += $case_count;
    }
}

#
# >>_Description::
# {{Y:_tests_report}} outputs a report summarising a set of tests.
# The total number of failures is returned.
#
sub _tests_report {
#   local() = @_;
    local($total);
    local($test);
    local($test_total, $fail_total, $case_total);
    local($test_count, $fail_count, $case_count);
    local($s_tests, $s_fails, $s_cases);
    local($summary);
    local($group);
    local($minutes, $seconds);
    local($s_minutes, $s_seconds);

    # Report the problem counts
    $test_total = 0;
    $fail_total = 0;
    $case_total = 0;
    for $test (sort keys %_Tests_Fails) {
        $test_count = $_Tests_Count{$test};
        $fail_count = $_Tests_Fails{$test};
        $case_count = $_Tests_Cases{$test};
        $test_total += $test_count;
        $fail_total += $fail_count;
        $case_total += $case_count;
        if ($Tests_Verbose || $fail_count > 0) {
            $s_fails = $fail_count == 1 ? 'failure'   : 'failures';
            $s_cases = $case_count == 1 ? 'test case' : 'test cases';
            &tests_msg("$fail_count $s_fails in $case_count $s_cases in $Tests_Group$test");
        }
    }

    # Summarise the results
    $s_tests = $test_total == 1 ? 'test'      : 'tests';
    $s_fails = $fail_total == 1 ? 'failure'   : 'failures';
    $s_cases = $case_total == 1 ? 'test case' : 'test cases';
    $summary = "$test_total $s_tests, $case_total $s_cases, $fail_total $s_fails";
    if ($Tests_Group ne '') {
        $group = $Tests_Group;
        $group =~ s/:$//;
        $summary .= " in $group";
    }
    if ($_Tests_Start) {
        $seconds   = time - $_Tests_Start;
        $minutes   = int($seconds / 60);
        $seconds   = $seconds % 60;
        $s_minutes = $minutes == 1 ? 'minute' : 'minutes';
        $s_seconds = $seconds == 1 ? 'second' : 'seconds';
        $summary  .= " ($minutes $s_minutes, $seconds $s_seconds)";
    }
    &tests_msg("summary: $summary");

    # Return result
    return $total;
}

#
# >>_Description::
# {{Y:_tests_exit}} exits the current application.
#
sub _tests_exit {
#   local() = @_;
#   local();

    # Publish the log file on the web, if requested
    if ($Tests_Web && $Tests_Start) {
        close($Tests_Strm) unless $Tests_No_Logging;
        system("sdf -2html -pruntests $TESTS_DEFAULT_LOG");
    }

    # Exit the program
    exit(0);
}

#
# >>Description::
# {{Y:verify_files}} is a predefined verify function.
# Each test is expected to have a directory called {{test}}.ok
# which contains the expected set of output files.
# Files which verify ok are deleted. If possible, the other files
# are moved into a directory called {{test}}.bad. Otherwise,
# the files are left where they are.
#
sub verify_files {
    local($test, *case_count, *test_count) = @_;
    local($fail_count);
    local($ok_dir, $bad_dir);
    local(@ok_files, $ok_file, $ok);

    # Check the ok directory exists
    $ok_dir = "$test.ok";
    if (! -d $ok_dir) {
        &tests_msg("unable to find ok directory '$ok_dir'");
        return 1;
    }

    # Check the bad directory exists
    $bad_dir = "$test.bad";
    if (! -d $bad_dir) {
        mkdir($bad_dir, 0755) ||
            &tests_msg("unable to find or create bad directory '$bad_dir': $!");
    }

    # Check the files in the directory are ok
    $fail_count = 0;
    $case_count = 0;
    if ($ok_dir) {
        @ok_files = grep(s/$ok_dir\///, <$ok_dir/*>);
        for $ok_file (@ok_files) {
            $ok = &_tests_verify_file($ok_file, "$ok_dir/$ok_file",
                  "$bad_dir/$ok_file", "$Tests_Group$test");
            $fail_count++ unless $ok;
            $case_count++;
        }
    }

    # Return result
    return $fail_count;
}

#
# >>_Description::
# {{Y:_tests_verify_file}} compares a test file against a checked file.
# If the file does not match, it is renamed to {{bad_file}}.
#
sub _tests_verify_file {
    local($test_file, $check_file, $bad_file, $test_id) = @_;
    local($ok);
    local($test_data, $check_data);

    # Get the data from the test file
    unless (open(TESTFILE, $test_file)) {
        &tests_msg("unable to open test file '$test_file' for verification: $!");
        return 0;
    }
    $test_data = join('', <TESTFILE>);
    close TESTFILE;

    # Get the data from the check file
    unless (open(CHECKFILE, $check_file)) {
        &tests_msg("unable to open ok file '$check_file' for verification: $!");
        return 0;
    }
    $check_data = join('', <CHECKFILE>);
    close CHECKFILE;

    # Compare the data
    if ($test_data eq $check_data) {
        &tests_msg("ok $test_file in $test_id", 1);
        unlink $test_file ||
            &tests_msg("unable to delete '$test_file'");
        return 1;
    }
    else {
        &tests_msg("not ok $test_file in $test_id");
        rename($test_file, $bad_file) ||
            &tests_msg("unable to rename '$test_file' to '$bad_file': $!");
        return 0;
    }
}

#
# >>Description::
# {{Y:verify_logs}} is a predefined verify function.
# Each test is expected to be a nested test group, i.e.
# each test has a directory to itself and the results of the
# test run are expected to be output to a log file.
#
sub verify_logs {
    local($test, *case_count, *test_count) = @_;
    local($fail_count);
    local($log_file);

    # Open the log file
    $log_file = "$test/" . $TESTS_DEFAULT_LOG;
    unless (open(LOGFILE, $log_file)) {
        &tests_msg("unable to open test log file '$log_file': $!");
        return 1;
    }

    # Get the results of the most recent run
    while ($line = <LOGFILE>) {
        chop($line);
        if ($line =~ /^summary: (\d+) tests?, (\d+) test cases?, (\d+) failures?/) {
            $test_count = $1;
            $case_count = $2;
            $fail_count = $3;
        }
    }
    close(LOGFILE);

    # Return result
    return $fail_count;
}

# package return value
1;
