#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use WWW::ConfixxBackup;

my @versions = qw(confixx2.0 confixx3.0);

my $cb = WWW::ConfixxBackup->new(
    confixx_version => $versions[0],
);

is $cb->confixx_version, $versions[0];

$cb->confixx_version( $versions[1] );
is $cb->confixx_version, $versions[1];

is_deeply [$cb->available_confixx_versions], \@versions;
is $cb->default_confixx_version, $versions[1];
