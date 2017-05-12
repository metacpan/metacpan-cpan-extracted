#!/usr/bin/perl

use strict;
use warnings;

BEGIN { delete $ENV{http_proxy} }

# workaround for HTTP::Tiny + Test::TCP
BEGIN { $INC{'threads.pm'} = 0 }
sub threads::tid { }
use HTTP::Tiny;
use Test::TCP;
BEGIN { delete $INC{'threads.pm'} }
BEGIN { $SIG{__WARN__} = sub { warn @_ if not $_[0] =~ /^Subroutine tid redefined/ } }

use Test::More;
use Plack::Test::Suite;

if ($^O eq 'MSWin32' and $] >= 5.016 and $] < 5.019005 and not $ENV{PERL_TEST_BROKEN}) {
    plan skip_all => 'Perl with bug RT#119003 on MSWin32';
    exit 0;
}

push @Plack::Test::Suite::TEST,
    [
        'sleep',
        sub {
            sleep 1;
            pass;
        },
        sub {
            # nothing
        },
    ];

Plack::Test::Suite->run_server_tests('Thrall', undef, undef, quiet => 1);

done_testing();
