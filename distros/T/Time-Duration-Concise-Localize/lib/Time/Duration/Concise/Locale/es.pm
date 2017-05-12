package Time::Duration::Concise::Locale::es;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::es - Spanish locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::es to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'segundo',
        'seconds' => 'segundos',
        'minute'  => 'minuto',
        'minutes' => 'minutos',
        'hour'    => 'hora',
        'hours'   => 'horas',
        'day'     => 'día',
        'days'    => 'días',
        'month'   => 'mes',
        'months'  => 'meses',
        'year'    => 'año',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::es
