package Time::Duration::Concise::Locale::vi;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::vi - Vietnamese - Vietnam locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::vi to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'giây',
        'seconds' => 'giây',
        'minute'  => 'phút',
        'minutes' => 'phút',
        'hour'    => 'giờ',
        'hours'   => 'giờ',
        'day'     => 'ngày',
        'days'    => 'ngày',
        'month'   => 'tháng',
        'months'  => 'tháng',
        'year'    => 'năm',
        'years'   => 'năm',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::vi
