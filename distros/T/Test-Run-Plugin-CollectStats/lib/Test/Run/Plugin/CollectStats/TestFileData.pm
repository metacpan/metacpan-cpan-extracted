package Test::Run::Plugin::CollectStats::TestFileData;

use strict;
use warnings;

use Moose;

=head1 NAME

Test::Run::Plugin::CollectStats::TestFileData - an object representing the
data for a single test file in Test::Run.

=head1 VERSION

Version 0.0103

=cut

extends('Test::Run::Base::Struct');

has 'elapsed_time' => (is => "rw", isa => "Str");
has 'results' => (is => "rw", isa => "Test::Run::Straps::StrapsTotalsObj");
has 'summary_object' => (is => "rw", isa => "Test::Run::Obj::TestObj");

1;

__END__

=head1 METHODS

=head2 $test_file_data->elapsed_time()

The elapsed time in seconds, with a leading space. Could have a fraction if
L<Time::HiRes> is installed or could be "<1" if less than one second.

=head2 $test_file_data->results()

The L<Test::Run::Straps::StrapsTotalsObj> object representing the test file
totals information.

=head2 $test_file_data->summary_object()

The L<Test::Run::Obj::TestObj> object that summarizes and analzes the
results.

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

