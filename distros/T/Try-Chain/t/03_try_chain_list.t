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
        qw( try_chain try catch finally );
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
            my @list = try_chain { return __PACKAGE__->new->string };
            eq_or_diff
                \@list,
                [ 'foo' ],
                'call method';
        },
        '...->new->string';
    lives_ok
        sub {
            my @list = try_chain { return __PACKAGE__->new->array_ref->[0] };
            eq_or_diff
                \@list,
                [ 'item' ],
                'fetch index';
        },
        '...->new->array_ref->[0]';
    lives_ok
        sub {
            my @list = try_chain { return __PACKAGE__->new->hash_ref->{key} };
            eq_or_diff
                \@list,
                [ 'value' ],
                'fetch key';
        },
        '...->new->hash_ref->{key}';
}

BROKEN_CHAIN: {
    lives_ok
        sub {
            my @list = try_chain { return undef()->nothing->list };
            eq_or_diff
                \@list,
                [],
                'undef 1st';
        },
        'undef()->nothing->list';
    lives_ok
        sub {
            my @list = try_chain { return __PACKAGE__->nothing->list };
            eq_or_diff
                \@list,
                [],
                'undef 2nd';
        },
        '...->nothing->list';
    lives_ok
        sub {
            my @list = try_chain { return __PACKAGE__->nothing->[0] };
            eq_or_diff
                \@list,
                [], # not undef inside because method nothing or fetch array index can break
                'fetch index';
        },
        '...->nothing->[0]';
    lives_ok
        sub {
            my @list = try_chain { return __PACKAGE__->nothing->{key} };
            eq_or_diff
                \@list,
                [], # not undef inside because method nothing or fetch array index can break
                'fetch key';
        },
        '...->nothing->{key}';
}

NO_AUTOVIVIFIVCATION: {
    lives_ok
        sub {
            my $foo;
            my @list = try_chain {
                no autovivification;
                return $foo->{bar}[0];
            };
            eq_or_diff
                \@list,
                [ undef ],
                'autovivification';
        },
        '...->{bar}[0]';
}

TRY_CHAIN_CATCH_FINALLY: {
    lives_ok
        sub {
            my @list = try_chain { __PACKAGE__->new->string }
                catch { $_ }
                finally { ok 1, 'finally' };
            eq_or_diff
                \@list,
                [ 'foo' ],
                'try_chain ok, no catch, finally';
        },
        '...->new->string';
    lives_ok
        sub {
            my @list = try_chain { __PACKAGE__->nothing->string }
                catch { $_ }
                finally { ok 1, 'finally' };
            eq_or_diff
                \@list,
                [],
                'try_chain ok, no catch, finally';
        },
        '...->nothing->string';
    lives_ok
        sub {
            my @list
                = try_chain { die "error message\n" }
                    catch { $_ }
                    finally { ok 1, 'finally' };
            eq_or_diff
                \@list,
                [ "error message\n" ],
                'try_chain not ok, catch, finally';
        },
        q{die 'error message'};
}

TRY_CATCH_FINALLY: {
    lives_ok
        sub {
            my @list = try { die "error message\n" }
                catch { $_ }
                finally { ok 1, 'finally' };
            eq_or_diff
                \@list,
                [ "error message\n" ],
                'try not ok, catch, finally';
        },
        q{die 'error message'};
}
