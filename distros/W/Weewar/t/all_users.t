#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 3;

use t::lib::WeewarTest;

my @users = Weewar->all_users;
is scalar @users, 2, 'got two users';
isa_ok $users[0], 'Weewar::User', 'first user';
is_deeply [map {$_->name} @users], [qw/jrockway test/], 'got jrockway and test';

