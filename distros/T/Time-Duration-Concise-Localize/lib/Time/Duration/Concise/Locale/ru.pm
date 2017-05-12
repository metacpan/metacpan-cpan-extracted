package Time::Duration::Concise::Locale::ru;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::ru - Russian locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::ru to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'секунд(ы)',
        'seconds' => 'секунд(ы)',
        'minute'  => 'минут(ы)',
        'minutes' => 'минут(ы)',
        'hour'    => 'час.',
        'hours'   => 'час.',
        'day'     => 'дн.',
        'days'    => 'дн.',
        'month'   => 'мес.',
        'months'  => 'мес.',
        'year'    => 'год(а)/лет',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::ru
