#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use Test::Mock::Net::FTP;

Test::Mock::Net::FTP::mock_prepare(
    'somehost.example.com' => {
        'user1' => {
            password => 'secret',
        },
        'user2' => {
            password => 'secret2',
        }
    },
    'host2.example.com' => {
        'userX' => {
            password => 'secretX',
        }

    },
);

subtest 'invalid host', sub {
    ok( !defined Test::Mock::Net::FTP->new('invalidhost.example.com') );
    done_testing();
};

subtest 'login to somehost', sub {
    my $ftp = Test::Mock::Net::FTP->new('somehost.example.com');
    ok( defined $ftp);
    ok( $ftp->login('user1', 'secret') );
    ok( !$ftp->login('invalid', 'invalid') );
    is( $ftp->message, 'Login incorrect.');
    ok( $ftp->close );
    done_testing();
};


subtest 'login to host2', sub {
    my $ftp = Test::Mock::Net::FTP->new('host2.example.com');
    ok( defined $ftp);
    ok( $ftp->login('userX', 'secretX') );
    ok( $ftp->close );
    done_testing();
};


done_testing();
