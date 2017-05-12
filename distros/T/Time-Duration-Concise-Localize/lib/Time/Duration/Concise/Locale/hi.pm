package Time::Duration::Concise::Locale::hi;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::hi - Hindi - India locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::hi to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'सेकंड',
        'seconds' => 'सेकंड',
        'minute'  => 'मिनट',
        'minutes' => 'मिनट',
        'hour'    => 'घंटे',
        'hours'   => 'घंटे',
        'day'     => 'दिन',
        'days'    => 'दिन',
        'month'   => 'माह',
        'months'  => 'माह',
        'year'    => 'साल',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::hi
