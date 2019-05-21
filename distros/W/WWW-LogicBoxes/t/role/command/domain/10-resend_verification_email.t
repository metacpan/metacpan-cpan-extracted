#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::LogicBoxes::Domain qw( create_domain );
use Test::WWW::LogicBoxes qw( create_api );

my $logic_boxes = create_api;

subtest 'Attempt to Resend Email Verification For Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->resend_verification_email( id => 999999999 );
    } qr/No such domain/, 'Throws on domain does not exist';
};

subtest 'Attempt to Resend Email Verification For Already Verified Domain' => sub {
    my $domain        = create_domain();
    my $mocked_submit = Test::MockModule->new('WWW::LogicBoxes');
    $mocked_submit->mock( 'submit', sub {
        note('Mocked WWW::LogicBoxes->submit');

        return {
            raaVerificationStatus => 'Verified'
        };
    });

    throws_ok {
        $logic_boxes->resend_verification_email( id => $domain->id );
    } qr/Domain already verified/, 'Throws on domain already verified';

    $mocked_submit->unmock_all;
};

subtest 'Resend Email Verification For Domain Requiring Verification - Successful' => sub {
    my $domain = create_domain();

    my $response;
    lives_ok {
        $response = $logic_boxes->resend_verification_email( id => $domain->id );
    } 'Lives through resending of verification email';

    ok( $response, 'Successfully resent verification email' );
};

done_testing;
