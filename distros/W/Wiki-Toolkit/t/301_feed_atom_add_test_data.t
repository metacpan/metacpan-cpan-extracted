use strict;

use Wiki::Toolkit::TestConfig::Utilities;
use Wiki::Toolkit;

use Test::More tests => $Wiki::Toolkit::TestConfig::Utilities::num_stores;

# Add test data to the stores.
my %stores = Wiki::Toolkit::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
    SKIP: {
      skip "$store_name storage backend not configured for testing", 1
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = Wiki::Toolkit->new( store => $store );

      # Write two versions of one node
      # The recent changes should only show it once though
      $wiki->write_node( "Old Node",
                         "First version of Old Node" );
      my %old_node = $wiki->retrieve_node("Old Node");
      $wiki->write_node( "Old Node",
                         "We will write at least 15 nodes after this one",
                         $old_node{'checksum'} );

      my $slept = sleep(2);
      warn "Slept for less than a second, 'days=n' test may pass even if buggy"
        unless $slept >= 1;

      for my $i ( 1 .. 15 ) {
          $wiki->write_node( "Temp Node $i", "foo" );
      }

      $slept = sleep(2);
      warn "Slept for less than a second, test results may not be trustworthy"
        unless $slept >= 1;

      $wiki->write_node( "Test Node 1",
                         "Just a plain test",
			 undef,
			 { username => "Kake",
			   comment  => "new node",
               category => [ 'TestCategory1', 'Meta' ]
			 }
		       );

      $slept = sleep(2);
      warn "Slept for less than a second, 'items=n' test may fail"
        unless $slept >= 1;

      $wiki->write_node( "Calthorpe Arms",
		         "CAMRA-approved pub near King's Cross",
		         undef,
		         { comment  => "Stub page, please update!",
		           username => "Kake",
			   postcode => "WC1X 8JR",
			   locale   => [ "Bloomsbury" ]
                         }
      );

      $wiki->write_node( "Test Node 2",
                         "Gosh, another test!",
                         undef,
                         {
                           username     => "nou",
                           comment      => "This is a minor edit.",
                           major_change => 0,
                         }
                       );

      pass "$store_name test backend primed with test data";
    }
}
