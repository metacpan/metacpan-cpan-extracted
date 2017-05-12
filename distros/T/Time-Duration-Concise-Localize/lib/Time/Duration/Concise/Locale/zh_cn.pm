package Time::Duration::Concise::Locale::zh_cn;

use 5.006;
use strict;
use warnings FATAL => 'all';
use utf8;

our $VERSION = '2.61';    ## VERSION

=head1 NAME

Time::Duration::Concise::Locale::zh_cn - Chinese - China locale translation.

=head1 DESCRIPTION

Time::Duration::Concise uses Time::Duration::Concise::Locale::zh_cn to localize concise time duration string representation.

=head1 METHODS

=head2 translation

Localized translation hash

=cut

sub translation {
    my ($self) = @_;
    return {
        'second'  => '秒钟',
        'seconds' => '秒钟',
        'minute'  => '分钟',
        'minutes' => '分钟',
        'hour'    => '小时',
        'hours'   => '小时',
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

1;    # End of Time::Duration::Concise::Locale::zh_cn
