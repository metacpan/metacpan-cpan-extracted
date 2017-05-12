#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use WWW::ConfixxBackup;

my $ftp_user = 'renee';
my $pass     = 'secret';
my $server   = 'server';
my $seconds  = 1800;

my $cb = WWW::ConfixxBackup->new(
    ftp_user       => $ftp_user,
    password       => $pass,
    confixx_server => $server,
    waiter         => $seconds,
);

is $cb->ftp_user, $ftp_user;
is $cb->password, $pass;
is $cb->ftp_password, $pass;
is $cb->confixx_password, $pass;
is $cb->confixx_server, $server;
is $cb->waiter, $seconds;