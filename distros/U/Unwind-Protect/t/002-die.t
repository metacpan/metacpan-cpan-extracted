#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use Unwind::Protect;
use Test::Exception;

# XXX: If you insert code, be sure to adjust every subsequent line number!

my @calls;

throws_ok {
    unwind_protect { die "ahhh" }
      after => sub { push @calls, 'protected' };
} qr{^ahhh at .*002-die.* line 13\b};

is_deeply([splice @calls], ['protected']);

my ($package, $line);
eval {
    local $SIG{__DIE__} = sub { ($package, $line) = (caller)[0, 2] };

    unwind_protect { die "oh no" }
      after => sub { push @calls, 'protected' };
};

is($package, 'main');
is($line, 23);
is_deeply([splice @calls], ['protected']);

