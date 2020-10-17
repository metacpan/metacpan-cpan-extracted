package Test::Run::Straps;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.0305';

=head1 NAME

Test::Run::Straps - analyse the test results by using TAP::Parser.

=head1 METHODS

=cut

use Moose;

use MRO::Compat;

extends('Test::Run::Straps::Base');

use Config;

use IPC::System::Simple qw( capturex );

use TAP::Parser;

use Test::Run::Straps::EventWrapper;
use Test::Run::Straps::StrapsTotalsObj;

use Test::Run::Obj::Error;

has 'bailout_reason' => (is => "rw", isa => "Str");
has 'callback' => (is => "rw", isa => "Maybe[CodeRef]");
has 'Debug' => (is => "rw", isa => "Bool");
has 'error' => (is => "rw", isa => "Any");
has 'exception' => (is => "rw", isa => "Any");
has 'file' => (is => "rw", isa => "Str");
has '_file_totals' =>
    (is => "rw", isa => "Test::Run::Straps::StrapsTotalsObj");
has '_is_macos' => (is => "rw", isa => "Bool",
    default => sub { return ($^O eq "MacOS"); },
);
has '_is_win32' => (is => "rw", isa => "Bool",
    default => sub { return ($^O =~ m{\A(?:MS)?Win32\z}); },
);
has '_is_vms' => (is => "rw", isa => "Bool",
    default => sub { return ($^O eq "VMS"); },
);
has 'last_test_print' => (is => "rw", isa => "Bool");
has 'next_test_num' => (is => "rw", isa => "Num");
has '_old5lib' => (is => "rw", isa => "Maybe[Str]");
has '_parser' => (is => "rw", isa => "Maybe[TAP::Parser]");
has 'results' =>
    (is => "rw", isa => "Test::Run::Straps::StrapsTotalsObj");
has 'saw_bailout' => (is => "rw", isa => "Bool");
has 'saw_header' => (is => "rw", isa => "Bool");
has '_seen_header' => (is => "rw", isa => "Num");
has 'Switches' => (is => "rw", isa => "Maybe[Str]");
has 'Switches_Env' => (is => "rw", isa => "Maybe[Str]");
has 'Test_Interpreter' => (is => "rw", isa => "Maybe[Str]");
has 'todo' => (is => "rw", isa => "HashRef", default => sub { +{} },);
has 'too_many_tests' => (is => "rw", isa => "Bool");
has 'totals' =>
    (is => "rw", isa => "HashRef", default => sub { +{} },);


=head2 my $strap = Test::Run::Straps->new();

Initialize a new strap.

=cut

sub _start_new_file
{
    my $self = shift;

    $self->_reset_file_state;
    my $totals =
        $self->_init_totals_obj_instance(
            $self->_get_initial_totals_obj_params(),
        );

    $self->_file_totals($totals);

    # Set them up here so callbacks can have them.
    $self->totals()->{$self->file()}         = $totals;

    return;
}

sub _calc_next_event
{
    my $self = shift;

    my $event = scalar($self->_parser->next());

    if (defined($event))
    {
        return
            Test::Run::Straps::EventWrapper->new(
                {
                    event => $event,
                },
            );
    }
    else
    {
        return undef;
    }
}

sub _get_next_event
{
    my ($self) = @_;

    return $self->_event($self->_calc_next_event());
}

sub _get_event_types_cascade
{
    return [qw(test plan bailout comment)];
}

=head2 $strap->_inc_seen_header()

Increment the _seen_header field. Used by L<Test::Run::Core>.

=cut

sub _inc_seen_header
{
    my $self = shift;

    $self->inc_field('_seen_header');

    return;
}

sub _inc_saw_header
{
    my $self = shift;

    $self->inc_field('saw_header');

    return;
}

sub _plan_set_max
{
    my $self = shift;

    $self->_file_totals->max($self->_event->tests_planned());

    return;
}

sub _handle_plan_skip_all
{
    my $self = shift;

    # If it's a skip-all line.
    if ($self->_event->tests_planned() == 0)
    {
        $self->_file_totals->skip_all($self->_event->explanation());
    }

    return;
}

sub _calc__handle_plan_event__callbacks
{
    my $self = shift;

    return [qw(
        _inc_saw_header
        _plan_set_max
        _handle_plan_skip_all
        )];
}

sub _handle_plan_event
{
    shift->_run_sequence();

    return;
}

sub _handle_bailout_event
{
    my $self = shift;

    $self->bailout_reason($self->_event->explanation());
    $self->saw_bailout(1);

    return;
}

sub _handle_comment_event
{
    my $self = shift;

    my $test = $self->_file_totals->last_detail();
    if (defined($test))
    {
        $test->append_to_diag($self->_event->comment());
    }

    return;
}

sub _handle_labeled_test_event
{
    my $self = shift;

    return;
}

sub _on_first_too_many_tests
{
    my $self = shift;

    warn "Enormous test number seen [test ", $self->_event->number(), "]\n";
    warn "Can't detailize, too big.\n";

    return;
}

sub _handle_enormous_event_num
{
    my $self = shift;

    if (! $self->too_many_tests())
    {
        $self->_on_first_too_many_tests();
        $self->too_many_tests(1);
    }

    return;
}

sub _handle_test_event
{
    my $self = shift;
    return $self->_file_totals->handle_event(
        {
            event => $self->_event,
            enormous_num_cb =>
                sub { return $self->_handle_enormous_event_num(); },
        }
    );

    return;
}

=head2 $self->_handle_event()

Handles the current event according to the list of types in the cascade. It
checks each type and if matches calls the appropriate
C<_handle_${type}_event> callback. Returns the type of the event that matched.

=cut

sub _handle_event
{
    my $self = shift;

    my $event = $self->_event;

    foreach my $type (@{$self->_get_event_types_cascade()})
    {
        my $is_type = "is_" . $type;
        if ($event->$is_type())
        {
            my $handle_type = "_handle_${type}_event";
            $self->$handle_type();

            return $type;
        }
    }

    return;
}

sub _invoke_cb
{
    my $self = shift;
    my $args = shift;

    if ($self->callback())
    {
        $self->callback()->(
            $args
        );
    }
}

sub _call_callback
{
    my $self = shift;
    return $self->_invoke_cb(
        {
            type => "tap_event",
            event => $self->_event(),
            totals => $self->_file_totals(),
        }
    );
}

sub _bump_next
{
    my $self = shift;

    if (defined(my $n = $self->_event->get_next_test_number()))
    {
        $self->next_test_num($n);
    }

    return;
}


sub _calc__analyze_event__callbacks
{
    my $self = shift;

    return [qw(
        _handle_event
        _call_callback
        _bump_next
    )];
}

sub _analyze_event
{
    shift->_run_sequence();

    return;
}

sub _events_loop
{
    my $self = shift;

    while ($self->_get_next_event())
    {
        $self->_analyze_event();
        last if $self->saw_bailout();
    }

    return;
}

sub _end_file
{
    my $self = shift;

    $self->_file_totals->determine_passing();

    $self->_parser(undef);
    $self->_event(undef);

    return;
}

sub _calc__analyze_with_parser__callbacks
{
    my $self = shift;

    return [qw(
        _start_new_file
        _events_loop
        _end_file
    )];
}

sub _analyze_with_parser
{
    my $self = shift;

    $self->_run_sequence();

    return $self->_file_totals();
}

sub _get_command_and_switches
{
    my $self = shift;

    return [$self->_command(), @{$self->_switches()}];
}

sub _get_full_exec_command
{
    my $self = shift;

    return [ @{$self->_get_command_and_switches()}, $self->file()];
}

sub _command_line
{
    my $self = shift;

    return join(" ", @{$self->_get_full_exec_command()});
}

sub _create_parser
{
    my $self = shift;

    local $ENV{PERL5LIB} = $self->_INC2PERL5LIB;
    $self->_invoke_cb({type => "report_start_env"});

    my $ret = TAP::Parser->new(
            {
                exec => $self->_get_full_exec_command(),
            }
        );

     $self->_restore_PERL5LIB();

     return $ret;
}

=head2 my $results = $self->analyze( $name, \@output_lines)

Analyzes the output @output_lines of a given test, to which the name
$name is assigned. Returns the results $results of the test - an object of
type L<Test::Run::Straps::StrapsTotalsObj> .

@output_lines should be the output of the test including newlines.

=cut

sub analyze
{
    my($self, $name, $test_output_orig) = @_;

    # Assign it here so it won't be passed around.
    $self->file($name);

    $self->_parser($self->_create_parser($test_output_orig));

    return $self->_analyze_with_parser();
}

sub _init_totals_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Straps::StrapsTotalsObj->new($args);
}

sub _get_initial_totals_obj_params
{
    my $self = shift;

    return
    {
        (map { $_ => 0 } qw(max seen ok todo skip bonus)),
        filename => $self->file(),
        details => [],
        _is_vms => $self->_is_vms(),
    };
}

sub _is_event_todo
{
    my $self = shift;

    return $self->_event->has_todo();
}

=head2 $strap->analyze_fh()

Analyzes a TAP stream based on the TAP::Parser from $self->_create_parser().

=cut

sub analyze_fh
{
    my $self = shift;

    $self->_parser($self->_create_parser());

    return $self->_analyze_with_parser();
}

sub _analyze_fh_wrapper
{
    my $self = shift;

    eval
    {
        $self->results($self->analyze_fh());
    };
    $self->exception($@);

    return;
}

sub _throw_trapped_exception
{
    my $self = shift;

    if ($self->exception() ne "")
    {
        die $self->exception();
    }

    return;
}

sub _cleanup_analysis
{
    my ($self) = @_;

    $self->_throw_trapped_exception();

    $self->results()->_calc_all_process_status();

    return;
}

=head2 $strap->analyze_file($filename)

Runs and analyzes the program file C<$filename>. It will also use it
as the name in the final report.

=cut

sub analyze_file
{
    my ($self, $file) = @_;

    # Assign it here so it won't be passed around.
    $self->file($file);

    $self->_analyze_fh_wrapper();

    $self->_cleanup_analysis();

    return $self->results();
}

sub _default_inc
{
    my $self = shift;

    # Temporarily nullify PERL5LIB so Perl will not report the paths
    # that it contains.
    local $ENV{PERL5LIB};

    my $perl_includes;

    my @includes = capturex( $^X, "-e", qq{print join("\\n", \@INC);} );
    chomp(@includes);

    return \@includes;
}

=head2 $strap->_filtered_INC(\@inc)

Filters @inc so it will fit into the environment of some operating systems
which limit it (such as VMS).

=cut

sub _filtered_INC
{
    my ($self, $inc_param) = @_;

    my @inc = $inc_param ? @$inc_param : @INC;

    if ($self->_is_vms())
    {
        @inc = grep { !m{perl_root}i } @inc;
    }
    elsif ($self->_is_win32())
    {
        foreach my $path (@inc)
        {
            $path =~ s{[\\/]+\z}{}ms;
        }
    }

    my %seen;

    %seen = (map { $_ => 1} @{$self->_default_inc()});
    @inc = (grep { ! $seen{$_}++ } @inc);

    return \@inc;
}

=head2 [@filtered] = $strap->_clean_switches(\@switches)

Returns trimmed and blank-filtered switches from the user.

=cut

sub _trim
{
    my $s = shift;

    if (!defined($s))
    {
        return ();
    }
    $s =~ s{\A\s+}{}ms;
    $s =~ s{\s+\z}{}ms;

    return ($s);
}

sub _split_switches
{
    my $self = shift;
    my $switches = shift;

    return
    [
        map
        { my $s = $_; $s =~ s{\A"(.*)"\z}{$1}; $s }
        map
        { split(/\s+/, $_) }
        grep
        { defined($_) }
        @$switches
    ];
}

sub _clean_switches
{
    my ($self, $switches) = @_;

    return [grep { length($_) } map { _trim($_) } @$switches];
}

sub _get_shebang
{
    my($self) = @_;

    my $file = $self->file();

    my $test_fh;
    if (!open($test_fh, $file))
    {
        $self->_handle_test_file_opening_error(
            {
                file => $file,
                error => $!,
            }
        );
        return "";
    }
    my $shebang = <$test_fh>;
    if (!close($test_fh))
    {
        $self->_handle_test_file_closing_error(
            {
                file => $file,
                error => $!,
            }
        );
    }
    return $shebang;
}

=head2 $self->_command()

Returns the command (the command-line executable) that will run the test
along with L<_switches()>.

Normally returns $^X, but can be over-rided using the C<Test_Interpreter>
accessor.

This method can be over-rided in custom test harnesses in order to run
using different TAP producers than Perl.

=cut

sub _command
{
    my $self = shift;

    if (defined(my $interp = $self->Test_Interpreter()))
    {
        return
            +(ref($interp) eq "ARRAY")
                ? (@$interp)
                : (split(/\s+/, $interp))
                ;
    }
    else
    {
        return $self->_default_command($^X);
    }
}

sub _default_command
{
    my $self = shift;
    my $path = shift;

    if ($self->_is_win32())
    {
        return Win32::GetShortPathName($path);
    }
    else
    {
        return $path;
    }
}

sub _handle_test_file_opening_error
{
    my ($self, $args) = @_;

    $self->_invoke_cb({type => "test_file_opening_error", %$args});
}

sub _handle_test_file_closing_error
{
    my ($self, $args) = @_;

    $self->_invoke_cb({type => "test_file_closing_error", %$args});
}

=head2 $strap->_restore_PERL5LIB()

Restores the old value of PERL5LIB. This is necessary on VMS. Does not
do anything on other platforms.

=cut

sub _restore_PERL5LIB
{
    my $self = shift;

    if ($self->_is_vms())
    {
        $ENV{PERL5LIB} = $self->_old5lib();
    }

    return;
}

=head2 $self->_reset_file_state()

Reset some fields so it will be ready to process the next file.

=cut

sub _calc_reset_file_state
{
    my $self = shift;

    return
    {
        too_many_tests => undef(),
        todo => +{},
        saw_header => 0,
        saw_bailout => 0,
        bailout_reason => "",
        next_test_num => 1,
    };
}

sub _reset_file_state
{
    my $self = shift;

    my $to = $self->_calc_reset_file_state();

    while (my ($field, $value) = each(%$to))
    {
        $self->$field($value);
    }

    return;
}

sub _calc_existing_switches
{
    my $self = shift;

    return $self->_clean_switches(
        $self->_split_switches(
            [$self->Switches(), $self->Switches_Env()]
        )
    );
}

sub _calc_taint_flag
{
    my $self = shift;

    my $shebang = $self->_get_shebang();

    if ($shebang =~ m{^#!.*\bperl.*\s-\w*([Tt]+)})
    {
        return ($1);
    }
    else
    {
        return;
    }
}

sub _calc_derived_switches
{
    my $self = shift;

    if (my ($t) = $self->_calc_taint_flag())
    {
        return ["-$t", map { "-I$_" } @{$self->_filtered_INC()}];
    }
    else
    {
        return [];
    }
}

=head2 $self->_switches()

Calculates and returns the switches necessary to run the test.

=cut

sub _switches
{
    my $self = shift;

    return
    [
        @{$self->_calc_existing_switches()},
        @{$self->_calc_derived_switches()},
    ];
}

=head2 local $ENV{PERL5LIB} = $self->_INC2PERL5LIB()

Takes the calculated library paths for running the test scripts and returns
it as something that one can assign to the PERL5LIB environment variable.

=cut

sub _INC2PERL5LIB
{
    my $self = shift;

    $self->_old5lib($ENV{PERL5LIB});

    return join($Config{path_sep}, @{$self->_filtered_INC()});
}


1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .
