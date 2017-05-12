use strict;
use Wiki::Toolkit::TestConfig::Utilities;
use Wiki::Toolkit;
use URI::Escape;

# Note - update the count in the skip block to match the number here
#        we would put the number in a variable, but that doesn't seem to work
use Test::More tests =>
  (3 + 14 * $Wiki::Toolkit::TestConfig::Utilities::num_stores);

use_ok( "Wiki::Toolkit::Feed::Atom" );

eval { my $atom = Wiki::Toolkit::Feed::Atom->new; };
ok( $@, "new croaks if no wiki object supplied" );

eval {
        my $atom = Wiki::Toolkit::Feed::Atom->new( wiki => "foo" );
     };
ok( $@, "new croaks if something that isn't a wiki object supplied" );

my %stores = Wiki::Toolkit::TestConfig::Utilities->stores;

my ($store_name, $store);
while ( ($store_name, $store) = each %stores ) {
  SKIP: {
      skip "$store_name storage backend not configured for testing", 14
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
              recent_changes_link => "http://example.com/?RecentChanges",
              atom_link => "http://example.com/?action=rc;format=atom",
      );
      my $atom = eval {
          Wiki::Toolkit::Feed::Atom->new( %default_config, site_url => "http://example.com/kakeswiki/" );
      };
      is( $@, "",
         "'new' doesn't croak if wiki object and mandatory parameters supplied"
      );
      isa_ok( $atom, "Wiki::Toolkit::Feed::Atom" );

      my $feed = eval { $atom->node_all_versions; };
      is( $@, "", "->node_all_versions doesn't croak" );

      # Should be empty to start with
      unlike($feed, qr|<entry>|, "no entry items as empty" );


      # Now retry with a node name
      $feed = eval { $atom->node_all_versions(name=>'Test Node 1'); };
      is( $@, "", "->node_all_versions doesn't croak with a name" );

      # Should only have it once
      my @items = $feed =~ /(\<\/entry\>)/g;
      is( scalar @items, 1, "Only found it once" );

      # And should have the name
      like( $feed, qr|<title>Test Node 1</title>|, "Found right node" );

      # And the be the first version
      like( $feed, '/<link href=".*?;version=1" \/>/', "And right version" );
      #like( $feed, qr|<modwiki:version>1</modwiki:version>|, "And right version" );


      # Now try again, with a 2 version node
      $feed = eval { $atom->node_all_versions(name=>'Old Node'); };
      is( $@, "", "->node_all_versions doesn't croak with a name" );

      # Check we found two versions
      @items = $feed =~ /(\<\/entry\>)/g;
      is( scalar @items, 2, "Found it twice" );

      # Both the right name
      @items = $feed =~ /(<title>Old Node<\/title>)/g;
      is( scalar @items, 2, "Had the right name" );

      # And the right version
      like( $feed, '/<link href=".*?;version=2" \/>/', "And right version" );
      like( $feed, '/<link href=".*?;version=1" \/>/', "And right version" );
      #like( $feed, qr|<modwiki:version>2</modwiki:version>|, "And right version" );
      #like( $feed, qr|<modwiki:version>1</modwiki:version>|, "And right version" );

      # And in the right order
      like( $feed, '/;version=2.*;version=1/s', "Right order" );
      #like( $feed, '/<modwiki:version>2<\/modwiki:version>.*<modwiki:version>1<\/modwiki:version>/s', "Right order" );

  }
}
