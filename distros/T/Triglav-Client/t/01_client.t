use strict;
use warnings;

use Test::More;
use Test::Stub;
use Test::Should;

use Triglav::Client;

sub client   ();
sub services ();
sub roles    ();
sub hosts    ();

sub describe { goto &Test::More::subtest }
sub context  { goto &Test::More::subtest }
sub it       { goto &Test::More::subtest }

describe 'Triglav::Client' => sub {
  describe '.initialize' => sub {
    context 'when no arguments are passed' => sub {
        client->should_be_a('Triglav::Client');
    };

    context 'when no arguments are passed' => sub {
        (sub { Triglav::Client->new })->should_throw(
            qr/Both `base_url` and `api_token` are required/
        );
    };

    context 'when only `base_url` is passed' => sub {
        (sub { Triglav::Client->new(base_url => 'http://example.com/') })->should_throw(
            qr/Both `base_url` and `api_token` are required/
        );
    };

    context 'when `api_token` is passed' => sub {
        (sub { Triglav::Client->new(api_token => 'xxxxxxxxxxxxxxxxxx') })->should_throw(
            qr/Both `base_url` and `api_token` are required/
        );
    };
  };

  describe '#services' => sub {
      my $client = client;
      stub($client)->dispatch_request(services);

      my $response = $client->services;
         $response->should_be_a('ARRAY');
         $response->should_have_length(scalar @{services()});
  };

  describe '#roles' => sub {
      my $client = client;
      stub($client)->dispatch_request(roles);

      my $response = $client->roles;
         $response->should_be_a('ARRAY');
         $response->should_have_length(scalar @{roles()});
  };

  describe '#roles_in' => sub {
      my $client = client;
      stub($client)->dispatch_request(roles);

      context 'when `service` is passed' => sub {
          my $response = $client->roles_in('triglav');
          $response->should_be_a('ARRAY');
          $response->should_have_length(scalar @{roles()});
      };

      context 'when `service` is not passed' => sub {
          (sub { $client->roles_in })->should_throw(
              qr/`service` is required/
          );
      };
  };

  describe '#hosts' => sub {
      my $client = client;
      stub($client)->dispatch_request(hosts);

      context 'and `with_inactive` option is not passed' => sub {
          my $response = $client->hosts;
             $response->should_be_a('ARRAY');
             $response->should_have_length(scalar(@{hosts()}) - 1);
      };

      context 'when `with_inactive` option passed as true' => sub {
          my $response = $client->hosts(with_inactive => 1);
             $response->should_be_a('ARRAY');
             $response->should_have_length(scalar @{hosts()});
      };
  };

  describe '#hosts_in' => sub {
      my $client = client;
      stub($client)->dispatch_request(hosts);

      context 'when `role` is passed' => sub {
          context 'and `with_inactive` option is not passed' => sub {
              my $response = $client->hosts_in('triglav', 'app');
                 $response->should_be_a('ARRAY');
                 $response->should_have_length(scalar(@{hosts()}) - 1);
          };

          context 'and `with_inactive` option passed as true' => sub {
              my $response = $client->hosts_in('triglav', 'app', with_inactive => 1);
                 $response->should_be_a('ARRAY');
                $response->should_have_length(scalar @{hosts()});
          };
      };

      context 'when `role` is not passed' => sub {
          context 'and `with_inactive` option is not passed' => sub {
              my $response = $client->hosts_in('triglav');
              $response->should_be_a('ARRAY');
              $response->should_have_length(scalar(@{hosts()}) - 1);
          };

          context 'and `with_inactive` option passed as true' => sub {
              (sub { $client->hosts_in('triglav', with_inactive => 1) })->should_throw(
                  qr/`role` must be passed \(even if it's not needed\) when you want to pass `%options`/
              );
          };
      };
  };

  describe '#dispatch_request' => sub {
      my $client = client;

      context 'when arguments are passed correctly' => sub {
          context 'and request is successfully dispatched' => sub {
              stub($client)->do_request('{ "result": "ok" }');

              my $response = $client->dispatch_request('get', '/foo');
                 $response->should_be_a('HASH');
                 $response->{result}->should_be_equal('ok');
          };

          context 'and request fails by an error' => sub {
              stub($client)->do_request(sub { die '403: 403 Forbidden' });

              (sub { $client->dispatch_request('get', '/foo')->() })->should_throw(
                  qr/403: 403 Forbidden/
              );
          };
      };

    context 'when arguments are not passed correctly' => sub {
      context 'and no arguments are passed' => sub {
          (sub { $client->dispatch_request }).should_throw(
              qr/Both `method` and `path` are required/
          );
        }
      };

      context 'and only `$method` is passed' => sub {
          (sub { $client->dispatch_request('get') })->should_throw(
              qr/Both `method` and `path` are required/
          );
      };

      subtest 'and only `$path` is passed' => sub {
          (sub { $client->dispatch_request(undef, '/foo') })->should_throw(
              qr/Both `method` and `path` are required/
          );
      };
  };
};

done_testing;

sub client () {
    Triglav::Client->new(
        base_url  => 'http://example.com/',
        api_token => 'xxxxxxxxxxxxxxxxxxx',
    );
}

sub services () {
    [
        { id => 1 },
        { id => 2 },
    ]
}

sub roles () {
    [
        { id => 1 },
        { id => 2 },
    ]
}

sub hosts () {
    [
        { id => 1, active => 1 },
        { id => 2, active => 0 },
        { id => 2, active => 1 },
    ]
}
