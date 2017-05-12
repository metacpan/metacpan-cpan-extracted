package Test::Run::Obj::TotObj;

use strict;
use warnings;

=head1 NAME

Test::Run::Obj::TotObj - totals encountered for the entire Test::Run session

=head1 DESCRIPTION

Inherits from L<Test::Run::Base::Struct>.

=head1 METHODS

=cut

use vars qw(@fields @counter_fields %counter_fields_map);

use Benchmark qw();

use Moose;
use MRO::Compat;

extends("Test::Run::Base::Struct");

@counter_fields = (qw(
    bad
    bench
    bonus
    files
    good
    max
    ok
    skipped
    sub_skipped
    todo
));

%counter_fields_map = (map { $_ => 1 } @counter_fields);

has 'bad' => (is => "rw", isa => "Num");
has 'bench' => (is => "rw", isa => "Any");
has 'bonus' => (is => "rw", isa => "Str");
# TODO : Should this be removed?
has 'files' => (is => "rw");
has 'good' => (is => "rw", isa => "Num");
has 'max' => (is => "rw", isa => "Num");
has 'ok' => (is => "rw", isa => "Num");
has 'skipped' => (is => "rw", isa => "Num");
has 'sub_skipped' => (is => "rw", isa => "Num");
has 'todo' => (is => "rw", isa => "Num");
has 'tests' => (is => "rw", isa => "Num");

sub _pre_init
{
    my $self = shift;
    foreach my $f (@counter_fields)
    {
        $self->$f(0);
    }
    return 0;
}

=head2 BUILD

For Moose.

=cut

sub BUILD
{
    my $self = shift;

    $self->_register_obj_formatter(
        {
            name => "fail_no_tests_output",
            format => "FAILED--%(tests)d test %(_num_scripts)s could be run, alas--no output ever seen\n",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "sub_skipped_msg",
            format => "%(sub_skipped)d %(_skipped_subtests)s",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "skipped_bonusmsg_on_skipped",
            format => ", %(skipped)d %(_skipped_tests_str)s%(_and_skipped_msg)s skipped",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "skipped_bonusmsg_on_sub_skipped",
            format => ", %(_sub_skipped_msg)s skipped",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "sub_percent_msg",
            format => " %(_not_ok)s/%(max)s subtests failed, %(_percent_ok).2f%% okay.",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "good_percent_msg",
            format => "%(_good_percent).2f",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "fail_tests_good_percent_string",
            format => ", %(good_percent_msg)s%% okay",
        },
    );

    $self->_register_obj_formatter(
        {
            name => "positive_bonusmsg",
            format => " (%(bonus)s %(_bonus_subtests_str)s UNEXPECTEDLY SUCCEEDED)",
        },
    );

    return $self;
}

sub _good_percent
{
    my $self = shift;

    return $self->_percent("good", "tests");
}

sub _percent
{
    my ($self, $num, $denom) = @_;

    return ($self->$num() * 100 / $self->$denom());
}

=head2 $self->add($field, $diff)

Adds the difference $diff to the slot $field, assuming it is a counter field.

=cut

sub add
{
    my ($self, $field, $diff) = @_;
    if (!exists($counter_fields_map{$field}))
    {
        Carp::confess "Cannot add to field \"$field\"!";
    }
    $self->$field($self->$field() + $diff);
    return $self->$field();
}

=head2 $self->inc($field)

Increments the field $field by 1.

=cut

sub inc
{
    my ($self, $field) = @_;

    return $self->add($field, 1);
}

=head2 $self->bench_timestr()

Retrieves the timestr() "nop" according to Benchmark.pm of the bench() field.

=cut

sub bench_timestr
{
    my $self = shift;

    return Benchmark::timestr($self->bench(), 'nop');
}

=head2 $self->all_ok()

Returns a boolean value - 0 or 1 if all tests were OK.

=cut

sub all_ok
{
    my $self = shift;

    return $self->_normalize_cond(
           ($self->bad() == 0)
        && ($self->max() || $self->skipped())
    );
}

sub _normalize_cond
{
    my ($self, $cond) = @_;
    return ($cond ? 1 : 0);
}

=head2 $self->fail_test_scripts_string()

Internal use.

=cut

sub fail_test_scripts_string
{
    my $self = shift;

    return $self->_get_obj_formatter(
        "%(bad)s/%(tests)s test scripts",
    )->obj_format($self);
}

=head2 $self->add_results($results)

Adds the sums from a results object.

=cut

sub add_results
{
    my ($self, $results) = @_;

    foreach my $type (qw(bonus max ok todo))
    {
        $self->add($type, $results->$type());
    }

    $self->add("sub_skipped", $results->skip())
}

sub _num_scripts
{
    my $self = shift;

    return $self->_pluralize("script", $self->tests());
}

sub _get_fail_no_tests_output_text
{
    my $self = shift;

    return $self->_format_self(
        "fail_no_tests_output",
    );
}

sub _skipped_subtests
{
    my $self = shift;

    return $self->_pluralize("subtest", $self->sub_skipped());
}

=head2 $self->get_sub_skipped_msg()

Calculates the sub-skipped message ("X subtest/s")

=cut

sub _sub_skipped_msg
{
    my $self = shift;

    return $self->_format_self(
        "sub_skipped_msg",
    );
}

sub _skipped_tests_str
{
    my $self = shift;

    return $self->_pluralize("test", $self->skipped());
}

sub _and_skipped_msg
{
    my $self = shift;

    return $self->sub_skipped()
        ? ( " and " . $self->_sub_skipped_msg() )
        :   ""
        ;
}

sub _get_skipped_bonusmsg_on_skipped
{
    my $self = shift;

    return $self->_format_self(
        "skipped_bonusmsg_on_skipped"
    );
}

sub _get_skipped_bonusmsg_on_sub_skipped
{
    my $self = shift;

    return $self->_format_self(
        "skipped_bonusmsg_on_sub_skipped",
    );
}

sub _get_skipped_bonusmsg
{
    my $self = shift;

    if ($self->skipped())
    {
        return $self->_get_skipped_bonusmsg_on_skipped();
    }
    elsif ($self->sub_skipped())
    {
        return $self->_get_skipped_bonusmsg_on_sub_skipped();
    }
    else
    {
        return "";
    }
}

sub _bonus_subtests_str
{
    my $self = shift;

    return $self->_pluralize("subtest", $self->bonus());
}

sub _get_positive_bonusmsg
{
    my $self = shift;

    return $self->_format_self(
        "positive_bonusmsg"
    );
}

sub _get_subtests_bonusmsg
{
    my $self = shift;
    return ($self->bonus() ? $self->_get_positive_bonusmsg() : "");
}

=head2 $self->get_bonusmsg()

Internal use.

=cut

sub get_bonusmsg
{
    my $self = shift;

    return $self->_get_subtests_bonusmsg() . $self->_get_skipped_bonusmsg();
}

sub _percent_ok
{
    my $self = shift;

    return 100*$self->ok()/$self->max();
}

sub _not_ok
{
    my $self = shift;

    return $self->max() - $self->ok();
}

=head2 $self->get_sub_percent_msg()

Internal use.

=cut

sub get_sub_percent_msg
{
    my $self = shift;

    return $self->_format_self(
        "sub_percent_msg",
    );
}

=head2 $self->good_percent_msg()

Internal use.

=cut

sub good_percent_msg
{
    my $self = shift;

    return $self->_format_self(
        "good_percent_msg",
    );
}

=head2 $self->fail_tests_good_percent_string()

Internal use.

=cut

sub fail_tests_good_percent_string
{
    my $self = shift;

    return $self->_format_self(
        "fail_tests_good_percent_string",
    );
}

=head2 $self->benchmark_callback(\&callback)

Benchmarks the callback C<&callback> using the Benchmark module and puts the
result in the C<bench()> slot.

=cut

sub benchmark_callback
{
    my ($self, $cb) = @_;

    my $start_time = new Benchmark;
    $cb->();
    my $end_time = new Benchmark;

    $self->bench(Benchmark::timediff($end_time, $start_time));

    return;
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

