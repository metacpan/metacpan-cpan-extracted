#!/usr/bin/perl

use Test::More;
BEGIN { plan tests => 26 }

########################################################################
use strict ;
use warnings FATAL => qw(all);
use lib qw/t/ ;

use ExtUtils::testlib;
use Tie::Hash::CustomStorage;

package ObjTest;

sub new { bless {}, shift ;}

package main ;

ok(1);

########################################################################

{
  my %hash;

  my $msg = 'hello ' ;

  tie %hash, 'Tie::Hash::CustomStorage',
    init_storage => [ sub{ $ {$_[0]} = $_[1] }, $msg ] ;

  ok(1,'created utility tie hash with init') ;

  is($hash{one} , $msg, "checked default value" );

  $hash{two} .= 'world';

  is($hash{two}, $msg.'world',"checked default value + assignment") ;

  is(scalar keys %hash, 2, "checked nb of keys") ;
}

{
  my %hash;

  my $obj = tie %hash, 'Tie::Hash::CustomStorage',
    tie_hash => 'Tie::StdHash' ;

  my $msg = 'hello ' ;
  ok(1,'created utility tie hash with tie_hash') ;

  is(ref tied (%{$obj->{data}}), 'Tie::StdHash', 
    "checked type of tied hash within utility") ;

  $hash{one} = $msg ;
  is($hash{one} , $msg ,"checked value for key one" );

  $hash{two} .= 'world';

  is($hash{two}, 'world',"checked value for key two" ) ;

  is(scalar keys %hash, 2, "checked nb of keys") ;
}

{
  my %hash;

  tie %hash, 'Tie::Hash::CustomStorage',
    tie_storage => [ 'TieScalarTest', enum => [qw/A B C/], 
		     default => 'B'] ;

  ok(1,'created utility tie hash with tie_storage') ;

  is($hash{one} , 'B'  ,"checked default value for key one");

  $hash{two} = 'C';

  is($hash{two}, 'C',"checked assigned value for key one") ;

  is(scalar keys %hash, 2, "checked nb of keys") ;
}


{
  my %hash;

  tie %hash, 'Tie::Hash::CustomStorage',
    class_storage => 'ObjTest', 
      init_object => sub { $_[0]->{index} = $_[1]};

  ok(1, 'created utility tie hash with class_storage') ;

  my $t = $hash{one} ;
  isa_ok($t , 'ObjTest', "check autovivified object" );

  is($t->{index}, 'one', "check that init_object was called") ;

  $hash{two} = ObjTest -> new;

  ok(1,"object assignment worked");

  isa_ok($hash{two}, 'ObjTest', "check autovivified object") ;

  eval {$hash{three} = bless {}, 'Dummy'; } ;

  ok($@,"wrong object assignement rejected: $@") ;

}

{
  my %hash;

  my $tied_obj = tie %hash, 'Tie::Hash::CustomStorage',
    tie_storage => [ 'TieScalarTest', enum => [qw/A B C/], 
		     default => 'B'
		   ],
		     init_object => sub { $_[0]->{index} = $_[1]};

  ok(1,'created utility tie hash with tie_storage') ;

  is($hash{one} , 'B'  ,"checked default value for key one");

  $hash{two} = 'C';

  is($hash{two}, 'C',"checked assigned value for key one") ;

  is(scalar keys %hash, 2, "checked nb of keys") ;

  my $obj = $tied_obj->get_tied_storage_object('one') ;
  is(ref($obj), 'TieScalarTest', "check type of storage object") ;
  is($obj->{index}, 'one', "check that init_object was called") ;

}


1;
