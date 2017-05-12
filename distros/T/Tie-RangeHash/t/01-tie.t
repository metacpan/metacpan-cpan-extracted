#-*- mode: perl;-*-

# General tests using 'tie' interface for Tie::RangeHash
# 
# You will see warnings. This is intentional.

require 5.006;

use Test;

BEGIN { plan tests => 23, todo => [ ] }

use Tie::RangeHash 1.00;
ok(1);


{
  # tie
  my %hash;
  tie %hash, 'Tie::RangeHash';
  ok(1);

  # STORE

  $hash{'A,C'}  = 1;
  ok(1);

  $hash{'G,I'}  = 2;
  ok($hash{'H'}, 2);

  # EXISTS
  ok ( exists( $hash{'B'} ));
  ok (!exists( $hash{'D'} ));

  $hash{'D,F'} = undef;
  ok ( exists( $hash{'D'} ));
  ok (! $hash{'D'} );

  # STORE overlapping
  eval { $hash{'AA,B'} = 2; };
  ok($hash{'AA'} != 2);

  # check ranges (*TODO*)
  ok( $hash{'A,C'}, 1 );
  eval {
    ok( $hash{'A,B'}, 1 ); # These cause fatal errors now
    ok( $hash{'B,C'}, 1 );
  };

  # redfinition
  $hash{'A,C'} = 3;
  ok( $hash{'B'}, 3); # works now!

  # bad ranges
  eval {
    ok( !defined($hash{'B,D'}) ); # overlap before
    ok( !defined($hash{'1,B'}) ); # overlap after
    ok( !defined($hash{'1,E'}) ); # beyond!
  };

  ok( !defined($hash{'1,9'}) ); # not found

  # not found
  ok( !defined($hash{'CC'}) );
  ok( !defined($hash{'X'}) );

  # DELETE
  ok(!defined(delete( $hash{'H'} ) ) );
  eval {
    ok(!defined(delete( $hash{'H,J'} ) ) );
    ok(!defined(delete( $hash{'F,H'} ) ) );
  };

  ok(delete( $hash{'G,I'} ), 2);
  ok (!exists( $hash{'H'} ));

  ok(delete( $hash{'A,C'} ), 3);
  ok (!exists( $hash{'B'} ));
  ok (!exists( $hash{'AA,B'} ));

#  require Data::Dumper;
#  print Data::Dumper->Dump([\%hash]);

  # CLEAR

  $hash{'A,C'} = 10;
  %hash = ();
  ok(1);
  ok (!exists( $hash{'B'} ));

  # untie
  untie %hash;
  ok(1);
}



