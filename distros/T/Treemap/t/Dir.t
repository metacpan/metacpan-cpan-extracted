#!/usr/bin/perl -w

use Test::More 'no_plan';

use Treemap::Input::Dir;

my $dir = Treemap::Input::Dir->new;         # create an object
ok( defined $dir,                      "Successfully created object." );
ok( $dir->isa('Treemap::Input::Dir'),  "This object is of the correct class." );
is( $dir->load('./'), 1,               "We can recurse through the current working directory." );
