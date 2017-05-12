#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Schedule;

use strict;
use warnings;

use lib 't/lib';

use DateTime;
use Test::More;
use Test::Exception;

use WebService::SendGrid::Newsletter;

use parent 'WebService::SendGrid::Newsletter::Test::Base';

my $start_dt;
my $list_name       = 'subscribers_test';
my $newsletter_name = 'Test Newsletter';

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    $self->SUPER::startup();

    # Create a new recipients list
    $self->sgn->lists->add(list => $list_name, name => 'name');

    $self->sgn->lists->email->add(
        list => $list_name,
        data => { name  => 'Some One', email => 'someone@example.com' }
    );

    my %newsletter = (
        name     => $newsletter_name,
        identity => 'This is my test marketing email',
        subject  => 'Your weekly newsletter',
        text     => 'Hello, this is your weekly newsletter',
        html     => '<h1>Hello</h1><p>This is your weekly newsletter</p>'
    );
    $self->sgn->add(%newsletter);

    if ($ENV{CAPTURE_DATA}) {
        # Give SendGrid some time for the changes to become effective
        sleep(60);
    }

    $self->sgn->recipients->add(name => $newsletter_name, list => $list_name);
}

sub shutdown : Test(shutdown) {
    my ($self) = @_;

    $self->SUPER::shutdown();

    $self->sgn->lists->delete(list => $list_name);
    $self->sgn->delete(name => $newsletter_name);

    if ($ENV{CAPTURE_DATA}) {
        print STDERR "Datetime: $start_dt\n";
    }
}

sub schedule : Tests {
    my ($self) = @_;

    throws_ok
        {
            $self->sgn->schedule->add->(list => $list_name);
        }
        qr/Required parameter 'name' is not defined/,
        'An exception is thrown when a required parameter is missing';

    my $dt;

    if ($ENV{CAPTURE_DATA}) {
        $start_dt = DateTime->now();
        $dt = $start_dt;
    } else {
        $dt = DateTime->new(
            year   => 2015,
            month  => 10,
            day    => 8,
            hour   => 10,
            minute => 52,
            second => 00,
        );
    }

    $dt->add(minutes => 2);

    $self->sgn->schedule->add(name => $newsletter_name, at => "$dt");
    $self->expect_success($self->sgn, 'Scheduling a specific delivery time');

    $self->sgn->schedule->add(name => $newsletter_name, after => 5);
    $self->expect_success($self->sgn, 'Scheduling delivery in a number of minutes');

    throws_ok
        {
            $self->sgn->schedule->add->();
        }
        qr/Required parameter 'name' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->schedule->get(name => $newsletter_name);
    ok($self->sgn->{last_response}->{date},
        'Date is set when retrieving a scheduled delivery');

    throws_ok
        {
            $self->sgn->schedule->delete->();
        }
        qr/Required parameter 'name' is not defined/, 
        'An exception is thrown when a required parameter is missing';


    $self->sgn->schedule->delete(name => $newsletter_name);
    $self->expect_success($self->sgn, 'Deleting a scheduled delivery');
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
                                           'date' => 'Thu, 08 Oct 2015 10:50:58 GMT',
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
                                       'name' => 'name',
                                       'api_key' => 'sendgrid_api_key',
                                       'list' => 'subscribers_test'
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
                                           'date' => 'Thu, 08 Oct 2015 10:50:59 GMT',
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
                                       'list' => 'subscribers_test'
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
                                           'date' => 'Thu, 08 Oct 2015 10:51:00 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/add.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
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
                                           'date' => 'Thu, 08 Oct 2015 10:52:00 GMT',
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
                                       'list' => 'subscribers_test'
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
                                           'date' => 'Thu, 08 Oct 2015 10:52:01 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/add.json',
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
                                       'at' => '2015-10-08T10:54:00',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/add.json',
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
                                           'date' => 'Thu, 08 Oct 2015 10:52:01 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/add.json',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'after' => '5',
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'Test+Newsletter',
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/add.json',
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
                                           'date' => 'Thu, 08 Oct 2015 10:52:01 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/get.json',
                            'content' => '{"date": "2015-10-08 10:57:01"}',
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
            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/get.json',
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
                                           'date' => 'Thu, 08 Oct 2015 10:52:02 GMT',
                                           'server' => 'nginx'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/delete.json',
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
                                       'api_key' => 'sendgrid_api_key'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/schedule/delete.json',
            'method' => 'POST'
          }
        ];
}

