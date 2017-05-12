#!perl

use strict;
use warnings;

use Test::More tests => 2;

use VS::Chart;

my $chart = VS::Chart->new();

$chart->add(10, 10, 10);
$chart->add(20, 20, 20);

my $td;

$chart->render(type => 'line', as => 'png', to => sub { 
    my ($self, $data) = @_;
    $td .= $data;
});

ok(defined $td);
ok(length($td) > 0);