package Test::Run::Obj::CanonFailedObj;

use strict;
use warnings;

# TODO
# Refactor the hell out of this module.

=head1 NAME

Test::Run::Obj::CanonFailedObj - the failed tests canon object.

=head1 METHODS

=cut

use Moose;

extends('Test::Run::Base::Struct');

use MRO::Compat;

use vars qw(@fields);

has 'failed' => (is => "rw", isa => "ArrayRef");
has '_more_results' => (is => "rw", isa => "ArrayRef",
    lazy => 1, default => sub { [] },
);

sub _get_more_results
{
    my $self = shift;

    return $self->_more_results();
}

=head2 $self->add_result($result)

Pushes $result to the result() slot.

=cut

sub add_result
{
    my $self = shift;
    push @{$self->_more_results()}, @_;
}

=head2 $self->get_ser_results()

Returns the serialized results.

=cut

sub get_ser_results
{
    my $self = shift;
    return join("", @{$self->result()});
}

=head2 $self->add_Failed($test)

Add a failed test $test to the diagnostics.

=cut

sub _add_Failed_summary
{
    my ($self, $test) = @_;

    $self->add_result(
        sprintf(
            "\tFailed %s/%s tests, ",
            $self->failed_num(),
            $test->max()
        )
    );
}

sub _add_Failed_percent_okay
{
    my ($self, $test) = @_;

    $self->add_result(
        $self->_calc_Failed_percent_okay($test)
    );
}

sub _calc_Failed_percent_okay
{
    my ($self, $test) = @_;

    return
        $test->max()
            ? sprintf("%.2f%% okay", 100*(1-$self->failed_num()/$test->max()))
            : "?% okay"
        ;
}

sub add_Failed
{
    my ($self, $test) = @_;

    my $max = $test->max();
    my $failed_num = $self->failed_num();

    $self->_add_Failed_summary($test);
    $self->_add_Failed_percent_okay($test);
}

=head2 $self->add_skipped($test)

Add a skipped test.

=cut

sub add_skipped
{
    my ($self, $test) = @_;

    if ($test->skipped())
    {
        $self->_add_actual_skipped($test);
    }
}

sub _add_actual_skipped
{
    my ($self, $test) = @_;

    my $tests_string = (($test->skipped() > 1) ? "tests" : "test");

    $self->add_result(
        sprintf(
            " (less %s skipped %s: %s okay, %s%%)",
            $test->skipped(),
            $tests_string,
            $self->_calc_skipped_percent($test),
        )
    );
}

sub _calc_skipped_percent
{
    my ($self, $test) = @_;

    return
        $test->max()
            ? sprintf("%.2f", 100*($self->good($test)/$test->max()))
            : "?"
        ;
}

=head2 $self->good()

Returns the number of good (non failing or skipped) tests.

=cut

sub good
{
    my ($self, $test) = @_;

    return $test->max() - $self->failed_num() - $test->skipped();
}

=head2 $self->add_Failed_and_skipped($test)

Adds a test as both failed and skipped.

=cut

sub add_Failed_and_skipped
{
    my ($self, $t) = @_;

    $self->add_Failed($t);
    $self->add_skipped($t);

    return;
}

=head2 $self->canon_list()

Returns the the failed tests as a list of ranges.

=cut

sub canon_list
{
    my $self = shift;

    return (@{$self->failed()} == 1)
        ? [ @{$self->failed()} ]
        : $self->_get_canon_ranges()
       ;
}

sub _get_canon_ranges
{
    my $self = shift;

    my @failed = @{$self->failed()};

    # Assign the first number in the range.
    my $min = shift(@failed);

    my $last = $min;

    my @ranges;

    foreach my $number (@failed, $failed[-1]) # Don't forget the last one
    {
        if (($number > $last+1) || ($number == $last))
        {
            push @ranges, +($min == $last) ? $min : "$min-$last";
            $min = $last = $number;
        }
        else
        {
            $last = $number;
        }
    }

    return \@ranges;
}

=head2 my $string = $self->canon()

Returns the canon as a space-delimited string.

=cut

sub canon
{
    my $self = shift;

    return join(' ', @{$self->canon_list()});
}


sub _get_failed_string
{
    my $self = shift;

    my $canon = $self->canon_list;

    return
        sprintf("FAILED %s %s",
            $self->_list_pluralize("test", $canon),
            join(", ", @$canon)
        );
}

sub _get_failed_string_line
{
    my $self = shift;

    return $self->_get_failed_string() . "\n";
}

=head2 $self->result()

The non-serialized result of the test.

=cut

sub result
{
    my $self = shift;

    return [ $self->_get_failed_string_line(), @{$self->_get_more_results()} ];
}

=head2 $self->failed_num()

Returns the number of failed tests.

=cut

sub failed_num
{
    my $self = shift;

    return scalar(@{$self->failed()});
}

=head2 $self->add_skipped($test)

Add a skipped test.

=cut


=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 SEE ALSO

L<Test::Run::Obj>, L<Test::Run::Core>.

=cut

1;
