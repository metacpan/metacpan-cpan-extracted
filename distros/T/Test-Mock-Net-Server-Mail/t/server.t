#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::SMTP;

use_ok('Test::Mock::Net::Server::Mail');

my $s = Test::Mock::Net::Server::Mail->new;
isa_ok( $s, 'Test::Mock::Net::Server::Mail' );

$s->start_ok;

isa_ok( $s->socket, 'IO::Socket::INET' );
cmp_ok( $s->port, '>=', 50000, 'must be running on a high port');
cmp_ok( $s->pid, '>=', 1, 'a server pid must be set');

my $c = Test::SMTP->connect_ok('connect to mock server on port '.$s->port,
  Host => $s->bind_address,
  Port => $s->port,
  AutoHello => 1,
  Timeout => 5,
);

$c->mail_from_ok('<gooduser@gooddomain>', 'accept good sender');
$c->mail_from_ko('<baduser@gooddomain>', 'refuse bad sender');
$c->mail_from_ko('<gooduser@baddomain>', 'refuse bad sender domain');

$c->rcpt_to_ok('<gooduser@gooddomain>', 'accept good recipient');
$c->rcpt_to_ko('<baduser@gooddomain>', 'refuse bad recipient');
$c->rcpt_to_ko('<gooduser@baddomain>', 'refuse bad recipient domain');

$c->data_ok('send DATA');
$c->datasend('bla...
bad mail content
bla bla bla...
');
$c->dataend_ko('must refuse bad mail content');

$c->quit_ok('send QUIT');

$s->stop_ok('going down...');

