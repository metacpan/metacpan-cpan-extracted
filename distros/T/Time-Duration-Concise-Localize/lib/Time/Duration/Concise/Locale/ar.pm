package Time::Duration::Concise::Locale::ar;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::ar - Arabic locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::ar to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => 'ثانية',
        'seconds' => 'ثوانى',
        'minute'  => 'دقيقة',
        'minutes' => 'دقائق',
        'hour'    => 'ساعة',
        'hours'   => 'ساعات',
        'day'     => 'يوم',
        'days'    => 'أيام',
        'month'   => 'شهر',
        'months'  => 'شهور',
        'year'    => 'عام',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::ar
