package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

use Carp;
use Benchmark qw(timestr);
use MRO::Compat;

use Moose;
extends("Test::Run::Core");

use Test::Run::Output;

=head1 NAME

Test::Run::Plugin::CmdLine::Output - the default output plugin for
Test::Run::CmdLine.

=head1 MOTIVATION

This class has gradually re-implemented all of the
L<Test::Run::Plugin::CmdLine::Output::GplArt> functionality to
avoid license complications.

=head1 METHODS

=cut

sub _get_new_output
{
    my ($self, $args) = @_;

    return Test::Run::Output->new({ Verbose => $self->Verbose(), NoTty => $self->NoTty()});
}

sub _print
{
    my ($self, $string) = @_;

    return $self->output()->print_message($string);
}

sub _named_printf
{
    my ($self, $format, $args) = @_;

    return
        $self->_print(
            $self->_format($format, $args),
        );
}

has "+output" => (lazy => 1, builder => "_get_new_output");

=head2 BUILD

For Moose.

=cut

sub BUILD
{
    my $self = shift;

    my ($args) = @_;

    {
        my %formatters =
        (
            "dubious_status" =>
                "Test returned status %(estatus)s (wstat %(wstatus)d, 0x%(wstatus)x)",
            "vms_status" =>
                "\t\t(VMS status is %(estatus)s)",
            "test_file_closing_error" =>
                "can't close %(file)s. %(error)s",
            "could_not_run_script" =>
                "can't run %(file)s. %(error)s",
            "test_file_opening_error" =>
                "can't open %(file)s. %(error)s",
            "premature_test_dubious_summary" =>
                "DIED. %(canonfailed)s",
            "report_skipped_test" =>
                "%(ml)sok%(elapsed)s\n        %(all_skipped_test_msgs)s",
            "report_all_ok_test" =>
                "%(ml)sok%(elapsed)s",
            "start_env" =>
                "# PERL5LIB=%(p5lib)s",
        );

        while (my ($id, $format) = each(%formatters))
        {
            $self->_register_formatter($id, $format);
        }
    }

    {
        my %obj_formatters =
        (
            "skipped_msg" =>
                "%(skipped)s/%(max)s skipped: %(skip_reason)s",
            "bonus_msg" =>
                "%(bonus)s/%(max)s unexpectedly succeeded",
            "report_final_stats" =>
                "Files=%(files)d, Tests=%(max)d, %(bench_timestr)s",
        );

        while (my ($id, $format) = each(%obj_formatters))
        {
            $self->_register_obj_formatter(
                { name => $id, format => $format,},
            );
        }
    }

    return 0;
}

sub _get_dubious_message_ml
{
    my $self = shift;
    return $self->last_test_obj->ml();
}

sub _get_dubious_verdict_message
{
    return "dubious";
}

sub _calc__get_dubious_message_components__callbacks
{
    my $self = shift;

    return [qw(
        _get_dubious_message_ml
        _get_dubious_verdict_message
        _get_dubious_message_line_end
        _get_dubious_status_message_indent_prefix
        _get_dubious_status_message
    )];
}

sub _get_dubious_message_components
{
    my $self = shift;

    return $self->_run_sequence([@_]);
}

sub _get_dubious_message_line_end
{
    return "\n";
}

sub _get_dubious_status_message_indent_prefix
{
    return "\t";
}

sub _get_dubious_status_message
{
    my $self = shift;

    return $self->_format("dubious_status",
        {
            estatus => $self->_get_estatus(),
            wstatus => $self->_get_wstatus(),
        }
    );
}

sub _get_dubious_message
{
    my $self = shift;

    return join("",
        @{$self->_get_dubious_message_components()}
    );
}

sub _report_dubious_summary_all_subtests_successful
{
    my $self = shift;

    $self->_print("\tafter all the subtests complete successfully");
}

sub _vms_specific_report_dubious
{
    my ($self) = @_;

    if ($^O eq "VMS")
    {
        $self->_named_printf(
            "vms_status",
            { estatus => $self->_get_estatus() },
        );
    }
}

sub _report_dubious
{
    my ($self) = @_;

    $self->_print($self->_get_dubious_message());
    $self->_vms_specific_report_dubious();
}

sub _get_leaked_files_string
{
    my ($self, $args) = @_;

    return join(" ", sort @{$args->{leaked_files}});
}

sub _report_leaked_files
{
    my ($self, $args) = @_;

    $self->_print("LEAKED FILES: " . $self->_get_leaked_files_string($args));
}

sub _handle_test_file_closing_error
{
    my ($self, $args) = @_;

    return $self->_named_printf(
        "test_file_closing_error",
        $args,
    );
}

sub _report_could_not_run_script
{
    my ($self, $args) = @_;

    return $self->_named_printf(
        "could_not_run_script",
        $args,
    );
}

sub _handle_test_file_opening_error
{
    my ($self, $args) = @_;

    return $self->_named_printf(
        "test_file_opening_error",
        $args,
    );
}

sub _get_defined_skipped_msgs
{
    my ($self, $args) = @_;

    return $self->_format("skipped_msg", { obj => $self->last_test_obj});
}

sub _get_skipped_msgs
{
    my ($self, $args) = @_;

    if ($self->last_test_obj->skipped())
    {
        return [ $self->_get_defined_skipped_msgs() ];
    }
    else
    {
        return [];
    }
}

sub _get_defined_bonus_msg
{
    my ($self, $args) = @_;

    return $self->_format("bonus_msg", { obj => $self->last_test_obj() });
}

sub _get_bonus_msgs
{
    my ($self, $args) = @_;

    return
    [
        ($self->last_test_obj->bonus()) ?
            $self->_get_defined_bonus_msg() :
            ()
    ];
}

sub _get_all_skipped_test_msgs
{
    my ($self) = @_;
    return
    [
        @{$self->_get_skipped_msgs()},
        @{$self->_get_bonus_msgs()}
    ];
}

sub _reset_output_watch
{
    my $self = shift;

    $self->output()->last_test_print(0);

    return;
}

sub _output__get_display_filename_param
{
    my ($self, $args) = @_;

    return $self->_get_test_file_display_path($args->{test_file});
}

sub _output_print_leader
{
    my ($self, $args) = @_;

    $self->output()->print_leader(
        {
            filename => $self->_output__get_display_filename_param($args),
            width => $self->width(),
        }
    );

    return;
}

sub _report_single_test_file_start_leader
{
    my ($self, $args) = @_;

    $self->_reset_output_watch($args);
    $self->_output_print_leader($args);
}

sub _report_single_test_file_start_debug
{
    my ($self, $args) = @_;

    if ($self->Debug())
    {
        $self->_print(
            "# Running: " . $self->Strap()->_command_line($self->_output_print_leader($args))
        );
    }
}

sub _report_single_test_file_start
{
    my ($self, $args) = @_;

    $self->_report_single_test_file_start_leader($args);

    $self->_report_single_test_file_start_debug($args);

    return;
}

sub _calc_test_struct_ml
{
    my $self = shift;

    return $self->output->ml;
}


sub _report_premature_test_dubious_summary
{
    my $self = shift;

    $self->_named_printf(
        "premature_test_dubious_summary",
        {
            canonfailed => $self->_ser_failed_results(),
        }
    );

    return;
}

sub _report_skipped_test
{
    my $self = shift;

    $self->_named_printf(
        "report_skipped_test",
        {
            ml => $self->last_test_obj->ml(),
            elapsed => $self->last_test_elapsed,
            all_skipped_test_msgs =>
                join(', ', @{$self->_get_all_skipped_test_msgs()}),
        }
    );
}

sub _report_all_ok_test
{
    my ($self, $args) = @_;

    $self->_named_printf(
        "report_all_ok_test",
        {
            ml => $self->last_test_obj->ml(),
            elapsed => $self->last_test_elapsed,
        }
    );
}

sub _report_failed_before_any_test_output
{
    my $self = shift;

    $self->_print("FAILED before any test output arrived");
}

sub _report_all_skipped_test
{
    my ($self, $args) = @_;

    $self->_print(
        "skipped\n        all skipped: "
        . $self->last_test_obj->get_reason()
    );
}

sub _namelenize_string
{
    my ($self, $string) = @_;

    $string =~ s/\$\{max_namelen\}/$self->max_namelen()/ge;

    return $string;
}

sub _obj_named_printf
{
    my ($self, $string, $obj) = @_;

    return
    $self->_print(
        $self->_get_obj_formatter(
            $self->_namelenize_string(
                $string,
            ),
        )->obj_format($obj)
    );
}

sub _fail_other_report_tests_print_summary
{
    my ($self, $args) = @_;

    return $self->_obj_named_printf(
        ( "%(name)-\${max_namelen}s  "
        . "%(estat)3s %(wstat)5s %(max_str)5s %(failed_str)4s "
        . "%(_defined_percent)6.2f%%  %(first_canon_string)s"
        ),
        $args->{test},
    );
}

sub _fail_other_report_test_print_rest_of_canons
{
    my ($self, $args) = @_;

    my $test = $args->{test};

    my $whitespace = (" " x ($self->format_columns() - $self->list_len()));

    foreach my $canon (@{$test->rest_of_canons()})
    {
        $self->_print($whitespace.$canon);
    }
}

sub _fail_other_report_test
{
    my $self = shift;
    my $script = shift;

    my $test = $self->failed_tests()->{$script};

    $test->_assign_canon_strings({ main => $self, });

    my $args_to_pass =
    {
        test => $test,
        script => $script,
    };

    $self->_fail_other_report_tests_print_summary($args_to_pass);

    $self->_fail_other_report_test_print_rest_of_canons($args_to_pass);
}

sub _calc_fail_other_bonus_message
{
    my $self = shift;

    my $message = $self->_bonusmsg() || "";
    $message =~ s{\A,\s*}{};

    return $message ? "$message." : "";
}

sub _fail_other_print_bonus_message
{
    my $self = shift;

    if (my $bonusmsg = $self->_calc_fail_other_bonus_message())
    {
        $self->_print($bonusmsg);
    }
}

sub _report_failed_with_results_seen
{
    my ($self) = @_;

    $self->_print($self->_get_failed_with_results_seen_msg());
}

sub _report_test_progress__verdict
{
    my ($self, $args) = @_;

    my $totals = $args->{totals};

    if ($totals->last_detail->ok)
    {
        $self->output->print_ml_less(
            "ok ". $totals->seen . "/" . $totals->max
        );
    }
    else
    {
        $self->output->print_ml("NOK " . $totals->seen);
    }
}

sub _report_test_progress__counter
{
    my ($self, $args) = @_;

    my $totals = $args->{totals};

    my $curr = $totals->seen;
    my $next = $self->Strap->next_test_num();

    if ($curr > $next)
    {
        $self->_print("Test output counter mismatch [test $curr]");
    }
    elsif ($curr < $next)
    {
        $self->_print(
            "Confused test output: test $curr answered after test @{[$next-1]}",
        );
    }
}

sub _report_test_progress
{
    my ($self, $args) = @_;
    $self->_report_test_progress__verdict($args);
    $self->_report_test_progress__counter($args);
}

sub _report_tap_event
{
    my ($self, $args) = @_;

    my $raw_event = $args->{event}->raw();
    if ($self->Verbose())
    {
        chomp($raw_event);
        $self->_print($raw_event);
    }
}

sub _calc_PERL5LIB
{
    my $self = shift;

    return
        +(exists($ENV{PERL5LIB}) && defined($ENV{PERL5LIB}))
            ? $ENV{PERL5LIB}
            : ""
        ;
}

sub _report_script_start_environment
{
    my $self = shift;

    if ($self->Debug())
    {
        $self->_named_printf(
            "start_env",
            { 'p5lib' => $self->_calc_PERL5LIB()},
        );
    }
}

sub _report_final_stats
{
    my $self = shift;

    return $self->_named_printf(
        "report_final_stats",
        { obj => $self->tot() },
    );
}

sub _report_success_event
{
    my ($self, $args) = @_;

    $self->_print($self->_get_success_msg());
}

sub _report_non_success_event
{
    my ($self, $args) = @_;

    confess "Unknown \$event->{type} passed to _report!";
}

sub _report
{
    my ($self, $args) = @_;

    my $event = $args->{event};

    if ($event->{type} eq "success")
    {
        return $self->_report_success_event($args);
    }
    else
    {
        return $self->_report_non_success_event($args);
    }
}

sub _fail_other_print_top
{
    my $self = shift;

    $self->_named_printf(
        \("%(failed)-" . $self->max_namelen() . "s%(middle)s%(list)s") ,
        {
            failed => $self->_get_format_failed_str(),
            middle => $self->_get_format_middle_str(),
            list =>   $self->_get_format_list_str(),
        }
    );

    $self->_print("-" x $self->format_columns());
}

=head1 LICENSE

This file is licensed under the MIT X11 License.

L<http://www.opensource.org/licenses/mit-license.php>

=cut

1;

