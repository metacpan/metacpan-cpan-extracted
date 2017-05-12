#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

my $collection;

$collection = $mango->db('foo')->collection('bar');
is $collection->full_name, 'foo.bar', 'full name ok';

$collection = Test::Mock::Mango::Collection->new('baz');
is $collection->full_name, 'baz', 'full name ok';

done_testing();
