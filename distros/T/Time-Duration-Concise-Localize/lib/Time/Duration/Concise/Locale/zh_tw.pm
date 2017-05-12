package Time::Duration::Concise::Locale::zh_tw;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::zh_tw - Traditional Chinese locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::zh_tw to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => '秒',
        'seconds' => '秒',
        'minute'  => '分鐘',
        'minutes' => '分鐘',
        'hour'    => '小時',
        'hours'   => '小時',
        'day'     => '天',
        'days'    => '天',
        'month'   => '月份',
        'months'  => '月份',
        'year'    => '年',
        'years'   => '年',
    };
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=cut

1;    # End of Time::Duration::Concise::Locale::zh_tw
