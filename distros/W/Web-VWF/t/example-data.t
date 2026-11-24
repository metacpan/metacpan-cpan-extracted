#!/usr/bin/env perl

# The example site's databases, read through their data modules: index.csv (the
# people the contact form can reach, "!" separated and keyed on entry, which is
# what Web::VWF::Data::index expects) and states.csv (comma separated, keyed on
# state).

use strict;
use warnings;

use Test::Most;

use File::Spec;
use FindBin qw($Bin);

BEGIN {
	require lib;
	my $root = File::Spec->catdir($Bin, File::Spec->updir());
	lib->import(File::Spec->catdir($root, 'lib'), File::Spec->catdir($root, 'example', 'lib'));
}

use Database::Abstraction;
use Web::VWF::Data::index;
# The states driver is in example/data, its data in example/databases
require(File::Spec->catfile($Bin, File::Spec->updir(), 'example', 'data', 'states.pm'));

Database::Abstraction::init({ directory => File::Spec->catdir($Bin, File::Spec->updir(), 'example', 'databases') });

my $index = Web::VWF::Data::index->new();
is(($index->email({ entry => 'bob' }))[0], 'bob@example.com', 'index: the address of a person');
is_deeply([$index->email({ entry => 'nobody' })], [], 'index: nobody has no address');
ok($index->updated(), 'index: updated() has a value');

my $states = Web::VWF::Data::states->new();
is(scalar(@{$states->selectall_arrayref()}), 50, 'states: all 50');
is($states->fetchrow_hashref({ state => 'NY' })->{'name'}, 'New York', 'states: keyed on the two letter code');

done_testing();
