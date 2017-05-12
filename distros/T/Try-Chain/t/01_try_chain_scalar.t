#!perl -T
use strict;
use warnings;

use Test::More tests => 30;
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
            my $scalar = try_chain { return __PACKAGE__->new->string };
            is
                $scalar,
                'foo',
                'call method';
        },
        '...->new->string';
    lives_ok
        sub {
            my $scalar = try_chain { return __PACKAGE__->new->array_ref->[0] };
            is
                $scalar,
                'item',
                'fetch index';
        },
        '...->new->array_ref->[0]';
    lives_ok
        sub {
            my $scalar = try_chain { return __PACKAGE__->new->hash_ref->{key} };
            is
                $scalar,
                'value',
                'fetch key';
        },
        '...->new->hash_ref->{key}';
}

BROKEN_CHAIN: {
    lives_ok
        sub {
            my $scalar = try_chain { return undef()->nothing->string };
            is
                $scalar,
                undef,
                'undef 1st';
        },
        'undef()->nothing->string';
    lives_ok
        sub {
            my $scalar = try_chain { return __PACKAGE__->nothing->string };
            is
                $scalar,
                undef,
                'undef 2nd';
        },
        '...->nothing->string';
    lives_ok
        sub {
            my $scalar = try_chain { return __PACKAGE__->nothing->[0] };
            is
                $scalar,
                undef,
                'fetch index';
        },
        '...->nothing->[0]';
    lives_ok
        sub {
            my $scalar = try_chain { return __PACKAGE__->nothing->{key} };
            is
                $scalar,
                undef,
                'fetch key';
        },
        '...->nothing->{key}';
}

NO_AUTOVIVIFIVCATION: {
    lives_ok
        sub {
            my $foo;
            my $scalar = try_chain {
                no autovivification;
                return $foo->{bar}[0];
            };
            is
                $foo,
                undef,
                'autovivification';
        },
        '...->{bar}[0]';
}

TRY_CHAIN_CATCH_FINALLY: {
    lives_ok
        sub {
            my $scalar = try_chain { __PACKAGE__->new->string }
                catch { $_ }
                finally { ok 1, 'finally' };
            is
                $scalar,
                'foo',
                'try_chain ok, no catch, finally';
        },
        '...->new->string';
    lives_ok
        sub {
            my $scalar = try_chain { __PACKAGE__->nothing->string }
                catch { $_ }
                finally { ok 1, 'finally' };
            is
                $scalar,
                undef,
                'try_chain ok, no catch, finally';
        },
        '...->nothing->string';
    lives_ok
        sub {
            my $scalar
                = try_chain { die "error message\n" }
                    catch { $_ }
                    finally { ok 1, 'finally' };
            is
                $scalar,
                "error message\n",
                'try_chain not ok, catch, finally';
        },
        q{die 'error message'};
}

TRY_CATCH_FINALLY: {
    lives_ok
        sub {
            my $scalar = try { die "error message\n" }
                catch { $_ }
                finally { ok 1, 'finally' };
            is
                $scalar,
                "error message\n",
                'try not ok, catch, finally';
        },
        q{die 'error message'};
}
