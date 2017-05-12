package Inherit;

use Util::Any -Base;
use Clone qw/clone/;

our $Utils = $Util::Any::Utils;

$Utils->{cpan_l2s} = [
    ['List::Util', '', {
        first  => 'l2s_first',
        max    => 'l2s_max',
        maxstr => 'l2s_maxstr',
        min    => 'l2s_min',
        minstr => 'l2s_minstr',
        sum    => 'l2s_sum',
        minmax => 'l2s_minmax',
    }],
    ['List::MoreUtils', '', {
        any      => 'l2s_any',
        all      => 'l2s_all',
        none     => 'l2s_none',
        notall   => 'l2s_notall',
        true     => 'l2s_true',
        false    => 'l2s_false',
        firstidx => 'l2s_firstidx',
        firstval => 'l2s_firstval',
        lastidx  => 'l2s_lastidx',
        lastval  => 'l2s_lastval'
    }],
];

1;
