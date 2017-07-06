#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use t::Util;
use Test::More;


subtest 'command_histories', sub {
    my @methods = ('ls', 'dir');

    my $ftp = default_mock_prepare(
        'ls'  => sub {},
        'dir' => sub {},
    );
    $ftp->ls('arg1');
    $ftp->dir('arg1', 'arg2');
    my $expected = [
        ['login', 'user1', 'secret'],
        ['ls', 'arg1'],
        ['dir', 'arg1', 'arg2']
    ];
    is_deeply( [$ftp->mock_command_history()], $expected);

    $ftp->mock_clear_command_history();
    is_deeply( [$ftp->mock_command_history()], []);
    done_testing();
};

subtest 'command_history', sub {
    my @methods = all_methods_in_net_ftp();

    for my $method ( @methods ) {

        my $ftp = default_mock_prepare(
            $method => sub {
                # do_nothing
            }
        );
        $ftp->mock_clear_command_history();# clear login history
        {
            no strict 'refs';
            $ftp->$method('arg1', 'arg2');
        }
        is_deeply( [$ftp->mock_command_history()], [ [$method, 'arg1', 'arg2'] ], $method );
        $ftp->mock_clear_command_history();
    }
    done_testing();
};

done_testing();

