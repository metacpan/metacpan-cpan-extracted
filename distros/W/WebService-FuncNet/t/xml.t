use strict;
use warnings;

use Test::More tests => 3;

require "t/common_test_data.pl";

my $rah_data = get_test_data();

#############
####### TESTS

use_ok( 'WebService::FuncNet::Results');

my $R = WebService::FuncNet::Results->new( $rah_data );
isa_ok( $R, 'WebService::FuncNet::Results' );

my $got = $R->as_xml;

my $expected = '<results>
  <anon>
    <p1>Q9H8H3</p1>
    <p2>O75865</p2>
    <pv>0.8059660198021762</pv>
    <rs>1.615708908613666</rs>
  </anon>
  <anon>
    <p1>Q9H8H3</p1>
    <p2>A3EXL0</p2>
    <pv>0.8100139995728369</pv>
    <rs>1.593198817913301</rs>
  </anon>
  <anon>
    <p1>P22676</p1>
    <p2>A3EXL0</p2>
    <pv>0.9246652723089276</pv>
    <rs>0.8992717754263188</rs>
  </anon>
  <anon>
    <p1>Q5SR05</p1>
    <p2>A3EXL0</p2>
    <pv>0.9739920871688543</pv>
    <rs>0.49493596412217056</rs>
  </anon>
  <anon>
    <p1>P22676</p1>
    <p2>O75865</p2>
    <pv>0.994094913581514</pv>
    <rs>0.2256385111978283</rs>
  </anon>
  <anon>
    <p1>P22676</p1>
    <p2>Q8NFN7</p2>
    <pv>0.999999</pv>
    <rs>0.000002000001000058178</rs>
  </anon>
  <anon>
    <p1>Q5SR05</p1>
    <p2>O75865</p2>
    <pv>0.999999</pv>
    <rs>0.000002000001000058178</rs>
  </anon>
  <anon>
    <p1>Q5SR05</p1>
    <p2>Q8NFN7</p2>
    <pv>0.999999</pv>
    <rs>0.000002000001000058178</rs>
  </anon>
  <anon>
    <p1>Q9H8H3</p1>
    <p2>Q8NFN7</p2>
    <pv>0.999999</pv>
    <rs>0.000002000001000058178</rs>
  </anon>
</results>
';

is( 
   $got, 
   $expected, 
   'xml output matches'
);