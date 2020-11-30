
use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin '$Bin';
use lib "$Bin/..";

BEGIN { use_ok 't::SpiceParser'; }

my $sp = t::SpiceParser->new();
lives_ok { $sp->read("t/example-6.sp"); };
isa_ok( $sp->circuit_model('nmos'), 't::DeviceModel' );
isa_ok( $sp->circuit_model('inv'),  't::CircuitModel' );

#my $flat = $sp->circuit_model('fa')->flatten( box => [] );
#print $flat->explicate_contents;

done_testing;

