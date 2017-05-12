package Test::Run::Plugin::CollectStats;

use warnings;
use strict;

use Moose;

use MRO::Compat;
use Storable ();

extends('Test::Run::Base');

use Test::Run::Plugin::CollectStats::TestFileData;

=head1 NAME

Test::Run::Plugin::CollectStats - Test::Run plugin to collect statistics and
data.

=head1 VERSION

Version 0.0103

=cut

has '_recorded_test_files_data' => (is => "rw", isa => "ArrayRef",
    default => sub { [] },
);

has '_test_files_names_map' => (is => "rw", isa => "HashRef",
    default => sub { +{} },
);

our $VERSION = '0.0103';

=head1 SYNOPSIS

    package MyTestRun;

    use base 'Test::Run::Plugin::AlternateInterpreters';
    use base 'Test::Run::Obj';

=head1 METHODS

=cut

sub _run_single_test
{
    my ($self, $args) = @_;

    my $filename = $args->{test_file};

    $self->next::method($args);

    $self->_test_files_names_map->{$filename} =
        scalar(@{$self->_recorded_test_files_data()});

    push @{$self->_recorded_test_files_data},
        Test::Run::Plugin::CollectStats::TestFileData->new(
            {
                elapsed_time => $self->last_test_elapsed(),
                results => Storable::dclone($self->last_test_results()),
                summary_object => Storable::dclone($self->last_test_obj()),
            }
        );

    return;
}

=head2 $tester->get_recorded_test_file_data($index)

Returns the L<Test::Run::Plugin::CollectStats::TestFileData> instance
representing the results of test number $index.

=cut

sub get_recorded_test_file_data
{
    my $self = shift;
    my $idx = shift;

    return $self->_recorded_test_files_data->[$idx];
}

=head2 $tester->find_test_file_idx_by_filename($filename)

Retrieves the (last) index of the test file $filename.

=cut

sub find_test_file_idx_by_filename
{
    my $self = shift;
    my $filename = shift;

    return $self->_test_files_names_map->{$filename};
}

=head2 $tester->get_num_collected_tests()

Retrieves the number of collected tests.

=cut

sub get_num_collected_tests
{
    my $self = shift;

    return scalar(@{$self->_recorded_test_files_data});
}

=head2 $tester->get_filename_test_data($filename)

Returns theL<Test::Run::Plugin::CollectStats::TestFileData> instance
representing the results of the (last) test with the filename $filename.

=cut

sub get_filename_test_data
{
    my $self = shift;
    my $filename = shift;

    return $self->get_recorded_test_file_data(
        $self->find_test_file_idx_by_filename($filename)
    );
}

=head1 SEE ALSO

L<Test::Run::Plugin::CollectStats::TestFileData>, L<Test::Run::Core>,
L<Test::Run::Obj>.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-collectstats at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-CollectStats>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::CollectStats

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Run-Plugin-CollectStats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Run-Plugin-CollectStats>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Run-Plugin-CollectStats>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Run-Plugin-CollectStats>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11.

=cut

1; # End of Test::Run::Plugin::CollectStats
