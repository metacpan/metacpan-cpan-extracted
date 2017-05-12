package Time::Duration::Concise::Locale::it;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::it - Italian locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::it to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'secondo',
        'seconds' => 'secondi',
        'minute'  => 'minuto',
        'minutes' => 'minuti',
        'hour'    => 'ora',
        'hours'   => 'ore',
        'day'     => 'giorno',
        'days'    => 'giorni',
        'month'   => 'mese',
        'months'  => 'mesi',
        'year'    => 'anno',
        'years'   => 'anni'
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::it
