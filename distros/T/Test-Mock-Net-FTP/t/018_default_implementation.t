#!/usr/bin/perl -w
use strict;
use warnings;
use lib '.';
use t::Util;
use Test::More;



subtest 'default_implementation', sub {
    my @methods = all_methods_in_net_ftp();

    for my $method ( @methods ) {
        my $ftp = default_mock_prepare(
            $method => sub {
                # do_nothing
            }
        );
        {
            no strict 'refs';
            ok( $ftp->can("mock_default_$method"), $method );
        }
    }
    done_testing();
};

done_testing();

