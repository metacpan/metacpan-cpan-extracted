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

subtest 'Cancel Transfer That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->delete_domain_transfer_by_id( 999999999 );
    } qr/No matching order found/, 'Throws on deleting transfer that does not exist';
};

subtest 'Cancel Completed Transfer' => sub {
    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    $mocked_logic_boxes->mock( 'submit', sub {
        croak 'Invalid action status/action type for this operation';
    });

    throws_ok {
        $logic_boxes->delete_domain_transfer_by_id( 999999999 );
    } qr/Unable to delete/, 'Throws on deleting transfer that does not exist';
};

subtest 'Cancel Cancellable Transfer' => sub {
    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    $mocked_logic_boxes->mock( 'submit', sub {
        return {
            result => "Success"
        };
    });

    lives_ok {
        $logic_boxes->delete_domain_transfer_by_id( 12345 );
    } 'Lives through deleting domain transfer';
};

done_testing;
