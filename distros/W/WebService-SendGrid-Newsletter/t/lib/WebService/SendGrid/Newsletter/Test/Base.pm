#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Base;

use strict;
use warnings;

use Test::More;
use parent 'Test::Class';

use Test::Mock::HTTP::Tiny;

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    Test::Mock::HTTP::Tiny->clear_mocked_data;

    if ($ENV{CAPTURE_DATA}) {
        $self->SKIP_ALL('SENDGRID_API_USER and SENDGRID_API_KEY are ' .
            'required to run live tests')
            unless $ENV{SENDGRID_API_USER} && $ENV{SENDGRID_API_KEY};
    }
    else {
        if ($self->can('mocked_data')) {
            Test::Mock::HTTP::Tiny->set_mocked_data($self->mocked_data);
        }
    }
}

sub shutdown : Test(shutdown) {
    my ($self) = @_;

    if ($ENV{CAPTURE_DATA}) {
        my $captured_data = Test::Mock::HTTP::Tiny->captured_data;

        for my $request (@$captured_data) {
            $request->{args}{content}{api_user} = 'sendgrid_api_user';
            $request->{args}{content}{api_key}  = 'sendgrid_api_key';
        }

        print STDERR Test::Mock::HTTP::Tiny->captured_data_dump;
    }    
}

my $sgn;

sub sgn {
    my ($self) = @_;

    $sgn ||= WebService::SendGrid::Newsletter->new(
        api_user => $self->sendgrid_api_user,
        api_key  => $self->sendgrid_api_key,
        json_options => { canonical => 1 },
    );
    return $sgn;
}

sub sendgrid_api_user {
    my ($self) = @_;

    return $ENV{CAPTURE_DATA} ? $ENV{SENDGRID_API_USER} : 'sendgrid_api_user';
}

sub sendgrid_api_key {
    my ($self) = @_;

    return $ENV{CAPTURE_DATA} ? $ENV{SENDGRID_API_KEY} : 'sendgrid_api_key';
}

sub expect_success {
    my ($self, $sgn, $test_name) = @_;
    
    if(ref $sgn->{last_response} eq 'HASH' && $sgn->{last_response}->{message}){
        is($sgn->{last_response}->{message}, 'success',
            $test_name . ' results in a successful response');   
    }
    is($sgn->{last_response_code}, 200,
        $test_name . ' results in a successful response code');
}

1;
