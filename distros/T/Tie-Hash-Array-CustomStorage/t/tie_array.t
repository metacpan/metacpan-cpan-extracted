#!/usr/bin/perl

use Test::More;
BEGIN { plan tests => 26 }

########################################################################
use strict ;
use warnings FATAL => qw(all);
use lib qw/t/ ;

use ExtUtils::testlib;
use Tie::Array::CustomStorage;

package ObjTest;

sub new { bless {}, shift ;}

package main ;

ok(1);

########################################################################

{
  my @array;

  my $msg = 'hello ' ;

  tie @array, 'Tie::Array::CustomStorage',
    init_storage => [ sub{ $ {$_[0]} = $_[1] }, $msg ] ;

  ok(1,'created utility tie array with init') ;

  is($array[0] , $msg, "checked default value" );

  $array[1] .= 'world';

  is($array[1], $msg.'world',"checked default value + assignment") ;

  is( @array, 2, "checked nb of keys") ;
}

{
  my @array;

  my $obj = tie @array, 'Tie::Array::CustomStorage',
    tie_array => 'Tie::StdArray' ;

  my $msg = 'hello ' ;
  ok(1,'created utility tie array with tie_array') ;

  is(ref tied (@{$obj->{data}}), 'Tie::StdArray', 
    "checked type of tied array within utility") ;

  $array[0] = $msg ;
  is($array[0] , $msg ,"checked value for key 0" );

  $array[1] .= 'world';

  is($array[1], 'world',"checked value for key two" ) ;

  is( @array, 2, "checked nb of keys") ;
}

{
  my @array;

  tie @array, 'Tie::Array::CustomStorage',
    tie_storage => [ 'TieScalarTest', enum => [qw/A B C/], 
		     default => 'B'] ;

  ok(1,'created utility tie array with tie_storage') ;

  is($array[0] , 'B'  ,"checked default value for key 0");

  $array[1] = 'C';

  is($array[1], 'C',"checked assigned value for key 0") ;

  is( @array, 2, "checked nb of keys") ;
}


{
  my @array;

  tie @array, 'Tie::Array::CustomStorage',
    class_storage => 'ObjTest', 
      init_object => sub { $_[0]->{index} = $_[1]};

  ok(1, 'created utility tie array with class_storage') ;

  my $t = $array[0] ;
  isa_ok($t , 'ObjTest', "check autovivified object" );

  is($t->{index}, '0', "check that init_object was called") ;

  $array[1] = ObjTest -> new;

  ok(1,"object assignment worked");

  isa_ok($array[1], 'ObjTest', "check autovivified object") ;

  eval {$array[2] = bless {}, 'Dummy'; } ;

  ok($@,"wrong object assignement rejected: $@") ;

}

{
  my @array;

  my $tied_obj = tie @array, 'Tie::Array::CustomStorage',
    tie_storage => [ 'TieScalarTest', enum => [qw/A B C/], 
		     default => 'B'
		   ],
		     init_object => sub { $_[0]->{index} = $_[1]};

  ok(1,'created utility tie array with tie_storage') ;

  is($array[0] , 'B'  ,"checked default value for key 0");

  $array[1] = 'C';

  is($array[1], 'C',"checked assigned value for key 0") ;

  is( @array, 2, "checked nb of keys") ;

  my $obj = $tied_obj->get_tied_storage_object('0') ;
  is(ref($obj), 'TieScalarTest', "check type of storage object") ;
  is($obj->{index}, '0', "check that init_object was called") ;

}


1;
