package Test::Run::Obj::TestObj;

use strict;
use warnings;

=head1 NAME

Test::Run::Obj::TestObj - results of a single test script.

=cut

use vars qw(@fields);

use Moose;

extends('Test::Run::Base::Struct');

use MRO::Compat;

use Test::Run::Obj::IntOrUnknown;

=head1 FIELDS

=head2 $self->bonus()

Number of TODO tests that unexpectedly passed.

=head2 $self->failed()

Returns an array reference containing list of test numbers that failed.

=head2 $self->ok()

Number of tests that passed.

=head2 $self->next()

The next expected event.

=head2 $self->max()

The number of plannedt tests.

=head2 $self->skipped()

The number of skipped tests.

=head2 $self->skip_all()

This field will contain the reason for why the entire test script was skipped,
in cases when it was.

=head2 $self->skip_reason()

The skip reason for the last skipped test that specified such a reason.

=cut

has 'bonus' => (is => "rw", isa => "Num");
has 'failed' => (is => "rw", isa => "ArrayRef");
has 'max' => (is => "rw", isa => "Num");
has 'ml' => (is => "rw", isa => "Str");
has 'next' => (is => "rw", isa => "Num");
has 'ok' => (is => "rw", isa => "Num");
has 'skip_all' => (is => "rw", isa => "Maybe[Str]");
has 'skipped' => (is => "rw", isa => "Num");
has 'skip_reason' => (is => "rw", isa => "Maybe[Str]");

=head2 BUILD

For Moose.

=cut

sub BUILD
{
    my $self = shift;

    $self->_register_obj_formatter(
        {
            name => "dont_know_which_tests_failed",
            format => "Don't know which tests failed: got %(ok)s ok, expected %(max)s",
        },
    );

    return;
}

=head2 $self->add_to_failed(@failures)

Add failures to the failed() slot.

=cut

sub add_to_failed
{
    my $self = shift;
    push @{$self->failed()}, @_;
}

sub _get_reason_default
{
    return "no reason given";
}

=head2 $self->get_reason()

Gets the reason or defaults to the default.

=cut

sub get_reason
{
    my $self = shift;

    return
        +(defined($self->skip_all()) && length($self->skip_all())) ?
            $self->skip_all() :
            $self->_get_reason_default()
        ;
}

=head2 $self->num_failed()

Returns the number of failed tests.

=cut

sub num_failed
{
    my $self = shift;

    return scalar(@{$self->failed()});
}

=head2 $self->calc_percent()

Calculates the percent of failed tests.

=cut

sub calc_percent
{
    my $self = shift;

    return ( (100*$self->num_failed()) / $self->max() );
}

=head2 $self->add_next_to_failed()

Adds the tests from ->next() to ->max() to the list of failed tests.

=cut

sub add_next_to_failed
{
    my $self = shift;

    return $self->add_to_failed($self->next() .. $self->max());
}

=head2 $self->is_failed_and_max()

Returns if there are failed tests B<and> the maximal test number was set.

=cut

sub is_failed_and_max
{
    my $self = shift;

    return scalar(@{$self->failed()}) && $self->max();
}

sub _get_dont_know_which_tests_failed_msg
{
    my $self = shift;

    return $self->_format_self("dont_know_which_tests_failed");
}

=head2 $self->skipped_or_bonus()

Returns whether the test file is either skipped() or bonus().

=cut

sub skipped_or_bonus
{
    my $self = shift;

    return $self->skipped() || $self->bonus();
}

=head2 $self->all_succesful()

A predicate that calculates if all the tests in the TestObj were successful.

=cut

sub all_succesful
{
    my $self = shift;

    return
    (
        ($self->next() == $self->max() + 1)
            &&
        (! @{$self->failed()})
    );
}

=head2 $self->get_dubious_summary_main_obj_method()

Returns the method name of the main object that should be propagated
based on the success/failure status of this test object.

=cut

sub get_dubious_summary_main_obj_method
{
    my $self = shift;

    return
        $self->max()
            ? ($self->all_succesful()
                ? "_get_dubious_summary_all_subtests_successful"
                : "_get_premature_test_dubious_summary"
              )
            : "_get_no_tests_summary"
        ;
}

=head2 $self->get_failed_obj_params

Returns a key value array ref of params for initializing the failed-object.

=cut

sub get_failed_obj_params
{
    my $self = shift;

    return
        [
            max => ($self->max()
                ? Test::Run::Obj::IntOrUnknown->create_int($self->max())
                : Test::Run::Obj::IntOrUnknown->create_unknown()
            ),
        ];
}

sub _still_running
{
    my $self = shift;

    return ($self->next() <= $self->max());
}


sub _calc_tests_as_failures
{
    my ($self, $details) = @_;

    if ($self->_still_running())
    {
        return [$self->next() .. $self->max()];
    }
    else
    {
        return
        [
            grep { ref($details->[$_-1]) }
            (($self->max()+1) .. @$details)
        ];
    }
}

=head2 $self->list_tests_as_failures($last_test_results->details())

Lists the tests as failures where appropriate.

=cut

sub list_tests_as_failures
{
    my ($self, $details) = @_;

    $self->add_to_failed(@{$self->_calc_tests_as_failures($details)});
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

