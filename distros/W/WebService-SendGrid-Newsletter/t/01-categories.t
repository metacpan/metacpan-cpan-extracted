#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Categories;

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;
use String::Random qw(random_regex);

use WebService::SendGrid::Newsletter;

use parent 'WebService::SendGrid::Newsletter::Test::Base';

my $category_name;
my $newsletter_name = 'Test Newsletter';

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    $self->SUPER::startup();

    # Requires an existing newsletter in order to assign recipient to
    $self->sgn->add(
        identity => 'This is my test marketing email',
        name     => $newsletter_name,
        subject  => 'Your weekly newsletter',
        text     => 'Hello, this is your weekly newsletter',
        html     => '<h1>Hello</h1><p>This is your weekly newsletter</p>'
    );

    if ($ENV{CAPTURE_DATA}) {
        # Sleep for a minute to allow the changes to become effective
        sleep(60);

        # Generate a new random category name
        $category_name = random_regex('[A-Z]{5}[a-z]{5}')
    }
    else {
        $category_name = 'AWCCSbuzcs';
    }
}

sub shutdown : Test(shutdown) {
    my ($self) = @_;

    $self->sgn->delete(name => $newsletter_name);

    $self->SUPER::shutdown();

    if ($ENV{CAPTURE_DATA}) {
        print STDERR "Category name: $category_name\n";
    }
}

sub categories : Tests {
    my ($self) = @_;

    throws_ok 
        { 
            $self->sgn->categories->create() 
        } 
        qr/Required parameter 'category' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->categories->create(category => $category_name);
    $self->expect_success($self->sgn, 'Creating a new category');
  
    throws_ok 
        { 
            $self->sgn->categories->add(category => $category_name);
        } 
        qr/Required parameter 'name' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->categories->add(category => $category_name, name => $newsletter_name);
    $self->expect_success($self->sgn, 'Assigning category to a newletter');

    $self->sgn->categories->list();
    $self->expect_success($self->sgn, 'Listing category');

    throws_ok
        {
            $self->sgn->categories->remove->();
        }
        qr/Required parameter 'name' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->categories->remove(category => $category_name, name => $newsletter_name);
    $self->expect_success($self->sgn, 'Removing a category');

}

Test::Class->runtests;

sub mocked_data {
    my ($self) = @_;

    return [
          {
            'response' => {
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/add.json',
                            'headers' => {
                                           'date' => 'Sun, 27 Sep 2015 19:23:43 GMT',
                                           'x-frame-options' => 'DENY',
                                           'transfer-encoding' => 'chunked',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'connection' => 'keep-alive',
                                           'content-type' => 'text/html',
                                           'server' => 'nginx'
                                         },
                            'success' => 1,
                            'protocol' => 'HTTP/1.1',
                            'content' => '{"message": "success"}',
                            'reason' => 'OK'
                          },
            'args' => {
                        'content' => {
                                       'name' => 'Test+Newsletter',
                                       'identity' => 'This+is+my+test+marketing+email',
                                       'subject' => 'Your+weekly+newsletter',
                                       'api_key' => 'sendgrid_api_key',
                                       'html' => '<h1>Hello</h1><p>This+is+your+weekly+newsletter</p>',
                                       'text' => 'Hello,+this+is+your+weekly+newsletter',
                                       'api_user' => 'sendgrid_api_user'
                                     },
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     }
                      },
            'method' => 'POST',
            'url' => 'https://api.sendgrid.com/api/newsletter/add.json'
          },
          {
            'url' => 'https://api.sendgrid.com/api/newsletter/category/create.json',
            'response' => {
                            'headers' => {
                                           'date' => 'Sun, 27 Sep 2015 19:24:44 GMT',
                                           'x-frame-options' => 'DENY',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'connection' => 'keep-alive',
                                           'server' => 'nginx',
                                           'content-type' => 'text/html'
                                         },
                            'reason' => 'OK',
                            'success' => 1,
                            'content' => '{"message": "success"}',
                            'protocol' => 'HTTP/1.1',
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/category/create.json'
                          },
            'method' => 'POST',
            'args' => {
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     },
                        'content' => {
                                       'api_key' => 'sendgrid_api_key',
                                       'api_user' => 'sendgrid_api_user',
                                       'category' => 'AWCCSbuzcs'
                                     }
                      }
          },
          {
            'url' => 'https://api.sendgrid.com/api/newsletter/category/add.json',
            'response' => {
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/category/add.json',
                            'success' => 1,
                            'content' => '{"message": "success"}',
                            'reason' => 'OK',
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'server' => 'nginx',
                                           'content-type' => 'text/html',
                                           'connection' => 'keep-alive',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'x-frame-options' => 'DENY',
                                           'date' => 'Sun, 27 Sep 2015 19:24:44 GMT'
                                         }
                          },
            'method' => 'POST',
            'args' => {
                        'content' => {
                                       'api_user' => 'sendgrid_api_user',
                                       'api_key' => 'sendgrid_api_key',
                                       'category' => 'AWCCSbuzcs',
                                       'name' => 'Test+Newsletter'
                                     },
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     }
                      }
          },
          {
            'url' => 'https://api.sendgrid.com/api/newsletter/category/list.json',
            'response' => {
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/category/list.json',
                            'headers' => {
                                           'server' => 'nginx',
                                           'content-type' => 'text/html',
                                           'connection' => 'keep-alive',
                                           'transfer-encoding' => 'chunked',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'x-frame-options' => 'DENY',
                                           'date' => 'Sun, 27 Sep 2015 19:24:44 GMT'
                                         },
                            'success' => 1,
                            'reason' => 'OK',
                            'content' => '[{"category": "ABLQOobviv"},{"category": "AWCCSbuzcs"},{"category": "DYPVMzxurz"},{"category": "FUQTGybdtf"},{"category": "GEBRDhjwkm"},{"category": "GQVHTnkctf"},{"category": "JRNBWdxvra"},{"category": "LMWEDrindh"},{"category": "LOFSPheyqa"},{"category": "MUYBRtohqa"},{"category": "OHHWQprcrt"},{"category": "PBANZufkqs"},{"category": "Promotion News"},{"category": "RDYPQezjhd"},{"category": "ROEQWhyuwz"},{"category": "UFKBOuutlp"},{"category": "UWRKXrtugr"},{"category": "VCHLJlhckh"},{"category": "WNBIIinjsj"},{"category": "WSLLUaxvtk"},{"category": "YAGUNzhgiy"},{"category": "YBNMLgjsop"}]',
                            'protocol' => 'HTTP/1.1'
                          },
            'method' => 'POST',
            'args' => {
                        'content' => {
                                       'api_key' => 'sendgrid_api_key',
                                       'api_user' => 'sendgrid_api_user'
                                     },
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     }
                      }
          },
          {
            'response' => {
                            'success' => 1,
                            'reason' => 'OK',
                            'content' => '{"message": "success"}',
                            'protocol' => 'HTTP/1.1',
                            'headers' => {
                                           'transfer-encoding' => 'chunked',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'x-frame-options' => 'DENY',
                                           'date' => 'Sun, 27 Sep 2015 19:24:45 GMT',
                                           'content-type' => 'text/html',
                                           'server' => 'nginx',
                                           'connection' => 'keep-alive'
                                         },
                            'status' => '200',
                            'url' => 'https://api.sendgrid.com/api/newsletter/category/remove.json'
                          },
            'method' => 'POST',
            'args' => {
                        'content' => {
                                       'api_key' => 'sendgrid_api_key',
                                       'api_user' => 'sendgrid_api_user',
                                       'name' => 'Test+Newsletter',
                                       'category' => 'AWCCSbuzcs'
                                     },
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     }
                      },
            'url' => 'https://api.sendgrid.com/api/newsletter/category/remove.json'
          },
          {
            'url' => 'https://api.sendgrid.com/api/newsletter/delete.json',
            'args' => {
                        'content' => {
                                       'name' => 'Test+Newsletter',
                                       'api_key' => 'sendgrid_api_key',
                                       'api_user' => 'sendgrid_api_user'
                                     },
                        'headers' => {
                                       'content-type' => 'application/x-www-form-urlencoded'
                                     }
                      },
            'method' => 'POST',
            'response' => {
                            'url' => 'https://api.sendgrid.com/api/newsletter/delete.json',
                            'status' => '200',
                            'headers' => {
                                           'server' => 'nginx',
                                           'content-type' => 'text/html',
                                           'connection' => 'keep-alive',
                                           'access-control-allow-origin' => 'https://sendgrid.com',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Sun, 27 Sep 2015 19:24:45 GMT',
                                           'x-frame-options' => 'DENY'
                                         },
                            'success' => 1,
                            'reason' => 'OK',
                            'content' => '{"message": "success"}',
                            'protocol' => 'HTTP/1.1'
                          }
          }
        ];
}
