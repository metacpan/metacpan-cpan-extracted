#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );

use Carp;

my $logic_boxes = create_api();

subtest 'Submit Auth Code to Transfer That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->submit_auth_code(
            {
                id        => 999999999,
                auth_code => '9FP4HL79BMH9FVU5B',
            }
        );
    } qr/No matching order found/, 'Proper error on non-existing domain transfer';
};

subtest 'Arbitrary Error on Auth Code Submission' => sub {
    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    my $error_msg = 'Note: this is an arbitrary error message!';

    $mocked_logic_boxes->mock( 'submit', sub {
        croak $error_msg;
    });

    throws_ok {
        $logic_boxes->submit_auth_code(
            {
                id        => 999999999,
                auth_code => '9FP4HL79BMH9FVU5B',
            }
        );
    } qr/$error_msg/, 'Arbitrary error message passed as-is';
};

subtest 'Sucessfull Auth Code Submission' => sub {
    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    $mocked_logic_boxes->mock( 'submit', sub {
        return {
            result => 'Success'
        };
    });

    lives_ok {
        $logic_boxes->submit_auth_code(
            {
                id        => 999999999,
                auth_code => '9FP4HL79BMH9FVU5B',
            },
        );
    } 'Lives through auth code submission';
};

done_testing;
