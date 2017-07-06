package Travel::Status::DE::VRR;

use strict;
use warnings;
use 5.010;

no if $] >= 5.018, warnings => "experimental::smartmatch";

our $VERSION = '1.15';

use parent 'Travel::Status::DE::EFA';

sub new {
	my ( $class, %opt ) = @_;

	$opt{efa_url} = 'http://efa.vrr.de/vrr/XSLT_DM_REQUEST';

	return $class->SUPER::new(%opt);
}

1;

__END__

=head1 NAME

Travel::Status::DE::VRR - unofficial VRR departure monitor.

=head1 SYNOPSIS

    use Travel::Status::DE::VRR;

    my $status = Travel::Status::DE::VRR->new(
        place => 'Essen', name => 'Helenenstr'
    );

    for my $d ($status->results) {
        printf(
            "%s %d %-5s %s\n",
            $d->time, $d->platform, $d->line, $d->destination
        );
    }


=head1 VERSION

version 1.15

=head1 DESCRIPTION

Travel::Status::DE::VRR is an unofficial interface to the VRR departure
monitor at
L<http://efa.vrr.de/vrr/XSLT_DM_REQUEST?language=de&itdLPxx_transpCompany=vrr&>.

=head1 METHODS

=over

=item my $status = Travel::Status::DE::VRR->new(I<%opt>)

Requests the departures as specified by I<opts> and returns a new
Travel::Status::DE::VRR object.

Calls Travel::Status::DE::EFA->new with the appropriate B<efa_url>.
All I<opts> are passed on.

See Travel::Status::DE::EFA(3pm) for the other parameters and methods.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item * Class::Accessor(3pm)

=item * DateTime(3pm)

=item * LWP::UserAgent(3pm)

=item * Travel::Status::DE::EFA(3pm)

=back

=head1 BUGS AND LIMITATIONS

Many.

=head1 SEE ALSO

efa-m(1), Travel::Status::DE::EFA(3pm).

=head1 AUTHOR

Copyright (C) 2013-2015 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
