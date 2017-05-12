package Time::Duration::Concise::Locale::fr;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::fr - French locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::fr to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'seconde',
        'seconds' => 'secondes',
        'minute'  => 'minute',
        'minutes' => 'minutes',
        'hour'    => 'heure',
        'hours'   => 'heures',
        'day'     => 'jour',
        'days'    => 'jours',
        'month'   => 'mois',
        'months'  => 'mois',
        'year'    => 'année',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::fr
