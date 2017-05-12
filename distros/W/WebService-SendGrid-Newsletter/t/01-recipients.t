#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Recipients;

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use WebService::SendGrid::Newsletter;

use parent 'WebService::SendGrid::Newsletter::Test::Base';

my $list_name       = 'Test List';
my $newsletter_name = 'Test Newsletter';

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    $self->SUPER::startup();

    # Create a new recipients list
    $self->sgn->lists->add(list => $list_name, name => 'name');

    # Requires an existing newsletter in order to assign recipient to
    $self->sgn->add(
        identity => 'This is my test marketing email',
        name     => $newsletter_name,
        subject  => 'Your weekly newsletter',
        text     => 'Hello, this is your weekly newsletter',
        html     => '<h1>Hello</h1><p>This is your weekly newsletter</p>'
    );

    if ($ENV{CAPTURE_DATA}) {
        # Give SendGrid some time for the changes to become effective
        sleep(60);
    }
}

sub shutdown : Test(shutdown) {
    my ($self) = @_;

    $self->SUPER::shutdown();

    $self->sgn->lists->delete(list => $list_name);
    $self->sgn->delete(name => $newsletter_name);

}

sub lists : Tests {
    my ($self) = @_;

    throws_ok
        {
            $self->sgn->recipients->add->();
        }
        qr/Required parameter 'name' is not defined/,
        'An exception is thrown when a required parameter is missing';

    $self->sgn->recipients->add(list => $list_name, name => $newsletter_name);
    $self->expect_success($self->sgn, 'Adding a new list');

    throws_ok
        {
            $self->sgn->recipients->get->();
        }
        qr/Required parameter 'name' is not defined/,
        'An exception is thrown when a required parameter is missing';

    $self->sgn->recipients->get(name => $newsletter_name);
    $self->expect_success($self->sgn, "Getting recipients of specific newsletter");

    throws_ok
        {
            $self->sgn->recipients->delete->();
        }
        qr/Required parameter 'name' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->recipients->delete(list => $list_name, name => $newsletter_name);
    $self->expect_success($self->sgn, 'Deleting a list');
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
                                           'date' => 'Thu, 08 Oct 2015 12:36:02 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/lists/add.json',
                            'content' => '{"error": "Test List already exists"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'name',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/lists/add.json',
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
                                           'date' => 'Thu, 08 Oct 2015 12:36:03 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/lists/email/add.json',
                            'content' => '{"inserted": 1}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'data' => '{"email":"someone@example.com","name":"Some+One"}',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/lists/email/add.json',
            'method' => 'POST'
          },
          {
            'response' => {
                            'success' => '',
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Thu, 08 Oct 2015 12:36:03 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '401',
                            'url' => 'https://api.sendgrid.com/api/newsletter/add.json',
                            'content' => '{"error": "Test Newsletter already exists"}',
                            'reason' => 'Unauthorized'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'identity' => 'This+is+my+test+marketing+email',
                                       'html' => '<h1>Hello</h1><p>This+is+your+weekly+newsletter</p>',
                                       'text' => 'Hello,+this+is+your+weekly+newsletter',
                                       'subject' => 'Your+weekly+newsletter',
                                       'name' => 'Test+Newsletter',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/add.json',
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
                                           'date' => 'Thu, 08 Oct 2015 12:37:04 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/recipients/add.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'Test+Newsletter',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/recipients/add.json',
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
                                           'date' => 'Thu, 08 Oct 2015 12:37:04 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/recipients/get.json',
                            'content' => '[{"list": "Test List"}]',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'Test+Newsletter',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/recipients/get.json',
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
                                           'date' => 'Thu, 08 Oct 2015 12:37:05 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/recipients/delete.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'Test+Newsletter',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/recipients/delete.json',
            'method' => 'POST'
          }
        ];
}
