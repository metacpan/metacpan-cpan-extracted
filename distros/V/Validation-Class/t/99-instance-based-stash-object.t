#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Test::More;

package T;
use Validation::Class;

field name => { required => 1 };

package main;

my $rules;

$rules = T->new;
$rules->stash('user_id' => 1234);
ok 1234 == $rules->stash('user_id'), 'stash key is 1234';

$rules = T->new;
ok ! $rules->stash('user_id'), 'stash key is empty';

done_testing();

