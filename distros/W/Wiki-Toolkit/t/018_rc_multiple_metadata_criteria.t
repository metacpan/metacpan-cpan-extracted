use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 6 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {

    $wiki->write_node( "Test 1", "test", undef,
                       {
                         username  => "Earle",
                         edit_type => "Minor tidying",
                       } );

    $wiki->write_node( "Test 2", "test", undef,
                       {
                         username  => "Kake",
                         edit_type => "Minor tidying",
                       } );

    $wiki->write_node( "Test 3", "test", undef,
                       {
                         username  => "Earle",
                       } );

    my @nodes = $wiki->list_recent_changes(
        days           => 7,
        metadata_was   => { username  => "Earle",
                            edit_type => "Minor tidying" }
    );
    my @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 1" ],
               "can supply multiple criteria to metadata_was" );
    @nodes = $wiki->list_recent_changes(
        days           => 7,
        metadata_wasnt => { username  => "Earle",
                            edit_type => "Minor tidying" }
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 2", "Test 3" ],
               "can supply multiple criteria to metadata_wasnt" );

    @nodes = $wiki->list_recent_changes(
        days           => 7,
        metadata_is    => { username  => "Earle",
                            edit_type => "Minor tidying" }
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 1" ],
               "can supply multiple criteria to metadata_is" );
    @nodes = $wiki->list_recent_changes(
        days           => 7,
        metadata_isnt  => { username  => "Earle",
                            edit_type => "Minor tidying" }
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 2", "Test 3" ],
               "can supply multiple criteria to metadata_isnt" );

    @nodes = $wiki->list_recent_changes(
        days           => 7,
        metadata_was   => { username => "Earle" },
        metadata_wasnt => { edit_type => "Minor tidying" },
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 3" ],
               "can supply both metadata_was and metadata_wasnt" );

    @nodes = $wiki->list_recent_changes(
        days           => 7,
        metadata_is    => { username => "Earle" },
        metadata_isnt  => { edit_type => "Minor tidying" },
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Test 3" ],
               "can supply both metadata_is and metadata_isnt" );
}
