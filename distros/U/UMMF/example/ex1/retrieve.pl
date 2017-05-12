#!/usr/bin/perl

use strict;
use warnings;
use 5.6.0;

use Ex1::Ex1::A;

use Ex1::Storage; # Configuration for UMMF::Export::Perl::Tangram::Storage.
use Data::Dumper;

my $storage;

eval {
  $DB::single = 1;

  # Get the storage object.
  $storage = Ex1::Ex1::A->__storage;

  # Get the storage object.
  my $a1 = Ex1::Ex1::A->get('attr1' => 1);
  
  # Store object graph.
  print "store: object: \n", Data::Dumper->new([ $a1 ], [qw( $a1 )])->Dump, "\n";
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

