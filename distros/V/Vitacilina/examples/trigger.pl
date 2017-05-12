#!/usr/bin/perl

use strict;
use warnings;

use Vitacilina;

my $v = Vitacilina->new(
	config => 'feeds.yaml',
	template => 'wiki.tt',
	limit => 20,
);

$v->render;

