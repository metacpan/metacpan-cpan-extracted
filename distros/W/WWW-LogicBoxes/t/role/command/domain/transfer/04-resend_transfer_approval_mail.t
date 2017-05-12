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

subtest 'Request Resend of Transfer Approval Email - Invalid Domain' => sub {
    throws_ok {
        $logic_boxes->resend_transfer_approval_mail_by_id( 999999999 );
    } qr/No matching pending transfer order found/, 'Throws on invalid domain';
};

subtest 'Request Resend of Transfer Approval Email - Already Completed Transfer' => sub {
    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    $mocked_logic_boxes->mock( 'submit', sub {
        croak 'The current status of Transfer action for the domain name does not allow this operation';
    });

    throws_ok {
        $logic_boxes->resend_transfer_approval_mail_by_id( 999999999 );
    } qr/Domain is not pending admin approval/, 'Throws on completed transfer';
};

subtest 'Request Resend of Transfer Approval Email - Pending Unapproved Transfer' => sub {
    my $mocked_logic_boxes = Test::MockModule->new( 'WWW::LogicBoxes' );
    $mocked_logic_boxes->mock( 'submit', sub {
        return {
            result => 'true'
        };
    });

    lives_ok {
        $logic_boxes->resend_transfer_approval_mail_by_id( 12345 );
    } 'Lives through resending transfer approval email';
};

done_testing;
