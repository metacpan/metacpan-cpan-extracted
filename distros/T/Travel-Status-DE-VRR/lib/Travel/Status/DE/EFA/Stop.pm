package Travel::Status::DE::EFA::Stop;

use strict;
use warnings;
use 5.010;

no if $] >= 5.018, warnings => 'experimental::smartmatch';

use parent 'Class::Accessor';

our $VERSION = '1.14';

Travel::Status::DE::EFA::Stop->mk_ro_accessors(
	qw(arr_date arr_time dep_date dep_time name name_suf platform));

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = \%conf;

	return bless( $ref, $obj );
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA::Stop - Information about a stop (station) contained
in a Travel::Status::DE::EFA::Result's route

=head1 SYNOPSIS

    for my $stop ($departure->route_post) {
        printf(
            "%s -> %s : %40s %s\n",
            $stop->arr_time // q{     }, $stop->dep_time // q{     },
            $stop->name, $stop->platform
        );
    }

=head1 VERSION

version 1.14

=head1 DESCRIPTION

Travel::Status::DE::EFA::Stop describes a single stop of a departure's
route. It is solely based on the respective departure's schedule;
delays or changed platforms are not taken into account.

=head1 METHODS

=head2 ACCESSORS

=over

=item $stop->arr_date

arrival date (DD.MM.YYYY). undef if this is the first scheduled stop.

=item $stop->arr_time

arrival time (HH:MM). undef if this is the first scheduled stop.

=item $stop->dep_date

departure date (DD.MM.YYYY). undef if this is the final scehduled stop.

=item $stop->dep_time

departure time (HH:MM). undef if this is the final scehduled stop.

=item $stop->name

stop name with city prefix ("I<City> I<Stop>", for instance
"Essen RE<uuml>ttenscheider Stern").

=item $stop->name_suf

stop name without city prefix, for instance "RE<uuml>ttenscheider Stern".

=item $stop->platform

Platform name/number if available, empty string otherwise.

=back

=head2 INTERNAL

=over

=item $stop = Travel::Status::DE::EFA::Stop->new(I<%data>)

Returns a new Travel::Status::DE::EFA::Stop object.  You should not need to
call this.

=item $stop->TO_JSON

Allows the object data to be serialized to JSON.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

Travel::Status::DE::EFA(3pm).

=head1 AUTHOR

Copyright (C) 2015 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
