#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Web::Solid::Test::HTTPLists;

use FindBin qw($Bin);


is(Web::Solid::Test::HTTPLists::_create_authorization_field('dAhUUt'), 'Bearer dAhUUt', 'Bearer token returned from string');

my $filename = $Bin . '/data/alice-token';

ok(-r $filename, "file can be read") || diag "File $filename could not be read";

is(Web::Solid::Test::HTTPLists::_create_authorization_field(URI->new('file://' . $filename)), 'Bearer FoBaR', 'Bearer token returned from file IRI');


done_testing;
