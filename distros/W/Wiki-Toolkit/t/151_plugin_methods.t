use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

use lib "t/lib";
use Wiki::Toolkit::Plugin::Foo;
use Wiki::Toolkit::Plugin::Bar;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 6 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    my $plugin = Wiki::Toolkit::Plugin::Foo->new;
    isa_ok( $plugin, "Wiki::Toolkit::Plugin::Foo" );
    isa_ok( $plugin, "Wiki::Toolkit::Plugin" );
    can_ok( $plugin, qw( datastore indexer formatter ) );

    $wiki->register_plugin( plugin => $plugin );
    ok( ref $plugin->datastore,
        "->datastore seems to return an object after registration" );
    is_deeply( $plugin->datastore, $wiki->store, "...the right one" );

    # Check that the datastore etc attrs are set up before on_register
    # is called.
    my $plugin_2 = Wiki::Toolkit::Plugin::Bar->new;
    eval { $wiki->register_plugin( plugin => $plugin_2 ); };
    is( $@, "", "->on_register can access datastore" );
}
