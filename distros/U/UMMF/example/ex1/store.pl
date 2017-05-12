#!/usr/bin/perl

use strict;
use warnings;
use 5.6.0;

use Ex1::Ex1::A;
use Ex1::Ex1::B;
use Ex1::Ex1::C;
use Ex1::Ex1::D;

use Ex1::Storage; # Configuration for UMMF::Export::Perl::Tangram::Storage.
use Data::Dumper;

my $storage;

eval {
  $DB::single = 1;

  # Get the storage object.
  $storage = Ex1::Ex1::A->__storage;

  # Create a new object Graph.
  my $a1 = Ex1::Ex1::A->new('attr1' => 1, 'attr2' => 2.3);
  my $b1 = Ex1::Ex1::B->new('attr3' => 'Some string');
  $a1->add_b($b1);

  my $c1 = Ex1::Ex1::C->new(
			    'attr5' => [ 1, 2, 3, 4 ],
			    'attr6' => [ 5.6, 7.8, 9.10, 11.12 ],
			    'attr7' => 'c1',
			    );
  $a1->add_c($c1);

  my $c2 = Ex1::Ex1::C->new(
			    'attr5' => [ 13, ],
			    'attr6' => [ 15.16 ],
			    'attr7' => 'c2',
			    );
  $a1->add_c($c2);
  
  # Store object graph.
  print "store: object: \n", Data::Dumper->new([ $a1 ], [qw( $a1 )])->Dump, "\n";
  $DB::single = 1;
  $storage->insert($a1);
  print "store: object id: ", $storage->id($a1), "\n";
};
my $exc = $@;
if ( $exc ) {
  warn "Exception: $exc";
  $DB::single = 1;
}
$storage->disconnect if $storage;

exit 0;

