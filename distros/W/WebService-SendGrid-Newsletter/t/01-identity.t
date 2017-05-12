#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Identity;

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use WebService::SendGrid::Newsletter;

use parent 'WebService::SendGrid::Newsletter::Test::Base';

my $identity = 'Testing Address';
my $email    = 'someone@example.com';
my $new_name = 'The New Commpany Name';

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    $self->SUPER::startup();
}

sub identity : Tests {
    my ($self) = @_;

    throws_ok 
        {
            $self->sgn->identity->add(name => 'name')
        }
        qr/Required parameter 'identity' is not defined/, 
        'An exception is thrown when a required parameter is missing';


    $self->sgn->identity->add(
        identity => $identity,
        name     => 'A commpany name',
        email    => 'commpany@example.com',
        address  => 'Some street 123',
        city     => 'Hannover',
        zip      => '10220',
        state    => 'DEU',
        country  => 'Germany',
        replyto  => 'replythis@example.com',
    );
    $self->expect_success($self->sgn, 'Creating a new sender address');

    $self->sgn->identity->edit(
        identity    => $identity,
        name        => $new_name,
        email       => $email,
    );
    $self->expect_success($self->sgn, 'Editing a sender address');

    throws_ok 
        {
            $self->sgn->identity->get()
        }
        qr/Required parameter 'identity' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->identity->get(identity => $identity);
    is(
        $self->sgn->{last_response}->{name},
        $new_name, 
        'An expected name of sender is found'
    );
    $self->expect_success($self->sgn, 'Getting sender address');

    $self->sgn->identity->list(identity => $identity);
    is($self->sgn->{last_response}->[0]->{identity}, $identity, "$identity exists on the account");
    $self->expect_success($self->sgn, 'Checking if specific sender address exists');

    $self->sgn->identity->list();
    ok($self->sgn->{last_response}->[0]->{identity}, 'Get list of sender address');
    $self->expect_success($self->sgn, 'Listing sender addresses');

    throws_ok
        {
            $self->sgn->identity->delete()
        }
        qr/Required parameter 'identity' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->identity->delete(identity => $identity);
    $self->expect_success($self->sgn, 'Deleting sender address');
}

Test::Class->runtests;

sub mocked_data {
    my ($self) = @_;

    return [
          {
            'response' => {
                            'success' => 1,
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'x-frame-options' => 'DENY',
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Thu, 08 Oct 2015 11:19:06 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/identity/add.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'country' => 'Germany',
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'A+commpany+name',
                                       'api_key' => 'sendgrid_api_key',
                                       'state' => 'DEU',
                                       'email' => 'commpany@example.com',
                                       'zip' => '10220',
                                       'city' => 'Hannover',
                                       'identity' => 'Testing+Address',
                                       'address' => 'Some+street+123',
                                       'replyto' => 'replythis@example.com'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/identity/add.json',
            'method' => 'POST'
          },
          {
            'response' => {
                            'success' => 1,
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'x-frame-options' => 'DENY',
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Thu, 08 Oct 2015 11:19:06 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/identity/edit.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'email' => 'someone@example.com',
                                       'api_user' => 'sendgrid_api_user',
                                       'identity' => 'Testing+Address',
                                       'name' => 'The+New+Commpany+Name',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/identity/edit.json',
            'method' => 'POST'
          },
          {
            'response' => {
                            'success' => 1,
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'x-frame-options' => 'DENY',
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Thu, 08 Oct 2015 11:19:07 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/identity/get.json',
                            'content' => '{"city": "Hannover", "name": "The New Commpany Name", "zip": "10220", "replyto": "replythis@example.com", "country": "Germany", "state": "DEU", "address": "Some street 123", "email": "someone@example.com", "identity": "Testing Address"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'identity' => 'Testing+Address',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/identity/get.json',
            'method' => 'POST'
          },
          {
            'response' => {
                            'success' => 1,
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'x-frame-options' => 'DENY',
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Thu, 08 Oct 2015 11:19:07 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/identity/list.json',
                            'content' => '[{"identity": "Testing Address"}]',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'identity' => 'Testing+Address',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/identity/list.json',
            'method' => 'POST'
          },
          {
            'response' => {
                            'success' => 1,
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'x-frame-options' => 'DENY',
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Thu, 08 Oct 2015 11:19:07 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/identity/list.json',
                            'content' => '[{"identity": "This is my test marketing email"},{"identity": "Testing Address"}]',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/identity/list.json',
            'method' => 'POST'
          },
          {
            'response' => {
                            'success' => 1,
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'x-frame-options' => 'DENY',
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Thu, 08 Oct 2015 11:19:09 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/identity/delete.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'identity' => 'Testing+Address',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/identity/delete.json',
            'method' => 'POST'
          }
        ];
}
