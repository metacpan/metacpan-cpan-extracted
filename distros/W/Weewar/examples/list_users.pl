#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Weewar;

=head1 NAME

list_users.pl - list all Weewar users

=head1 USAGE

    list_users.pl

=cut

my @users = Weewar->all_users;

foreach (@users) {
    local $\ = "\n";
    local $, = " ";
    print $_->name, $_->rating;
}
