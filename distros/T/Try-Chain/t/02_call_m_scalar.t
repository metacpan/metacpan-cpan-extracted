#!perl -T
use strict;
use warnings;

use Test::More tests => 30;
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
            my $scalar = __PACKAGE__->new->$call_m('string');
            is
                $scalar,
                'foo',
                'call method';
        },
        q{...->new->$call_m('string')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->new->$call_em('string');
            is
                $scalar,
                'foo',
                'call method';
        },
        q{...->new->$call_em('string')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->array_ref->$fetch_i(0);
            is
                $scalar,
                'item',
                'fetch index';
        },
        q{...->array_ref->$fetch_i(0)};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->array_ref->$fetch_ei(0);
            is
                $scalar,
                'item',
                'fetch existing index';
        },
        q{...->array_ref->$fetch_ei(0)};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->hash_ref->$fetch_k('key');
            is
                $scalar,
                'value',
                'fetch key';
        },
        q{...->hash_ref->$fetch_k('key')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->hash_ref->$fetch_ek('key');
            is
                $scalar,
                'value',
                'fetch existing key';
        },
        q{...->hash_ref->$fetch_ek('key')};
}

BROKEN_CHAIN: {
    lives_ok
        sub {
            my $scalar = undef()->$call_m('string');
            is
                $scalar,
                undef,
                'call on undefined class';
        },
        q{undef()->$call_m('string')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->nothing->$call_m('string');
            is
                $scalar,
                undef,
                'call on undefined method result';
        },
        q{...->nothing->$call_m('string')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->nothing->$call_em('string');
            is
                $scalar,
                undef,
                'call on undefined method result';
        },
        q{...->nothing->$call_em('string')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->new->$call_em('string1');
            is
                $scalar,
                undef,
                'call not existing method';
        },
        q{...->new->$call_em('string1')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->nothing->$fetch_i(0);
            is
                $scalar,
                undef,
                'fetch index';
        },
        q{...->nothing->$fetch_i(0)};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->array_ref->$fetch_ei(1);
            is
                $scalar,
                undef,
                'fetch not existing index';
        },
        q{...->array_ref->$fetch_ei(1)};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->nothing->$fetch_k('key');
            is
                $scalar,
                undef,
                'fetch key';
        },
        q{...->nothing->$fetch_k('key')};
    lives_ok
        sub {
            my $scalar = __PACKAGE__->hash_ref->$fetch_ek('key1');
            is
                $scalar,
                undef,
                'fetch not existing key';
        },
        q{...->hash_ref->$fetch_ek('key1')};
}
