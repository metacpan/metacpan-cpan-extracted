#!/usr/bin/env perl
use warnings;
use strict;

use XML::Compile::Tester;
use Test::More tests => 10;

use XML::Compile::RPC::Util;
 
#use Data::Dumper;
#$Data::Dumper::Indent = 1;

#### Structures

my @members =
  ( {name => 'symbol', value => {string => 'RHAT'}}
  , {name => 'limit', value => {double => 2.25}}
  , {name => 'expires', value =>
        { 'dateTime.iso8601' => '2002-07-09T20:00:00Z' }} );
my $struct = { member => \@members };

my $hash   = struct_to_hash $struct;
is_deeply($hash
         , { symbol  => 'RHAT'
           , limit   => 2.25
           , expires => '2002-07-09T20:00:00Z'
           }
         , 'struct_to_hash'
         );

my @rows   = struct_to_rows $struct;
is_deeply(\@rows
         , [ [ 'symbol',  'string', 'RHAT' ]
           , [ 'limit',   'double', '2.25' ]
           , [ 'expires', 'dateTime.iso8601', '2002-07-09T20:00:00Z' ]
           ]
         , 'struct_to_rows'
         );


my $struct2 = struct_from_rows @rows;
is_deeply($struct2, +{struct => $struct}, 'struct_from_rows');

my $struct3 = struct_from_hash string => { 'A'..'F' };
is_deeply($struct3,
 { struct => { member => [
      { value => { string => 'B' }, name => 'A' },
      { value => { string => 'D' }, name => 'C' },
      { value => { string => 'F' }, name => 'E' }
    ] }}, 'struct_from_hash');

### Arrays

my @arrvals  = ({string => 'RHAT'}, {double => 4.12}, {double => 4.25});
my $rpcarray = {data => {value => \@arrvals}};

is_deeply( [rpcarray_values $rpcarray]
         , ['RHAT', 4.12, 4.25]
         , 'rpcarray_values'
         );

is_deeply( rpcarray_from(int => 1..3)
         , {array => {data => {value => [{int => 1}, {int => 2}, {int => 3}]}}}
         , 'rpcarray_from'
         );

#### Faults

my $errmsg = 'Unknown stock symbol ABCD';
my @fmemb = ( {name => 'faultCode', value => {int => 23}}
            , {name => 'faultString', value => {string => $errmsg}} );
my $fault = +{value => { struct => { member => \@fmemb }}};

my ($rc,$rcmsg) = fault_code $fault;
is($rc, 23, 'faultCode');
is($rcmsg, $errmsg, 'faultString');

my $rc2 = fault_code $fault;
is($rc2, 23, 'faultCode scalar context');

my $fault2 = fault_from 23, $errmsg;
is_deeply($fault2, +{fault => $fault}, 'fault_from');
