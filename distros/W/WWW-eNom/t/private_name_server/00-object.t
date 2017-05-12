#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::PrivateNameServer;

use Readonly;
Readonly my $CLASS => 'WWW::eNom::PrivateNameServer';

subtest "$CLASS is a well formed object" => sub {
    meta_ok( $CLASS );
};

subtest "$CLASS has the correct attributes" => sub {
    has_attribute_ok( $CLASS, 'name' );
    has_attribute_ok( $CLASS, 'ip' );
};

done_testing;
