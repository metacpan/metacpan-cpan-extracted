package Travel::Status::DE::URA::Stop;

use strict;
use warnings;
use 5.010;

use parent 'Class::Accessor';

our $VERSION = '2.01';

Travel::Status::DE::URA::Stop->mk_ro_accessors(qw(datetime name));

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = \%conf;

	return bless( $ref, $obj );
}

sub date {
	my ($self) = @_;

	return $self->{datetime}->strftime('%d.%m.%Y');
}

sub time {
	my ($self) = @_;

	return $self->{datetime}->strftime('%H:%M:%S');
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;

__END__

=head1 NAME

Travel::Status::DE::URA::Stop - Information about a stop

=head1 SYNOPSIS

    for my $stop ($departure->route_post) {
        printf(
            "%s  %s\n",
            $stop->time, $stop->name
        );
    }

=head1 VERSION

version 2.01

=head1 DESCRIPTION

Travel::Status::DE::URA::Stop describes a single stop of a departure's route.

=head1 METHODS

=head2 ACCESSORS

=over

=item $stop->datetime

DateTime object holding the arrival/departure date and time.

=item $stop->date

Arrival/departure date in dd.mm.YYYY format.

=item $stop->time

Arrival/departure time in HH:MM:SS format.

=item $stop->name

Stop name.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

Unknown.

=head1 SEE ALSO

Travel::Status::DE::URA(3pm).

=head1 AUTHOR

Copyright (C) 2015-2016 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
