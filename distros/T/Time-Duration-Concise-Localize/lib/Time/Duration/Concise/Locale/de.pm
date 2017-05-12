package Time::Duration::Concise::Locale::de;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::de - German locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::de to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'Sekunde',
        'seconds' => 'Sekunden',
        'minute'  => 'Minute',
        'minutes' => 'Minuten',
        'hour'    => 'Stunde',
        'hours'   => 'Stunden',
        'day'     => 'Tag',
        'days'    => 'Tage',
        'month'   => 'Monat',
        'months'  => 'Monate',
        'year'    => 'Jahr',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::de
