#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'WWW-Trello-Lite';
license 'perl';
all_from 'lib/WWW/Trello/Lite.pm';

requires 'HTTP::Tiny'                   => '0.022';
requires 'Moose'                        => '1.21';
requires 'IO::Socket::SSL'              => '1.74';
requires 'Net::SSLeay'                  => '1.55';
requires 'Role::REST::Client'           => '0.10';
requires 'Role::REST::Client::Response' => '0.10';
requires 'URI::Escape'                  => '3.30';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Pod'  => '1.44';

auto_install;
WriteAll;
