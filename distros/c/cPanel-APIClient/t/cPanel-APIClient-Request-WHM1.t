#!/usr/bin/perl

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::cPanel::APIClient::Request::WHM1;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent 'TestBase';

use Test::More;
use Test::Deep;

use cPanel::APIClient::Request::WHM1;

__PACKAGE__->new()->runtests() if !caller;

sub test_get_cli_command : Tests(1) {
    my $req = cPanel::APIClient::Request::WHM1->new(
        'some_function_name',
        {
            arg1 => 'foo bar',
            arg2 => [ 234, 345 ],
        },
    );

    my @cli = $req->get_cli_command();

    cmp_deeply(
        \@cli,
        superbagof(
            'some_function_name',
            'arg1=foo%20bar',
            'arg2=234',
            'arg2=345',
        ),
        'get_cli_command() output',
    );

    return;
}

1;
