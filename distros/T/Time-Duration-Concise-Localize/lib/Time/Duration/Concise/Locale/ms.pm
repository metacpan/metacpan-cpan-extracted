package Time::Duration::Concise::Locale::ms;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::ms - Malay - Malaysia locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::ms to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'kedua',
        'seconds' => 'saat',
        'minute'  => 'minit',
        'minutes' => 'minit',
        'hour'    => 'jam',
        'hours'   => 'jam',
        'day'     => 'hari',
        'days'    => 'hari',
        'month'   => 'bulan',
        'months'  => 'bulan',
        'year'    => 'tahun'
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::ms
