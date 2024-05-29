package Test::Health::Harness;

use warnings;
use strict;
use Moo 2.000002;
use namespace::clean 0.26;
use TAP::Harness 3.30;
use TAP::Formatter::HTML 0.11;
use Carp;
use File::Spec;
use Types::Standard 1.000005 qw(Str Object);

our $VERSION = '0.004'; # VERSION

=head1 NAME

Test::Health::Harness - Moo object to process output from TAP generating tests

=head1 SYNOPSIS

See health_check.pl command line script.

=head1 ATTRIBUTES

=head1 dir

Directories where the tests to be processed are located.

This is a required, read-only attribute during object creation.

=cut

has dir => ( is => 'ro', isa => Str, required => 1, reader => 'get_dir' );

=head2 report_file

Full path to the HTML file that will be created. 

This is a optional, read-write attribute during object creation, it defaults to "results.html".

=cut

has report_file => (
    is      => 'rw',
    isa     => Str,
    reader  => 'get_report_file',
    writer  => 'set_report_file',
    default => 'results.html'
);

=head2 _lib

Same function of the parameter C<lib> as described in L<TAP::Harness> C<new> method Pod.

Accepts a scalar value or array ref of scalar values indicating which paths to allowed libraries should be included if Perl tests are executed.

=cut

has _lib =>
  ( is => 'ro', isa => Str, reader => '_get_lib', predicate => '_has_lib' );

=head2 formatter

Holds a reference to L<TAP::Formatter::HTML>, so you can customize it if desired by subclassing this class.

=cut

has formatter => (
    is     => 'ro',
    isa    => Object,
    reader => 'get_formatter',
    writer => '_set_formatter'
);

=head1 METHODS

=head2 get_formatter

Getter for the C<formatter> attribute.

=head2 get_dir

Getter for C<dir> attribute.

=head2 get_report_file

Getter for the C<report_file> attribute.

=head2 set_report_file

Setter for the C<report_file> attribute.

=head2 BUILD

Execute validations over the parameter given during object creation.

It dies in case of exceptions.

=cut

sub BUILD {
    my ( $self, $args ) = @_;
    confess "must receive a valid dir parameter"
      unless ( ( exists( $args->{dir} ) ) and ( defined( $args->{dir} ) ) );
    stat( $args->{dir} );
    confess "Cannot read $args->{dir}: does not exists or it is not a directory"
      unless ( ( -e _ ) and ( -d _ ) );
    my $fmt = TAP::Formatter::HTML->new();
    $fmt->output_file( $self->get_report_file );
    $fmt->verbosity(-2);
    $self->_set_formatter($fmt);
}

=head2 test_health

Reads and process the tests under the directory defined on C<dir> attribute.

If the tests were executed succesfully (which doesn't mean they have the expected results), the
HTML report will be generated independent of the expected results.

If the results are FAIL, it will return the test name and the output filename.

If PASS, the HTML report will be removed (see C<discard_report method>) automatically and it will
return C<undef>.

=cut

sub test_health {
    my $self = shift;
    my @tests = glob( File::Spec->catfile( $self->get_dir, '*.t' ) );
    confess 'could not locate any test file (*.t) in ' . $self->get_dir
      unless ( scalar(@tests) >= 1 );

    foreach my $test (@tests) {
        my $output_filename = $self->get_report_file;
        my $harness;
        my $fmt = $self->get_formatter;

        if ( $self->_has_lib ) {
            $harness = TAP::Harness->new(
                {
                    formatter => $fmt,
                    merge     => 1,
                    lib       => $self->get_lib
                }
            );
        }
        else {
            $harness = TAP::Harness->new(
                {
                    formatter => $fmt,
                    merge     => 1,
                }
            );
        }

        my $aggregator = $harness->runtests($test);

        if ( $aggregator->has_problems ) {
            return $test, $output_filename;
        }
        else {
            $self->discard_report();
            return;
        }

    }

}

=head2 discard_report

Discards the HTML report file.

Generates an error message to STDERR in case of failure.

=cut

sub discard_report {
    my $self = shift;
    unlink $self->get_report_file
      or warn 'Could not remove unused report file '
      . $self->get_report_file . ": $!";
}

=head1 SEE ALSO

=over

=item *

L<TAP::Harness>

=item *

L<Moo>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Test-Health distribution.

Test-Health is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Test-Health is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Test-Health. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
