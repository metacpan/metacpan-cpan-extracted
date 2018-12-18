use strict;
use warnings;

use Test::More;
use Test::DNS;
use Test::Instance::DNS;

my $t_i_dns = Test::Instance::DNS->new(
  listen_addr => '127.0.0.1',
  zone_file => 't/etc/db.example.com'
);

$t_i_dns->run;

my $dns = Test::DNS->new(nameservers => ['127.0.0.1']);
$dns->object->port($t_i_dns->listen_port);

$dns->is_a('example.com' => '192.0.2.1');

done_testing;
