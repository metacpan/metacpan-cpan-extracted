use strict;
use Wiki::Toolkit::Plugin::Categoriser;
use Wiki::Toolkit::TestLib;
use Test::More;

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;
if ( $iterator->number ) {
    plan tests => ( $iterator->number * 1 );
} else {
    plan skip_all => "No backends configured.";
}

while ( my $wiki = $iterator->new_wiki ) {
    print "#\n##### TEST CONFIG: Store: " . (ref $wiki->store) . "\n";

    my $categoriser = Wiki::Toolkit::Plugin::Categoriser->new;
    $wiki->register_plugin( plugin => $categoriser );

    $wiki->write_node( "Pub Food", "pubs that serve food", undef,
                        { category => [ "Pubs", "Food", "Category" ] } )
      or die "Can't write node";

    $wiki->write_node( "Restaurants", "places that serve food", undef,
                        { category => [ "Food", "Category" ] } )
      or die "Can't write node";

    my @subcategories = $categoriser->subcategories( category => "Pubs" );
    is_deeply( \@subcategories, [ "Pub Food" ],
     "->subcategories returns things that belong, and not things that don't" );
}
