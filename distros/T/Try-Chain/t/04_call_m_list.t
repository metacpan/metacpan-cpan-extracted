#!perl -T
use strict;
use warnings;

use Test::More tests => 30;
use Test::Differences;
use Test::Exception;
use Test::NoWarnings;

BEGIN {
    use_ok
        'Try::Chain',
        qw( $call_m $call_em $fetch_i $fetch_ei $fetch_k $fetch_ek );
}

sub new {
    return bless {}, __PACKAGE__;
}
sub nothing {
    return;
}
sub string {
    return 'foo';
}
sub list {
    return qw( bar baz );
}
sub array_ref {
    return [ 'item' ];
}
sub hash_ref {
    return { key => 'value' };
}

OK: {
    lives_ok
        sub {
            my @list = __PACKAGE__->new->$call_m('list');
            eq_or_diff
                \@list,
                [ qw( bar baz ) ],
                'call method';
        },
        q{...->new->$call_m('list')};
    lives_ok
        sub {
            my @list = __PACKAGE__->new->$call_em('list');
            eq_or_diff
                \@list,
                [ qw( bar baz ) ],
                'call method';
        },
        q{...->new->$call_em('list')};
    lives_ok
        sub {
            my @list = __PACKAGE__->array_ref->$fetch_i(0);
            eq_or_diff
                \@list,
                [ 'item' ],
                'fetch index';
        },
        q{...->array_ref->$fetch_i(0)};
    lives_ok
        sub {
            my @list = __PACKAGE__->array_ref->$fetch_ei(0);
            eq_or_diff
                \@list,
                [ 'item' ],
                'fetch existing index';
        },
        q{...->array_ref->$fetch_ei(0)};
    lives_ok
        sub {
            my @list = __PACKAGE__->hash_ref->$fetch_k('key');
            eq_or_diff
                \@list,
                [ 'value' ],
                'fetch key';
        },
        q{...->hash_ref->$fetch_k('key')};
    lives_ok
        sub {
            my @list = __PACKAGE__->hash_ref->$fetch_ek('key');
            eq_or_diff
                \@list,
                [ 'value' ],
                'fetch existing key';
        },
        q{...->hash_ref->$fetch_k('key')};
}

BROKEN_CHAIN: {
    lives_ok
        sub {
            my @list = undef()->$call_m('list');
            eq_or_diff
                \@list,
                [],
                'call on undefined class';
        },
        q{undef()->$call_m('list')};
    lives_ok
        sub {
            my @list = __PACKAGE__->nothing->$call_m('list');
            eq_or_diff
                \@list,
                [],
                'call on undefined method result';
        },
        q{...->nothing->$call_m('list')};
    lives_ok
        sub {
            my @list = __PACKAGE__->nothing->$call_em('list');
            eq_or_diff
                \@list,
                [],
                'call on undefined method result';
        },
        q{...->nothing->$call_em('list')};
    lives_ok
        sub {
            my @list = __PACKAGE__->new->$call_em('list1');
            eq_or_diff
                \@list,
                [],
                'call not existing method';
        },
        q{...->new->$call_em('list1')};
    lives_ok
        sub {
            my @list = __PACKAGE__->nothing->$fetch_i(0);
            eq_or_diff
                \@list,
                [ undef ],
                'fetch index';
        },
        q{...->nothing->$fetch_i(0)};
    lives_ok
        sub {
            my @list = __PACKAGE__->array_ref->$fetch_ei(1);
            eq_or_diff
                \@list,
                [ undef ],
                'fetch not existing index';
        },
        q{...->array_ref->$fetch_ei(1)};
    lives_ok
        sub {
            my @list = __PACKAGE__->nothing->$fetch_k('key');
            eq_or_diff
                \@list,
                [ undef ],
                'fetch key';
        },
        q{...->nothing->$fetch_k('key')};
    lives_ok
        sub {
            my @list = __PACKAGE__->hash_ref->$fetch_ek('key1');
            eq_or_diff
                \@list,
                [ undef ],
                'fetch not existing key';
        },
        q{...->hash_ref->$fetch_ek('key1')};
}
