#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 26;
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
  Hello => 'localhost',
);
$s->next_log_ok('EHLO', 'localhost', 'server received EHLO command');

$c->mail_from_ko('<baduser@gooddomain>', 'refuse bad sender');
$s->next_log_ok('MAIL', 'baduser@gooddomain', 'server received MAIL command');
$c->reset;

$c->mail_from_ko('<gooduser@baddomain>', 'refuse bad sender domain');
$s->next_log_ok('MAIL', 'gooduser@baddomain', 'server received MAIL command');
$c->reset;

$c->mail_from_ok('<gooduser@gooddomain>', 'accept good sender');
$s->next_log_ok('MAIL', 'gooduser@gooddomain', 'server received MAIL command');

$c->rcpt_to_ok('<gooduser@gooddomain>', 'accept good recipient');
$s->next_log_ok('RCPT', 'gooduser@gooddomain', 'server received RCPT command');
$c->rcpt_to_ko('<baduser@gooddomain>', 'refuse bad recipient');
$s->next_log_ok('RCPT', 'baduser@gooddomain', 'server received RCPT command');
$c->rcpt_to_ko('<gooduser@baddomain>', 'refuse bad recipient domain');
$s->next_log_ok('RCPT', 'gooduser@baddomain', 'server received RCPT command');

$c->data_ok('send DATA');
$c->datasend('bla...
bad mail content
bla bla bla...
');
$c->dataend_ko('must refuse bad mail content');
$s->next_log_ok('DATA', qr/bad mail content/, 'server received DATA command');

$c->quit_ok('send QUIT');
$s->next_log_ok('QUIT', undef, 'server received QUIT command');

$s->stop_ok('going down...');

