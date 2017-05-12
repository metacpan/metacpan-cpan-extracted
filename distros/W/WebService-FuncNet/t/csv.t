use strict;
use warnings;

use Test::More tests => 3;
use Test::Deep;

require "t/common_test_data.pl";
my $rah_data = get_test_data();

#############
####### TESTS

use_ok( 'WebService::FuncNet::Results');

my $R = WebService::FuncNet::Results->new( $rah_data );
isa_ok( $R, 'WebService::FuncNet::Results' );

my $ra_output = $R->as_csv;

my $ra_expected = [
          'Q9H8H3,O75865,1.615708908613666,0.8059660198021762',
          'Q9H8H3,A3EXL0,1.593198817913301,0.8100139995728369',
          'P22676,A3EXL0,0.8992717754263188,0.9246652723089276',
          'Q5SR05,A3EXL0,0.49493596412217056,0.9739920871688543',
          'P22676,O75865,0.2256385111978283,0.994094913581514',
          'P22676,Q8NFN7,0.000002000001000058178,0.999999',
          'Q5SR05,O75865,0.000002000001000058178,0.999999',
          'Q5SR05,Q8NFN7,0.000002000001000058178,0.999999',
          'Q9H8H3,Q8NFN7,0.000002000001000058178,0.999999'
        ];

cmp_deeply( $ra_output, $ra_output, 'csv output matches');
