use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 2 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    print "# Store type: " . ref($wiki->store) . "\n";

    $wiki->write_node( "Test 1", "test", undef,
                       {
                         username  => "Earle",
                       } );

    my @nodes = $wiki->list_recent_changes(
        days         => 7,
        metadata_was => {
                          username  => "earle",
                        },
        ignore_case  => 1,
    );
    my @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 1" ],
               "ignore_case => 1 ignores case of metadata value" );

    @nodes = $wiki->list_recent_changes(
        days         => 7,
        metadata_was => {
                          Username  => "Earle",
                        },
        ignore_case  => 1,
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 1" ],
               "ignore_case => 1 ignores case of metadata type" );
}
