#!/usr/bin/env perl
use strict;
use warnings;

use WebService::Pixela;

my $pixela = WebService::Pixela->new(token => $ENV{TOKEN}, username => $ENV{USERNAME});

# set graph id
$pixela->graph->id('anatofuz-test');

$pixela->pixel->get(date => '20180915');
$pixela->pixel->update(date => '20180915', quantity => 50);

$pixela->pixel->increment(date => '20180915');
$pixela->pixel->decrement(date => '20180915');

$pixela->pixel->get(date => '20180915');
$pixela->pixel->delete(date => '20180915');
