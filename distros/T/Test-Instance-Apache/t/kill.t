use strict;
use warnings;

use FindBin qw /$Bin /;
use Test::More;
use Test::WWW::Mechanize;
use Test::Instance::Apache;

my $pid;

{
  my $instance = Test::Instance::Apache->new(
    config => [
      #Include "$Bin/conf/test.conf",
      "VirtualHost *" => [
        DocumentRoot => "$Bin/root",
        ServerName => "localhost",
      ],
    ],
    modules => [ qw/ mpm_prefork authz_core mime / ],
  );

  $instance->run;

  my $mech = Test::WWW::Mechanize->new;

  $mech->get_ok( "http://localhost:${\$instance->listen_port}/index.html" );
  $pid = $instance->pid;
  ok ( defined $pid, "Pid has been set" );
}

is ( kill( 0, $pid ), 0, "Pid has been successfully killed on destroy" );

done_testing;
