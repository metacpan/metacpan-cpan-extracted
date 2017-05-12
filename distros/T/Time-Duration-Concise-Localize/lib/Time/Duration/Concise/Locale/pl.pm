package Time::Duration::Concise::Locale::pl;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::pl - Polish locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::pl to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'sek.',
        'seconds' => 'sek.',
        'minute'  => 'minuta',
        'minutes' => 'min.',
        'hour'    => 'godzina',
        'hours'   => 'godziny',
        'day'     => 'dzień',
        'days'    => 'dni',
        'month'   => 'miesiąc',
        'months'  => 'miesiące',
        'year'    => 'rok',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::pl
