package Test::Run::Plugin::CollectStats::TestFileData;

use strict;
use warnings;

use Moose;

=head1 NAME

Test::Run::Plugin::CollectStats::TestFileData - an object representing the
data for a single test file in Test::Run.

=head1 VERSION

Version 0.0104

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

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish.

This program is released under the following license: MIT/Expat.

=cut

