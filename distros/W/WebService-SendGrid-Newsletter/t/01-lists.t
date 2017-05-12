#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Lists;

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;

use WebService::SendGrid::Newsletter;

use parent 'WebService::SendGrid::Newsletter::Test::Base';

my $list_name       = 'Test List';
my $new_list_name   = 'New Test List';
my $name            = 'Test List Name';

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    $self->SUPER::startup();
}

sub list : Tests {
    my ($self) = @_;

    throws_ok
        {
            $self->sgn->lists->add->();
        }
        qr/Required parameter 'list' is not defined/,
        'An exception is thrown when a required parameter is missing';

    $self->sgn->lists->add(list => $list_name, name => $name);
    $self->expect_success($self->sgn, 'Adding a new list');

    $self->sgn->lists->add(list => $list_name, name => $name);
    $self->expect_success($self->sgn, 'Adding a duplicate new list');
    is(
        $self->sgn->{last_response}->{error},
        "$list_name already exists",
        'An error response message is returned when the list name already exists'
    );

    $self->sgn->lists->edit(list => $list_name, newlist => $new_list_name);
    $self->expect_success($self->sgn, 'Editing list name');
    
    $self->sgn->lists->get();
    ok($self->sgn->{last_response}->[0]->{list}, 'List is found');
    $self->expect_success($self->sgn, 'Getting lists');

    $self->sgn->lists->get(list => $new_list_name);
    $self->expect_success($self->sgn, "$list_name already exists");

    throws_ok
        {
            $self->sgn->lists->email->add(list => $new_list_name)
        }
        qr/Required parameter 'data' is not defined/, 
        'An exception is thrown when a required parameter is missing';
    
    $self->sgn->lists->email->add(
        list => $new_list_name,
        data => { 
            name  => 'Some One', 
            email => 'someone@example.com' 
        }
    );
    $self->expect_success($self->sgn, 'Adding a new email');

    throws_ok
        {
            $self->sgn->lists->delete->();
        }
        qr/Required parameter 'list' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->lists->delete(list => $new_list_name);
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
                                           'date' => 'Thu, 08 Oct 2015 11:19:10 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/lists/add.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'Test+List+Name',
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
                                           'date' => 'Thu, 08 Oct 2015 11:19:10 GMT',
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
                                       'name' => 'Test+List+Name',
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
                                           'date' => 'Thu, 08 Oct 2015 11:19:10 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/lists/edit.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'newlist' => 'New+Test+List',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/lists/edit.json',
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
                                           'date' => 'Thu, 08 Oct 2015 11:19:11 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/lists/get.json',
                            'content' => '[{"list": "New Test List", "id": 44341881},{"list": "subscribers", "id": 38060302},{"list": "Test Category List", "id": 38116483}]',
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
            'url' => 'https://api.sendgrid.com/api/newsletter/lists/get.json',
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
                                           'date' => 'Thu, 08 Oct 2015 11:19:11 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/lists/get.json',
                            'content' => '[{"list": "New Test List", "id": 44341881}]',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'New+Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/lists/get.json',
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
                                           'date' => 'Thu, 08 Oct 2015 11:19:12 GMT',
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
                                       'list' => 'New+Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/lists/email/add.json',
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
                                           'date' => 'Thu, 08 Oct 2015 11:19:12 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/lists/delete.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'New+Test+List'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/lists/delete.json',
            'method' => 'POST'
          }
        ];
}