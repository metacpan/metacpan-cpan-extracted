package Travel::Status::GB::TFL;

use strict;
use warnings;
use 5.010;

no if $] >= 5.018, warnings => 'experimental::smartmatch';

our $VERSION = '2.01';

use parent 'Travel::Status::DE::URA';

sub new {
	my ( $class, %opt ) = @_;

	$opt{ura_base}    = 'http://countdown.api.tfl.gov.uk/interfaces/ura';
	$opt{ura_version} = '1';

	return $class->SUPER::new(%opt);
}

1;

__END__

=head1 NAME

Travel::Status::GB::TFL - unofficial TFL departure monitor.

=head1 SYNOPSIS

    use Travel::Status::GB::TFL;

    my $status = Travel::Status::GB::TFL->new(
        stop => 'Aachen Bushof'
    );

    for my $d ($status->results) {
        printf(
            "%s  %-5s %25s (in %d min)\n",
            $d->time, $d->line, $d->destination, $d->countdown
        );
    }

=head1 VERSION

version 2.01

=head1 DESCRIPTION

Travel::Status::GB::TFL is an unofficial interface to the Transport for London
(TfL) realtime departure monitor.

=head1 METHODS

=over

=item my $status = Travel::Status::GB::TFL->new(I<%opt>)

Requests the departures as specified by I<opts> and returns a new
Travel::Status::GB::TFL object.

Calls Travel::Status::DE::URA->new with the appropriate B<ura_base> and
B<ura_version> parameters. All I<opts> are passed on.

See Travel::Status::DE::URA(3pm) for the other methods.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item * Travel::Status::DE::URA(3pm)

=back

=head1 BUGS AND LIMITATIONS

Many.

=head1 SEE ALSO

tfl-m(1), Travel::Status::DE::URA(3pm).

=head1 AUTHOR

Copyright (C) 2016 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
