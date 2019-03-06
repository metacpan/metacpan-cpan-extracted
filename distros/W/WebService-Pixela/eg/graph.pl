#!/usr/bin/env perl
use strict;
use warnings;

use WebService::Pixela;

my $pixela = WebService::Pixela->new(token => $ENV{TOKEN}, username => $ENV{USER_NAME});

my $id = $ENV{GRAPH_ID};

my %params = (
    name     => 'test_graph',
    unit     => 'test',
    type     => 'int',
    color    => 'shibafu',
    timezone => 'Asia/Tokyo',
);

print $pixela->graph->id($ENV{GRAPH_ID})->create(%params)->{message} . "\n";

my $graps = $pixela->graph->get();
my $graphs_json = $pixela->decode(0)->graph->get();
$pixela->decode(1);

# if you write svg file...
# print $pixela->graph->get_svg ."\n";

$pixela->graph->update(color => 'kuro');

print $pixela->graph->html() . "\n";

my $pixels =  $pixela->graph->pixels();

#$pixela->graph->delete();
