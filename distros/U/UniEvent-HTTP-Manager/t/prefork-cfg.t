use 5.012;
use warnings;

use lib 't/lib';
use UniEvent::HTTP::Manager;
use Test::More;

my $l = UE::Loop->default;

my $mgr = UniEvent::HTTP::Manager->new({
    worker_model => UniEvent::HTTP::Manager::WORKER_PREFORK,
    min_servers  => 1,
    max_servers  => 1,
    server       => { locations => [{host => '127.0.0.1', port => 0}], },
}, $l);

my $cfg = $mgr->config;
note explain $cfg;
is_deeply $cfg, {
    'activity_timeout'      => 0,
    'check_interval'        => '1',
    'force_worker_stop'     => 1,
    'load_average_period'   => 3,
    'max_load'              => $cfg->{max_load},
    'max_requests'          => 0,
    'max_servers'           => 1,
    'max_spare_servers'     => 0,
    'min_load'              => $cfg->{min_load},
    'min_servers'           => 1,
    'min_spare_servers'     => 0,
    'min_worker_ttl'        => 60,
    'termination_timeout'   => 10,
    'worker_model'          => 0,
    'server'                => {
      'idle_timeout'            => 300000,
      'max_body_size'           => $cfg->{server}->{max_body_size},
      'max_headers_size'        => 16384,
      'max_keepalive_requests'  => 0,
      'tcp_nodelay'             => 0,
      'locations'               => [
        {
          'backlog'     => 4096,
          'domain'      => 2,
          'host'        => '127.0.0.1',
          'port'        => 0,
          'reuse_port'  => 1,
          'sock'        => undef,
          'ssl_ctx'     => undef,
        }
      ],
    },
};
ok (abs($cfg->{max_load} - 0.6999999) < 0.00001);
ok (abs($cfg->{min_load} - 0.3499999) < 0.00001);

done_testing;
