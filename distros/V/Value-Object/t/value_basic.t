#!/usr/bin/perl

use Test::More tests => 2;
use Test::Exception;

use strict;
use warnings;

use Value::Object;

can_ok( 'Value::Object', 'new', 'value' );
throws_ok { Value::Object->new() } qr/^Value::Object/, "Creating the base Value::Object not allowed";

