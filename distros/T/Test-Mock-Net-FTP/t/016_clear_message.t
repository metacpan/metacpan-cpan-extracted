#!/usr/bin/perl -w
use strict;
use warnings;
use lib '.';
use t::Util;
use Test::More;


subtest 'clear message', sub {
    my @methods = all_methods_in_net_ftp();

    for my $method ( @methods ) {
        next if ( $method eq 'message' );# skip message method itself.

        my $ftp = default_mock_prepare(
            $method => sub {
                # do_nothing
            }
        );
        $ftp->{message} = 'message';
        {
            no strict 'refs';
            $ftp->$method();
        }
        is( $ftp->message, '', $method);# 'message' is cleared after called $method()
    }
    done_testing();
};

done_testing();

