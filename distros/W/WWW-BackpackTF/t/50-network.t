#!/usr/bin/perl -w
use strict;
use warnings;

use Test::RequiresInternet 'backpack.tf' => 80;
use Test::More tests => 5;
use WWW::BackpackTF;

my $bp = WWW::BackpackTF->new;
my $user = $bp->get_users('76561198057056782');
is $user->{name}, 'gmariusx', '$user->{name} is correct';
ok exists $user->{$_}, "\$user->{$_} exists" for qw/steamid backpack_value backpack_update backpack_tf_reputation/;
