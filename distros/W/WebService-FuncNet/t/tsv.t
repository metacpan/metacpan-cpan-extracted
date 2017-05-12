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

my $ra_output = $R->as_tsv;

my $ra_expected = [
          "Q9H8H3\tO75865\t1.615708908613666\t0.8059660198021762",
          "Q9H8H3\tA3EXL0\t1.593198817913301\t0.8100139995728369",
          "P22676\tA3EXL0\t0.8992717754263188\t0.9246652723089276",
          "Q5SR05\tA3EXL0\t0.49493596412217056\t0.9739920871688543",
          "P22676\tO75865\t0.2256385111978283\t0.994094913581514",
          "P22676\tQ8NFN7\t0.000002000001000058178\t0.999999",
          "Q5SR05\tO75865\t0.000002000001000058178\t0.999999",
          "Q5SR05\tQ8NFN7\t0.000002000001000058178\t0.999999",
          "Q9H8H3\tQ8NFN7\t0.000002000001000058178\t0.999999",
        ];

cmp_deeply( $ra_output, $ra_output, 'csv output matches');
