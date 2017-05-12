use strict;
use warnings;

use Test::LWP::UserAgent;
use Test::Fatal;
use Test::Spec;

BEGIN: {
    unless (use_ok('WWW::Saucelabs')) {
        BAIL_OUT("Couldn't load WWW-Saucelabs");
        exit;
    }
}

describe 'Saucelabs' => sub {
    my $c;

    before each => sub {
        $c = WWW::Saucelabs->new(
            user => 'user',
            access_key => 'access'
        );
    };

    describe 'client' => sub {
        it 'should be a knork' => sub {
            ok($c->_client->isa('Net::HTTP::Knork'));
        };
    };

    describe 'spec methods' => sub {
        they 'should all be handled' => sub {
            my $methods = $c->_spec->{methods};
            my @missing = ();

            foreach my $method_name (keys %$methods) {
                unless ($c->can($method_name)) {
                    push @missing, 'missing ' . $method_name . "\n"
                }
            }

            print @missing if @missing;
            is(scalar @missing, 0);
        }
    };

    describe 'endpoints' => sub {
        my ($mock_client, $tua, $return_endpoint);
        before each => sub {
            $tua = Test::LWP::UserAgent->new;
            $return_endpoint = sub {
                my ($req) = @_;
                my $res = Net::HTTP::Knork::Response->new('200','OK');
                $res->request( $req );
                return $res;
            };
            $tua->map_response(1, $return_endpoint);

            $mock_client = WWW::Saucelabs->new(
                user => 'user',
                access_key => 'access',
                _ua => $tua
            );
        };

        describe 'without auth' => sub {
            my $no_auth_endpoints = {
                get_sauce_status => 'http://saucelabs.com/rest/v1/info/status'
            };

            describe 'should use the correct endpoint:' => sub {
                foreach my $method_name (keys %$no_auth_endpoints) {
                    it $method_name => sub {
                        my $res = $mock_client->$method_name;
                        my $endpoint = $res->request->uri->as_string;
                        my $expected = $no_auth_endpoints->{$method_name};

                        cmp_ok($endpoint, 'eq', $expected);
                    }
                }
            };
        };

        describe 'with auth' => sub {
            it 'should have the username in the path' => sub {
                my $res = $mock_client->get_jobs;
                my $endpoint = $res->request->uri->path;
                cmp_ok($endpoint, '=~', qr{/rest/v1/user});
            };
        };

        describe 'for jobs' => sub {
            my $job_id = 'job_id';
            they 'should be fail-able' => sub {
                my $res = $mock_client->fail_job($job_id);
                my $endpoint = $res->request->uri->path;
                cmp_ok($endpoint, '=~', qr{/user/.*/$job_id});
            };

            they 'should be pass-able' => sub {
                my $res = $mock_client->pass_job($job_id);
                my $endpoint = $res->request->uri->path;
                cmp_ok($endpoint, '=~', qr{/user/.*/$job_id});
            };

            they 'should have a body when passing' => sub {
                my $res = $mock_client->pass_job($job_id);
                my $body = $res->request->body;
                ok($body->{status});
            };

            they 'should have a body when passing' => sub {
                my $res = $mock_client->fail_job($job_id);
                my $body = $res->request->body;
                ok(! $body->{status});
            };
        };
    };

    describe 'base url' => sub {
        my $expected_url = 'https://user:access@saucelabs.com/rest/v1';

        it 'should be properly constructed' => sub {
            is($c->_base_url, $expected_url);
        };
        it 'should be on the spec' => sub {
            is($c->_spec->{base_url}, $expected_url);
        };
    };
};

describe 'Authentication' => sub {
    my %default_env = %ENV;

    my %no_sauce_vars = %default_env;
    delete $no_sauce_vars{SAUCE_USERNAME};
    delete $no_sauce_vars{SAUCE_ACCESS_KEY};

    before each => sub { %ENV = %no_sauce_vars; };
    after all => sub { %ENV = %default_env; };

    describe failure => sub {
        it 'should throw without a user' => sub {
            $ENV{SAUCE_ACCESS_KEY} = 'fake-access-key';
            like(exception { WWW::Saucelabs->new }, qr/SAUCE_USERNAME/);
        };

        it 'should throw without an access key' => sub {
            $ENV{SAUCE_USERNAME} = 'fake-sauce-user';
            like(exception { WWW::Saucelabs->new }, qr/SAUCE_ACCESS_KEY/);
        };
    };

    describe 'success' => sub {
        my ($env_client, $user, $access);
        $user = 'env-user';
        $access = 'env-access';

        before each => sub {
            $ENV{SAUCE_USERNAME} = $user;
            $ENV{SAUCE_ACCESS_KEY} = $access;
        };

        it 'should be able to find everything in env vars' => sub {
            is(exception { $env_client = WWW::Saucelabs->new }, undef);
        };

        it 'should override env vars with constructor opts' => sub {
            $env_client = WWW::Saucelabs->new(
                user => 'user',
                access_key => 'access_key'
            );
            is($env_client->user, 'user');
            is($env_client->access_key, 'access_key');
        };
    };
};

xdescribe 'E2E' => sub {
    # $ export SAUCE_USERNAME=your-sauce-user
    # $ export SAUCE_ACCESS_KEY=your-sauce-access-key
    my $sauce;

    before each => sub { $sauce = WWW::Saucelabs->new; };

    it 'should get a list of jobs' => sub {
        my $jobs = $sauce->get_jobs({limit => 5 });
        ok(scalar $jobs);
    };
};

runtests;
