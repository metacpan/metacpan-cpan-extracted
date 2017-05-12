use strict;
use Wiki::Toolkit::TestConfig::Utilities;
use Wiki::Toolkit;
use URI::Escape;

# Note - update the count in the skip block to match the number here
#        we would put the number in a variable, but that doesn't seem to work
use Test::More tests =>
  (3 + 18 * $Wiki::Toolkit::TestConfig::Utilities::num_stores);

use_ok( "Wiki::Toolkit::Feed::RSS" );

eval { my $rss = Wiki::Toolkit::Feed::RSS->new; };
ok( $@, "new croaks if no wiki object supplied" );

eval {
        my $rss = Wiki::Toolkit::Feed::RSS->new( wiki => "foo" );
     };
ok( $@, "new croaks if something that isn't a wiki object supplied" );

my %stores = Wiki::Toolkit::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
  SKIP: {
      skip "$store_name storage backend not configured for testing", 18
          unless $store;

      print "#\n##### TEST CONFIG: Store: $store_name\n#\n";

      my $wiki = Wiki::Toolkit->new( store => $store );
      my %default_config = (
              wiki => $wiki,
              site_name => "Wiki::Toolkit Test Site",
              make_node_url => sub {
                                     my $id = uri_escape($_[0]);
                                     my $version = $_[1] || '';
                                     $version = uri_escape($version) if $version;
                                     "http://example.com/?id=$id;version=$version";
                                   },
              recent_changes_link => "http://example.com/recentchanges"
      );
      my $rss = eval {
          Wiki::Toolkit::Feed::RSS->new( %default_config, site_url => "http://example.com/kakeswiki/" );
      };
      is( $@, "",
         "'new' doesn't croak if wiki object and mandatory parameters supplied"
      );
      isa_ok( $rss, "Wiki::Toolkit::Feed::RSS" );

      my $feed = eval { $rss->generate_node_name_distance_feed; };
      is( $@, "", "->generate_node_name_distance_feed doesn't croak" );

      # Should be empty to start with
      is( 1, $feed =~ /\<items\>\s+\<rdf:Seq\>\s*\<\/rdf:Seq\>\s*\<\/items\>/s, "empty list with no node name" );

      # Should be RSS though
      like( $feed, qr/<rdf:RDF/, "Is RSS" );

      # Now retry with a single node
      my @nodes = ( {name=>'Test Node 1'} );
      $feed = eval { $rss->generate_node_name_distance_feed('12345',@nodes); };
      is( $@, "", "->generate_node_name_distance_feed doesn't croak with a single node" );

      # Should only have it once
      my @items = $feed =~ /(\<\/item\>)/g;
      is( scalar @items, 1, "Only found it once" );

      # And should have the name
      like( $feed, qr|<title>Test Node 1</title>|, "Found right node" );


      # Now try again, with two nodes, one with distances
      @nodes = ( {name=>'Test Node 1',distance=>'2 miles'}, {name=>'Old Node'} );

      $feed = eval { $rss->generate_node_name_distance_feed('12345',@nodes); };
      is( $@, "", "->generate_node_name_distance_feed doesn't croak with distances" );

      # Check we found two nodes
      @items = $feed =~ /(\<\/item\>)/g;
      is( scalar @items, 2, "Found two nodes" );

      # Both the right name
      my @items_a = $feed =~ /(<title>Test Node 1<\/title>)/g;
      my @items_b = $feed =~ /(<title>Old Node<\/title>)/g;
      is( scalar @items_a, 1, "Had the right name" );
      is( scalar @items_b, 1, "Had the right name" );

      # And only one had the distance
      @items = $feed =~ /(<space:distance>)/g;
      is( scalar @items, 1, "Only had distance once" );


      # Now with all the geo bits
      @nodes = ( {name=>'Test Node 1',distance=>'2 miles',latitude=>'1.23',longitude=>'-1.33',os_x=>'2345',os_y=>'5678'}, {name=>'Old Node'} );
      $feed = eval { $rss->generate_node_name_distance_feed('12345',@nodes); };
      is( $@, "", "->generate_node_name_distance_feed doesn't croak with full geo" );
      like( $feed, qr/space:os_x/, "Had os_x" );
      like( $feed, qr/space:os_y/, "Had os_y" );
      like( $feed, qr/geo:lat/, "Had latitude" );
      like( $feed, qr/geo:long/, "Had longitude" );
  }
}
