package Test::Run::Core;

use strict;
use warnings;

use Moose;

extends('Test::Run::Base::PlugHelpers');


use vars qw($VERSION);

use MRO::Compat;

use List::MoreUtils ();

use Fatal qw(opendir);

use Time::HiRes ();
use List::Util ();

use File::Spec;

use Test::Run::Assert qw/ assert /;
use Test::Run::Obj::Error ();
use Test::Run::Straps ();
use Test::Run::Obj::IntOrUnknown ();

=head1 NAME

Test::Run::Core - Base class to run standard TAP scripts.

=head1 VERSION

Version 0.0306

=cut

$VERSION = '0.0306';

$ENV{HARNESS_ACTIVE} = 1;
$ENV{HARNESS_NG_VERSION} = $VERSION;

END
{
    # For VMS.
    delete $ENV{HARNESS_ACTIVE};
    delete $ENV{HARNESS_NG_VERSION};
}

has "_bonusmsg" => (is => "rw", isa => "Str");
has "dir_files" => (is => "rw", isa => "ArrayRef", lazy => 1,
    default => sub { [] },
);
has "_new_dir_files" => (is => "rw", isa => "Maybe[ArrayRef]");
has "failed_tests" => (is => "rw", isa => "HashRef");
has "format_columns" => (is => "rw", isa => "Num");
has "last_test_elapsed" => (is => "rw", isa => "Str");
has "last_test_obj" => (is => "rw", isa => "Test::Run::Obj::TestObj");
has "last_test_results" => (is => "rw", isa => "Test::Run::Straps::StrapsTotalsObj");
has "list_len" => (is => "rw", isa => "Num", default => 0);
has "max_namelen" => (is => "rw", isa => "Num");

# I don't know for sure what output is. It is Test::Run::Output in
# Test::Run::Plugin::CmdLine::Output but could be different elsewhere.
has "output" => (is => "rw", isa => "Ref");
has "_start_time" => (is => "rw", isa => "Num");
has "Strap" => (is => "rw", isa => "Test::Run::Straps",
    lazy => 1, builder => "_get_new_strap"
);
has "tot" => (is => "rw", isa => "Test::Run::Obj::TotObj");
has "width" => (is => "rw", isa => "Num");

# Private Simple Params of _get_private_simple_params
has "Columns" => (is => "rw", isa => "Num", default => "80");
has "Debug" => (is => "rw", isa => "Bool");
has "Leaked_Dir" => (is => "rw", isa => "Str");
has "NoTty" => (is => "rw", isa => "Bool");
has "Switches" => (is => "rw", isa => "Maybe[Str]", default => "-w",);
has "Switches_Env" => (is => "rw", isa => "Maybe[Str]");
has "test_files" => (is => "rw", isa => "ArrayRef");
has "test_files_data" => (is => "rw", isa => "HashRef",
    default => sub { +{} },
);
has "Test_Interpreter" => (is => "rw", isa => "Maybe[Str]");
has "Timer" => (is => "rw", isa => "Bool");
has "Verbose" => (is => "rw", isa => "Bool");

sub _get_new_strap
{
    my $self = shift;

    return $self->create_pluggable_helper_obj(
        {
            id => "straps",
            args => {},
        }
    );
}

=head2 BUILD

For Moose.

=cut

sub BUILD
{
    my $self = shift;

    $self->register_pluggable_helper(
        {
            id => "straps",
            base => "Test::Run::Straps",
            collect_plugins_method => "private_straps_plugins",
        },
    );

    $self->register_pluggable_helper(
        {
            id => "failed",
            base => "Test::Run::Obj::FailedObj",
            collect_plugins_method => "private_failed_obj_plugins",
        },
    );

    $self->register_pluggable_helper(
        {
            id => "test",
            base => "Test::Run::Obj::TestObj",
            collect_plugins_method => "private_test_obj_plugins",
        },
    );

    $self->register_pluggable_helper(
        {
            id => "tot",
            base => "Test::Run::Obj::TotObj",
            collect_plugins_method => "private_tot_obj_plugins",
        },
    );

    $self->register_pluggable_helper(
        {
            id => "canon_failed",
            base => "Test::Run::Obj::CanonFailedObj",
            collect_plugins_method => "private_canon_failed_obj_plugins",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "fail_other_except",
            format => "Failed %(_get_fail_test_scripts_string)s%(_get_fail_tests_good_percent_string)s.%(_get_sub_percent_msg)s\n"
        },
    );

    return 0;
}

=head2 $self->helpers_base_namespace()

See L<Test::Run::Base::PlugHelpers>.

=cut

sub helpers_base_namespace
{
    my $self = shift;

    return "Test::Run::Core::__HelperObjects";
}

=head2 Object Parameters

These parameters are accessors. They can be set at object creation by passing
their name along with a value on the constructor (along with the compulsory
C<'test_files'> argument):

    my $tester = Test::Run::Obj->new(
        {
            'test_files' => \@mytests,
            'Verbose' => 1,
        }
    );

Alternatively, before C<runtests()> is called, they can be set by passing a
value to their accessor:

    $tester->Verbose(1);

=over 4

=item C<$self-E<gt>Verbose()>

The object variable C<$self-E<gt>Verbose()> can be used to let C<runtests()>
display the standard output of the script without altering the behavior
otherwise.  The F<runprove> utility's C<-v> flag will set this.

=item C<$self-E<gt>Leaked_Dir()>

When set to the name of a directory, C<$tester> will check after each
test whether new files appeared in that directory, and report them as

  LEAKED FILES: scr.tmp 0 my.db

If relative, directory name is with respect to the current directory at
the moment C<$tester-E<gt>runtests()> was called.  Putting the absolute path
into C<Leaked_Dir> will give more predictable results.

=item C<$self-E<gt>Debug()>

If C<$self-E<gt>Debug()> is true, Test::Run will print debugging information
about itself as it runs the tests.  This is different from
C<$self-E<gt>Verbose()>, which prints the output from the test being run.

=item C<$self-E<gt>Columns()>

This value will be used for the width of the terminal. If it is not
set then it will default to 80.

=item C<$self-E<gt>Timer()>

If set to true, and C<Time::HiRes> is available, print elapsed seconds
after each test file.

=item C<$self-E<gt>NoTty()>

When set to a true value, forces it to behave as though STDOUT were
not a console.  You may need to set this if you don't want harness to
output more frequent progress messages using carriage returns.  Some
consoles may not handle carriage returns properly (which results in a
somewhat messy output).

=item C<$self-E<gt>Test_Interprter()>

Usually your tests will be run by C<$^X>, the currently-executing Perl.
However, you may want to have it run by a different executable, such as
a threading perl, or a different version.

=item C<$self-E<gt>Switches()> and C<$self-E<gt>Switches_Env()>

These two values will be prepended to the switches used to invoke perl on
each test.  For example, setting one of them to C<-W> will
run all tests with all warnings enabled.

The difference between them is that C<Switches_Env()> is expected to be
filled in by the environment and C<Switches()> from other sources (like the
programmer).

=back

=head2 METHODS

Test::Run currently has only one interface method.

=head2 $tester->runtests()

    my $all_ok = $tester->runtests()

Runs the tests, see if they are OK. Returns true if they are OK, or
throw an exception otherwise.

=cut

=head2 $self->_report_leaked_files({leaked_files => [@files]})

[This is a method that needs to be over-rided.]

Should report (or ignore) the files that were leaked in the directories
that were specifies as leaking directories.

=cut

=head2 $self->_report_failed_with_results_seen({%args})

[This is a method that needs to be over-rided.]

Should report (or ignore) the failed tests in the test file.

Arguments are:

=over 4

=item * test_struct

The test struct as returned by straps.

=item * filename

The filename

=item * estatus

Exit status.

=item * wstatus

Wait status.

=item * results

The results of the test.

=back

=cut

=head2 $self->_recheck_dir_files()

Called to recheck that the dir files is OK.

=cut

sub _recheck_dir_files
{
    my $self = shift;

    if (defined($self->Leaked_Dir()))
    {
        return $self->_real_recheck_dir_files();
    }
}

sub _calc_leaked_files_since_last_update
{
    my $self = shift;

    my %found;

    @found{@{$self->_new_dir_files()}} = (1) x @{$self->_new_dir_files()};

    delete(@found{@{$self->dir_files()}});

    return [sort keys(%found)];
}

sub _real_recheck_dir_files
{
    my $self = shift;

    $self->_new_dir_files($self->_get_dir_files());

    $self->_report_leaked_files(
        {
            leaked_files => $self->_calc_leaked_files_since_last_update()
        }
    );
    $self->_update_dir_files();
}

sub _update_dir_files
{
    my $self = shift;

    $self->dir_files($self->_new_dir_files());

    # Reset it to prevent dangerous behaviour.
    $self->_new_dir_files(undef);

    return;
}

sub _glob_dir
{
    my ($self, $dirname) = @_;

    my $dir;
    opendir $dir, $dirname;
    my @contents = readdir($dir);
    closedir($dir);

    return [File::Spec->no_upwards(@contents)];
}

sub _get_num_tests_files
{
    my $self = shift;

    return scalar(@{$self->test_files()});
}

sub _get_tot_counter_tests
{
    my $self = shift;

    return [ tests => $self->_get_num_tests_files() ];
}

sub _init_tot_obj_instance
{
    my $self = shift;
    return $self->create_pluggable_helper_obj(
        {
            id => "tot",
            args => { @{$self->_get_tot_counter_tests()} },
        }
    );
}

sub _init_tot
{
    my $self = shift;
    $self->tot(
        $self->_init_tot_obj_instance()
    );
}

sub _tot_inc
{
    my ($self, $field) = @_;

    $self->tot()->inc($field);
}

sub _tot_add_results
{
    my ($self, $results) = @_;

    return $self->tot->add_results($results);
}

sub _create_failed_obj_instance
{
    my $self = shift;
    my $args = shift;
    return $self->create_pluggable_helper_obj(
        {
            id => "failed",
            args => $args,
        }
    );
}

sub _create_test_obj_instance
{
    my ($self, $args) = @_;
    return $self->create_pluggable_helper_obj(
        {
            id => "test",
            args => $args,
        }
    );
}

sub _is_failed_and_max
{
    my $self = shift;

    return $self->last_test_obj->is_failed_and_max();
}

sub _strap_test_handler
{
    my ($self, $args) = @_;

    $args->{totals}->update_based_on_last_detail();

    $self->_report_test_progress($args);

    return;
}

sub _strap_header_handler
{
    my ($self, $args) = @_;

    my $totals = $args->{totals};

    if ($self->Strap()->_seen_header())
    {
        warn "Test header seen more than once!\n";
    }

    $self->Strap()->_inc_seen_header();

    if ($totals->in_the_middle())
    {
        warn "1..M can only appear at the beginning or end of tests\n";
    }

    return;
}


sub _tap_event_strap_callback
{
    my ($self, $args) = @_;

    $self->_report_tap_event($args);

    return $self->_tap_event_handle_strap($args);
}

sub _tap_event__calc_conds
{
    my $self = shift;

    return
    [
        { cond => "is_plan", handler => "_strap_header_handler", },
        { cond => "is_bailout", handler => "_strap_bailout_handler", },
        { cond => "is_test", handler => "_strap_test_handler"},
    ];
}

sub _tap_event_handle_strap
{
    my ($self, $args) = @_;
    my $event = $args->{event};

    foreach my $c (@{$self->_tap_event__calc_conds()})
    {
        my $cond = $c->{cond};
        my $handler = $c->{handler};

        if ($event->$cond())
        {
            return $self->$handler($args);
        }
    }
    return;
}

=begin _private

=over 4

=item B<_all_ok>

    my $ok = $self->_all_ok();

Tells you if the current test run is OK or not.

=cut

sub _all_ok
{
    my $self = shift;
    return $self->tot->all_ok();
}

=back

=cut

sub _get_dir_files
{
    my $self = shift;

    return $self->_glob_dir($self->Leaked_Dir());
}

sub _calc_strap_callback_map
{
    return
    {
        "tap_event"        => "_tap_event_strap_callback",
        "report_start_env" => "_report_script_start_environment",
        "could_not_run_script" => "_report_could_not_run_script",
        "test_file_opening_error" => "_handle_test_file_opening_error",
        "test_file_closing_error" => "_handle_test_file_closing_error",
    };
}

sub _strap_callback
{
    my ($self, $args) = @_;

    my $type = $args->{type};
    my $cb = $self->_calc_strap_callback_map()->{$type};

    return $self->$cb($args);
}

sub _inc_bad
{
    my $self = shift;

    $self->_tot_inc('bad');

    return;
}

sub _ser_failed_results
{
    my $self = shift;

    return $self->_canonfailed()->get_ser_results();
}

sub _get_current_time
{
    my $self = shift;

    return Time::HiRes::time();
}

sub _set_start_time
{
    my $self = shift;

    if ($self->Timer())
    {
        $self->_start_time($self->_get_current_time());
    }
}

sub _get_failed_with_results_seen_msg
{
    my $self = shift;

    return
        $self->_is_failed_and_max()
            ? $self->_get_failed_and_max_msg()
            : $self->_get_dont_know_which_tests_failed_msg()
            ;
}

sub _get_dont_know_which_tests_failed_msg
{
    my $self = shift;

    return $self->last_test_obj->_get_dont_know_which_tests_failed_msg();
}

sub _get_elapsed
{
    my $self = shift;

    if ($self->Timer())
    {
        return sprintf(" %8.3fs",
            $self->_get_current_time() - $self->_start_time()
        );
    }
    else
    {
        return "";
    }
}

sub _set_last_test_elapsed
{
    my $self = shift;

    $self->last_test_elapsed($self->_get_elapsed());
}

sub _get_copied_strap_fields
{
    return [qw(Debug Test_Interpreter Switches Switches_Env)];
}

sub _init_strap
{
    my ($self, $args) = @_;

    $self->Strap()->copy_from($self, $self->_get_copied_strap_fields());
}

sub _get_sub_percent_msg
{
    my $self = shift;

    return $self->tot->get_sub_percent_msg();
}

sub _handle_passing_test
{
    my $self = shift;

    $self->_process_passing_test();
    $self->_tot_inc('good');
}

sub _does_test_have_some_oks
{
    my $self = shift;

    return $self->last_test_obj->max();
}

sub _process_passing_test
{
    my $self = shift;

    if ($self->_does_test_have_some_oks())
    {
        $self->_process_test_with_some_oks();
    }
    else
    {
        $self->_process_all_skipped_test();
    }
}

sub _process_test_with_some_oks
{
    my $self = shift;

    if ($self->last_test_obj->skipped_or_bonus())
    {
        return $self->_process_skipped_test();
    }
    else
    {
        return $self->_process_all_ok_test();
    }
}

sub _process_all_ok_test
{
    my ($self) = @_;
    return $self->_report_all_ok_test();
}

sub _process_all_skipped_test
{
    my $self = shift;

    $self->_report_all_skipped_test();
    $self->_tot_inc('skipped');

    return;
}

sub _fail_other_get_script_names
{
    my $self = shift;

    return [ sort { $a cmp $b } (keys(%{$self->failed_tests()})) ];
}

sub _fail_other_print_all_tests
{
    my $self = shift;

    for my $script (@{$self->_fail_other_get_script_names()})
    {
        $self->_fail_other_report_test($script);
    }
}

sub _fail_other_throw_exception
{
    my $self = shift;

    die Test::Run::Obj::Error::TestsFail::Other->new(
        {text => $self->_get_fail_other_exception_text(),},
    );
}

sub _process_skipped_test
{
    my ($self) = @_;

    return $self->_report_skipped_test();
}



sub _time_single_test
{
    my ($self, $args) = @_;

    $self->_set_start_time($args);

    $self->_init_strap($args);

    $self->Strap->callback(sub { return $self->_strap_callback(@_); });

    # We trap exceptions so we can nullify the callback to avoid memory
    # leaks.
    my $results;
    eval
    {
        if (! ($results = $self->Strap()->analyze_file($args->{test_file})))
        {
            do
            {
                warn $self->Strap()->error(), "\n";
                next;
            }
        }
    };

    # To avoid circular references
    $self->Strap->callback(undef);

    if ($@ ne "")
    {
        die $@;
    }
    $self->_set_last_test_elapsed($args);

    $self->last_test_results($results);

    return;
}

sub _fail_no_tests_output
{
    my $self = shift;
    die Test::Run::Obj::Error::TestsFail::NoOutput->new(
        {text => $self->_get_fail_no_tests_output_text(),},
    );
}

sub _failed_canon
{
    my $self = shift;

    return $self->_canonfailed()->canon();
}

sub _get_failed_and_max_msg
{
    my $self = shift;

    return   $self->last_test_obj->ml()
           . $self->_ser_failed_results();
}

sub _canonfailed
{
    my $self = shift;

    my $canon_obj = $self->_canonfailed_get_canon();

    $canon_obj->add_Failed_and_skipped($self->last_test_obj);

    return $canon_obj;
    # Originally returning get_ser_results, canon
}


sub _filter_failed
{
    my ($self, $failed_ref) = @_;
    return [ List::MoreUtils::uniq(sort { $a <=> $b } @$failed_ref) ];
}

sub _canonfailed_get_failed
{
    my $self = shift;

    return $self->_filter_failed($self->_get_failed_list());
}

=head2 $self->_calc_test_struct_ml($results)

Calculates the ml(). (See L<Test::Run::Output>) for the test.

=cut

sub _calc_test_struct_ml
{
    my $self = shift;

    return "";
}

sub _calc_last_test_obj_params
{
    my $self = shift;

    my $results = $self->last_test_results;

    return
    [
        (
            map { $_ => $results->$_(), }
            (qw(bonus max ok skip_reason skip_all))
        ),
        skipped => $results->skip(),
        'next' => $self->Strap->next_test_num(),
        failed => $results->_get_failed_details(),
        ml => $self->_calc_test_struct_ml($results),
    ];
}

sub _get_fail_no_tests_run_text
{
    return "FAILED--no tests were run for some reason.\n"
}

sub _get_fail_no_tests_output_text
{
    my $self = shift;

    return $self->tot->_get_fail_no_tests_output_text();
}

sub _get_success_msg
{
    my $self = shift;
    return "All tests successful" . $self->_get_bonusmsg() . ".";
}

sub _fail_no_tests_run
{
    my $self = shift;
    die Test::Run::Obj::Error::TestsFail::NoTestsRun->new(
        {text => $self->_get_fail_no_tests_run_text(),},
    );
}

sub _calc_test_struct
{
    my $self = shift;

    my $results = $self->last_test_results;

    $self->_tot_add_results($results);

    return $self->last_test_obj(
        $self->_create_test_obj_instance(
            {
                @{$self->_calc_last_test_obj_params()},
            }
        )
    );
}

sub _get_failed_list
{
    my $self = shift;

    return $self->last_test_obj->failed;
}

sub _get_premature_test_dubious_summary
{
    my $self = shift;

    $self->last_test_obj->add_next_to_failed();

    $self->_report_premature_test_dubious_summary();

    return $self->_get_failed_and_max_params();
}

sub _failed_before_any_test_output
{
    my $self = shift;

    $self->_report_failed_before_any_test_output();

    $self->_inc_bad();

    return $self->_calc_failed_before_any_test_obj();
}

sub _max_len
{
    my ($self, $array_ref) = @_;

    return List::Util::max(map { length($_) } @$array_ref);
}

# TODO : Add _leader_width here.


sub _get_fn_fn
{
    my ($self, $fn) = @_;

    return $fn;
}

sub _get_fn_ext
{
    my ($self, $fn) = @_;

    return (($fn =~ /\.(\w+)\z/) ? $1 : "");
}

sub _get_filename_map_max_len
{
    my ($self, $cb) = @_;

    return $self->_max_len(
        [ map { $self->$cb($self->_get_test_file_display_path($_)) }
          @{$self->test_files()}
        ]
    );
}

sub _get_max_ext_len
{
    my $self = shift;

    return $self->_get_filename_map_max_len("_get_fn_ext");
}

sub _get_max_filename_len
{
    my $self = shift;

    return $self->_get_filename_map_max_len("_get_fn_fn");
}

=head2 $self->_leader_width()

Calculates how long the leader should be based on the length of the
maximal test filename.

=cut

sub _leader_width
{
    my $self = shift;

    return $self->_get_max_filename_len() + 3 - $self->_get_max_ext_len();
}

sub _strap_bailout_handler
{
    my ($self, $args) = @_;

    die Test::Run::Obj::Error::TestsFail::Bailout->new(
        {
            bailout_reason => $self->Strap->bailout_reason(),
            text => "FOOBAR",
        }
    );
}

sub _calc_failed_before_any_test_obj
{
    my $self = shift;

    return $self->_create_failed_obj_instance(
        {
            (map
                { $_ => Test::Run::Obj::IntOrUnknown->create_unknown() }
                qw(max failed)
            ),
            canon => "??",
            (map { $_ => "", } qw(estat wstat)),
            percent => undef,
            name => $self->_get_last_test_filename(),
        },
    );
}

sub _show_results
{
    my($self) = @_;

    $self->_show_success_or_failure();

    $self->_report_final_stats();
}

sub _is_last_test_seen
{
    return shift->last_test_results->seen;
}

sub _is_test_passing
{
    my $self = shift;

    return $self->last_test_results->passing;
}

sub _get_failed_and_max_params
{
    my $self = shift;

    my $last_test = $self->last_test_obj;

    return
    [
        canon => $self->_failed_canon(),
        failed => Test::Run::Obj::IntOrUnknown->create_int($last_test->num_failed()),
        percent => $last_test->calc_percent(),
    ];
}

# The test program exited with a bad exit status.
sub _dubious_return
{
    my $self = shift;

    $self->_report_dubious();

    $self->_inc_bad();

    return $self->_calc_dubious_return_ret_value();
}

sub _get_fail_test_scripts_string
{
    my $self = shift;

    return $self->tot->fail_test_scripts_string();
}

sub _get_undef_tests_params
{
    my $self = shift;

    return
    [
        canon => "??",
        failed => Test::Run::Obj::IntOrUnknown->create_unknown(),
        percent => undef,
    ];
}

sub _get_fail_tests_good_percent_string
{
    my $self = shift;

    return $self->tot->fail_tests_good_percent_string();
}

sub _get_FWRS_tests_existence_params
{
    my ($self) = @_;

    return
        [
            $self->_is_failed_and_max()
            ? (@{$self->_get_failed_and_max_params()})
            : (@{$self->_get_undef_tests_params()})
        ]
}

sub _handle_runtests_error_text
{
    my $self = shift;
    my $args = shift;

    my $text = $args->{'text'};

    die $text;
}

sub _is_error_object
{
    my $self = shift;
    my $error = shift;

    return
    (
        Scalar::Util::blessed($error) &&
        $error->isa("Test::Run::Obj::Error::TestsFail")
    );
}

sub _get_runtests_error_text
{
    my $self = shift;
    my $error = shift;

    return
        ($self->_is_error_object($error)
            ? $error->stringify()
            : $error
        );
}

sub _is_no_tests_run
{
    my $self = shift;

    return (! $self->tot->tests());
}

sub _is_no_tests_output
{
    my $self = shift;

    return (! $self->tot->max());
}

sub _report_success
{
    my $self = shift;
    $self->_report(
        {
            'channel' => "success",
            'event' => { 'type' => "success", },
        }
    );

    return;
}

sub _fail_other_if_bad
{
    my $self = shift;

    if ($self->tot->bad)
    {
        $self->_fail_other_print_bonus_message();
        $self->_fail_other_throw_exception();
    }

    return;
}

sub _calc__fail_other__callbacks
{
    my $self = shift;

    return [qw(
        _create_fmts
        _fail_other_print_top
        _fail_other_print_all_tests
        _fail_other_if_bad
    )];
}

sub _fail_other
{
    shift->_run_sequence();

    return;
}

sub _show_success_or_failure
{
    my $self = shift;

    if ($self->_all_ok())
    {
        return $self->_report_success();
    }
    elsif ($self->_is_no_tests_run())
    {
        return $self->_fail_no_tests_run();
    }
    elsif ($self->_is_no_tests_output())
    {
        return $self->_fail_no_tests_output();
    }
    else
    {
        return $self->_fail_other();
    }
}

sub _handle_runtests_error
{
    my $self = shift;
    my $args = shift;
    my $error = $args->{'error'};

    $self->_handle_runtests_error_text(
        {
            'text' => $self->_get_runtests_error_text($error),
        },
    );
}

sub _get_canonfailed_params
{
    my $self = shift;

    return [failed => $self->_canonfailed_get_failed(),];
}

sub _create_canonfailed_obj_instance
{
    my ($self, $args) = @_;

    return $self->create_pluggable_helper_obj(
        {
            id => "canon_failed",
            args => $args,
        }
    );
}

sub _canonfailed_get_canon
{
    my ($self) = @_;

    return $self->_create_canonfailed_obj_instance(
        {
            @{$self->_get_canonfailed_params()},
        }
    );
}

sub _prepare_for_single_test_run
{
    my ($self, $args) = @_;

    $self->_tot_inc('files');

    $self->Strap()->_seen_header(0);

    $self->_report_single_test_file_start($args);

    return;
}


sub _calc__run_single_test__callbacks
{
    my $self = shift;

    return [qw(
        _prepare_for_single_test_run
        _time_single_test
        _calc_test_struct
        _process_test_file_results
        _recheck_dir_files
    )];
}

sub _run_single_test
{
    my ($self, $args) = @_;

    $self->_run_sequence([$args]);

    return;
}

sub _list_tests_as_failures
{
    my $self = shift;

    return
        $self->last_test_obj->list_tests_as_failures(
            $self->last_test_results->details()
        );
}

sub _process_test_file_results
{
    my ($self) = @_;

    if ($self->_is_test_passing())
    {
        $self->_handle_passing_test();
    }
    else
    {
        $self->_list_tests_as_failures();
        $self->_add_to_failed_tests();
    }

    return;
}

sub _check_for_ok
{
    my $self = shift;

    assert( ($self->_all_ok() xor keys(%{$self->failed_tests()})),
            q{$ok is mutually exclusive with %$failed_tests}
        );

    return;

}

sub _calc_test_file_data_display_path
{
    my ($self, $idx, $test_file) = @_;

    return $test_file;
}

sub _get_test_file_display_path
{
    my ($self, $test_file) = @_;

    return $self->test_files_data()->{$test_file}->{display_path};
}

sub _calc_test_file_data_struct
{
    my ($self, $idx, $test_file) = @_;

    return
    {
        idx => $idx,
        real_path => $test_file,
        display_path => $self->_calc_test_file_data_display_path($idx, $test_file),
    };
}

sub _prepare_test_files_data
{
    my $self = shift;

    foreach my $idx (0 .. $#{$self->test_files()})
    {
        my $test_file = $self->test_files()->[$idx];

        $self->test_files_data()->{$test_file} =
            $self->_calc_test_file_data_struct($idx, $test_file);
    }
}

sub _calc__real_runtests__callbacks
{
    my $self = shift;

    return
    [qw(
        _run_all_tests
        _show_results
        _check_for_ok
    )];
}

sub _real_runtests
{
    shift->_run_sequence();

    return;
}

sub runtests
{
    my $self = shift;

    local ($\, $,);

    eval { $self->_real_runtests(@_) };

    my $error = $@;

    my $ok = $self->_all_ok();

    if ($error)
    {
        return $self->_handle_runtests_error(
            {
                ok => $ok,
                error => $error,
            }
        );
    }
    else
    {
        return $ok;
    }
}

sub _get_bonusmsg
{
    my $self = shift;

    if (! defined($self->_bonusmsg()))
    {
        $self->_bonusmsg($self->tot()->get_bonusmsg());
    }

    return $self->_bonusmsg();
}

sub _autoflush_file_handles
{
    my $self = shift;

    STDOUT->autoflush(1);
    STDERR->autoflush(1);
}

sub _init_failed_tests
{
    my $self = shift;

    $self->failed_tests({});
}

sub _prepare_run_all_tests
{
    my $self = shift;

    $self->_prepare_test_files_data();

    $self->_autoflush_file_handles();

    $self->_init_failed_tests();

    $self->_init_tot();

    $self->_init_dir_files();

    return;
}

# FWRS == failed_with_results_seen
sub _get_common_FWRS_params
{
    my $self = shift;

    return
    [
        max => Test::Run::Obj::IntOrUnknown->create_int(
            $self->last_test_obj->max()
        ),
        name => $self->_get_last_test_filename(),
        estat => "",
        wstat => "",
        list_len => $self->list_len(),
    ];
}

sub _get_failed_with_results_seen_params
{
    my ($self) = @_;

    return
        {
            @{$self->_get_common_FWRS_params()},
            @{$self->_get_FWRS_tests_existence_params()},
        }
}

sub _failed_with_results_seen
{
    my $self = shift;

    $self->_inc_bad();

    $self->_report_failed_with_results_seen();

    return
        $self->_create_failed_obj_instance(
            $self->_get_failed_with_results_seen_params(),
        );
}

sub _get_failed_struct
{
    my ($self) = @_;

    if ($self->_get_wstatus())
    {
         return $self->_dubious_return();
    }
    elsif($self->_is_last_test_seen())
    {
        return $self->_failed_with_results_seen();
    }
    else
    {
        return $self->_failed_before_any_test_output();
    }
}

sub _add_to_failed_tests
{
    my $self = shift;

    $self->failed_tests()->{$self->_get_last_test_filename()} =
        $self->_get_failed_struct();

    return;
}

sub _get_last_test_filename
{
    my $self = shift;

    return $self->last_test_results->filename();
}

sub _init_dir_files
{
    my $self = shift;

    if (defined($self->Leaked_Dir()))
    {
        $self->dir_files($self->_get_dir_files());
    }
}

sub _run_all_tests_loop
{
    my $self = shift;

    foreach my $test_file_path (@{$self->test_files()})
    {
        $self->_run_single_test({ test_file => $test_file_path});
    }
}

sub _run_all_tests__run_loop
{
    my $self = shift;

    $self->tot->benchmark_callback(
        sub {
            $self->width($self->_leader_width());
            $self->_run_all_tests_loop();
        }
    );
}

sub _finalize_run_all_tests
{
    my $self = shift;

    $self->Strap()->_restore_PERL5LIB();
}

sub _calc__run_all_tests__callbacks
{
    my $self = shift;

    return
    [qw(
        _prepare_run_all_tests
        _run_all_tests__run_loop
        _finalize_run_all_tests
    )];
}

sub _run_all_tests {
    shift->_run_sequence();

    return;
}


sub _get_dubious_summary_all_subtests_successful
{
    my ($self, $args) = @_;

    $self->_report_dubious_summary_all_subtests_successful();

    return
    [
        failed => Test::Run::Obj::IntOrUnknown->zero(),
        percent => 0,
        canon => "??",
    ];
}

sub _get_no_tests_summary
{
    my ($self, $args) = @_;

    return
    [
        failed => Test::Run::Obj::IntOrUnknown->create_unknown(),
        canon => "??",
        percent => undef(),
    ];
}

sub _get_dubious_summary
{
    my ($self, $args) = @_;

    my $method = $self->last_test_obj->get_dubious_summary_main_obj_method();

    return $self->$method($args);
}

sub _get_skipped_bonusmsg
{
    my $self = shift;

    return $self->tot->_get_skipped_bonusmsg();
}

sub _get_wstatus
{
    my $self = shift;

    return $self->last_test_results->wait;
}

sub _get_estatus
{
    my $self = shift;

    return $self->last_test_results->exit;
}

sub _get_format_failed_str
{
    my $self = shift;

    return "Failed Test";
}

sub _get_format_failed_str_len
{
    my $self = shift;

    return length($self->_get_format_failed_str());
}

sub _get_num_columns
{
    my $self = shift;

    # Some shells don't handle a full line of text well so we increment
    # 1.
    return ($self->Columns() - 1);
}

# Find the maximal name length among the failed_tests().
sub _calc_initial_max_namelen
{
    my $self = shift;

    my $max = $self->_get_format_failed_str_len();

    while (my ($k, $v) = each(%{$self->failed_tests()}))
    {
        my $l = length($v->{name});

        if ($l > $max)
        {
            $max = $l;
        }
    }

    $self->max_namelen($max);

    return;
}

sub _calc_len_subtraction
{
    my ($self, $field) = @_;

    return $self->format_columns()
         - $self->_get_fmt_mid_str_len()
         - $self->$field()
         ;
}

sub _calc_initial_list_len
{
    my $self = shift;

    $self->format_columns($self->_get_num_columns());

    $self->list_len(
        $self->_calc_len_subtraction("max_namelen")
    );

    return;
}

sub _calc_updated_lens
{
    my $self = shift;

    $self->list_len($self->_get_fmt_list_str_len);
    $self->max_namelen($self->_calc_len_subtraction("list_len"));
}

sub _calc_more_updated_lens
{
    my $self = shift;

    $self->max_namelen($self->_get_format_failed_str_len());

    $self->format_columns(
          $self->max_namelen()
        + $self->_get_fmt_mid_str_len()
        + $self->list_len()
    );
}

sub _calc_fmt_list_len
{
    my $self = shift;

    $self->_calc_initial_list_len();

    if ($self->list_len() < $self->_get_fmt_list_str_len()) {
        $self->_calc_updated_lens();
        if ($self->max_namelen() < $self->_get_format_failed_str_len())
        {
            $self->_calc_more_updated_lens();
        }
    }

    return;
}

sub _calc_format_widths
{
    my $self = shift;

    $self->_calc_initial_max_namelen();

    $self->_calc_fmt_list_len();

    return;
}

sub _get_format_middle_str
{
    my $self = shift;

    return " Stat Wstat Total Fail  Failed  ";
}

sub _get_fmt_mid_str_len
{
    my $self = shift;

    return length($self->_get_format_middle_str());
}

sub _get_fmt_list_str_len
{
    my $self = shift;

    return length($self->_get_format_list_str());
}

sub _get_format_list_str
{
    my $self = shift;

    return "List of Failed";
}

sub _create_fmts
{
    my $self = shift;

    $self->_calc_format_widths();

    return;
}

sub _get_fail_other_exception_text
{
    my $self = shift;

    return $self->_format_self("fail_other_except");
}

sub _calc_dubious_return_ret_value
{
    my $self = shift;

    return $self->_create_failed_obj_instance(
        $self->_calc_dubious_return_failed_obj_params(),
    );
}

sub _calc_dubious_return_failed_obj_params
{
    my $self = shift;

    return
    {
        @{$self->_get_dubious_summary()},
        @{$self->last_test_obj->get_failed_obj_params()},
        @{$self->last_test_results->get_failed_obj_params()},
    };
}

=head2 $self->_report_failed_before_any_test_output();

[This is a method that needs to be over-rided.]

=cut

=head2 $self->_report_skipped_test()

[This is a method that needs to be over-rided.]

Should report the skipped test.

=cut

=head2 $self->_report_all_ok_test()

[This is a method that needs to be over-rided.]

Should report the all OK test.

=cut

=head2 $self->_report_all_skipped_test()

[This is a method that needs to be over-rided.]

Should report the all-skipped test.

=cut

=head2 $self->_report_single_test_file_start({test_file => "t/my_test_file.t"})

[This is a method that needs to be over-rided.]

Should start the report for the C<test_file> file.

=cut

=head2 $self->_report('channel' => $channel, 'event' => $event_handle);

[This is a method that needs to be over-rided.]

Reports the C<$event_handle> event to channel C<$channel>. This should be
overrided by derived classes to do alternate functionality besides calling
output()->print_message(), also different based on the channel.

Currently available channels are:

=over 4

=item 'success'

The success report.

=back

An event is a hash ref that should contain a 'type' property. Currently
supported types are:

=over 4

=item * success

A success type.

=back

=cut

=head2 $self->_report_final_stats()

[This is a method that needs to be over-rided.]

Reports the final statistics.

=cut

=head2 $self->_fail_other_print_top()

[This is a method that needs to be over-rided.]

Prints the header of the files that failed.

=cut

=head2 $self->_fail_other_report_test($script_name)

[This is a method that needs to be over-rided.]

In case of failure from a different reason - report that test script.
Test::Run iterates over all the scripts and reports them one by one.

=cut


=head2 $self->_fail_other_print_bonus_message()

[This is a method that needs to be over-rided.]

Should report the bonus message in case of failure from a different
reason.

=cut

=head2 $self->_report_tap_event($args)

[This is a method that needs to be over-rided.]

=head2 $self->_report_script_start_environment()

[This is a method that needs to be over-rided.]

Should report the environment of the script at its beginning.

=head2 $self->_handle_test_file_opening_error($args)

[This is a method that needs to be over-rided.]

Should handle the case where the test file cannot be opened.

=cut

=head2 $self->_report_test_progress($args)

[This is a method that needs to be over-rided.]

Report the text progress. In the command line it would be a ok $curr/$total
or NOK.

=cut
=head2 The common test-context $args param

Contains:

=over 4

=item 'test_struct' => $test

A reference to the test summary object.

=item estatus

The exit status of the test file.

=back

=head2 $test_run->_report_dubious($args)

[This is a method that needs to be over-rided.]

Is called to report the "dubious" error, when the test returns a non-true
error code.

$args are the test-context - see above.

=cut

=head2 $test_run->_report_dubious_summary_all_subtests_successful($args)

[This is a method that needs to be over-rided.]

$args are the test-context - see above.

=head2 $test_run->_report_premature_test_dubious_summary($args)

[This is a method that needs to be over-rided.]

$args are the test-context - see above.

=head2 opendir

This method is placed in the namespace by Fatal.pm. This entry is here just
to settle Pod::Coverage.

=cut

1;

=head1 AUTHOR

Test::Run::Core is based on L<Test::Harness>, and has later been spinned off
as a separate module.

=head2 Test:Harness Authors

Either Tim Bunce or Andreas Koenig, we don't know. What we know for
sure is, that it was inspired by Larry Wall's TEST script that came
with perl distributions for ages. Numerous anonymous contributors
exist.  Andreas Koenig held the torch for many years, and then
Michael G Schwern.

Test::Harness was then maintained by Andy Lester C<< <andy at petdance.com> >>.

=head2 Test::Run::Obj Authors

Shlomi Fish, L<http://www.shlomifish.org/> .

Note: this file is a rewrite of the original Test::Run code in order to
change to a more liberal license.

=head1 LICENSE

This file is licensed under the MIT License:

http://www.opensource.org/licenses/mit-license.php

=cut
