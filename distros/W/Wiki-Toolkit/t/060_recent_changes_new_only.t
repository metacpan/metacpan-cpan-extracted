use strict;
use Wiki::Toolkit::Store::Database;
use Wiki::Toolkit::TestLib;
use DBI;
use Test::More;
use Time::Piece;
use Time::Seconds;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 10 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

# These tests are for the "new_only" parameter to ->list_recent_changes.
# We set things up so that we have the following nodes:
# - Ae Pub, in the Pubs category, added 8 days ago, edited 2 days ago and today
# - Ae Bar, in the Bars category, added 5 days ago, edited today
# - Ae Restaurant, in the Restaurants category, added today
# - Ae Nother Pub, in the Pubs category, added today
# Also, make it so the categories of these things were only added today.

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Store the time now, so we have a timestamp which precedes "today"'s
    # additions and edits.
    my $start_time = time;
    my $slept = sleep(2);
    warn "Slept for less than a second; test results may be unreliable"
        unless $slept >= 1;

    # Set up the data and run the tests.
    setup_nodes( wiki => $wiki );

    my @nodes = $wiki->list_recent_changes(
        days => 4,
    );
    my @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names,
               [ "Ae Bar", "Ae Nother Pub", "Ae Pub", "Ae Restaurant" ],
               "all nodes returned when new_only omitted" );

    @nodes = $wiki->list_recent_changes(
        days     => 4,
        new_only => 0,
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names,
               [ "Ae Bar", "Ae Nother Pub", "Ae Pub", "Ae Restaurant" ],
               "...and when it's set to false" );

    @nodes = $wiki->list_recent_changes(
        days     => 4,
        new_only => 1,
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Nother Pub", "Ae Restaurant" ],
       "nodes edited but not added in last n days are omitted with new_only" );

    @nodes = $wiki->list_recent_changes(
        between_days => [ 1, 6 ],
        include_all_changes => 1, # to make between_days work - bug?
        new_only     => 1,
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Bar" ],
               "...and this works for between_days too" );

    @nodes = $wiki->list_recent_changes(
        since    => $start_time,
        new_only => 1,
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Nother Pub", "Ae Restaurant" ],
               "...and for since" );

    @nodes = $wiki->list_recent_changes(
        last_n_changes => 3,
        new_only       => 1,
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Bar", "Ae Nother Pub", "Ae Restaurant" ],
               "...and for last n" );

    @nodes = $wiki->list_recent_changes(
        days        => 2,
        new_only    => 1,
        metadata_is => { category => "Pubs" },
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Nother Pub" ],
               "combination of days and metadata_is omits things edited but "
               . "not added in recent days" );

    # Ae Bar wasn't in the Bars category when it was added, but it is now.
    @nodes = $wiki->list_recent_changes(
        days           => 6,
        new_only       => 1,
        metadata_is    => { category => "Bars" },
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Bar" ],
               "...and includes the things it should include" );

    @nodes = $wiki->list_recent_changes(
        days           => 6,
        new_only       => 1,
        metadata_wasnt => { category => "Bars" },
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Bar", "Ae Nother Pub", "Ae Restaurant" ],
               "...and metadata_wasnt works too" );

    # Ae Nother Pub was the only pub added to the Pubs category on creation.
    @nodes = $wiki->list_recent_changes(
        days           => 10,
        new_only       => 1,
        metadata_was   => { category => "Pubs" },
    );
    @names = sort map { $_->{name} } @nodes;
    is_deeply( \@names, [ "Ae Nother Pub" ],
               "combination of new_only and metadata_was omits things which "
               . "didn't have the relevant data when they were created" );

}

sub get_timestamp {
    my %args = @_;
    my $days = $args{days};
    my $now = localtime; # overloaded by Time::Piece
    my $time = $now - ( $days * ONE_DAY );
    return Wiki::Toolkit::Store::Database->_get_timestamp( $time );
}

sub setup_nodes {
    my %args = @_;
    my $wiki = $args{wiki};

    # For "Ae Pub", write directly to the database so we can fake having
    # written something in the past (white box testing).  It might be a good
    # idea at some point to factor this out into Wiki::Toolkit::TestLib, as
    # it's used in other tests too.

    my $dbh = $wiki->store->dbh;
    my $content_sth = $dbh->prepare("INSERT INTO content
                                    (node_id,version,text,modified)
                                    VALUES (?,?,?,?)");
    my $node_sth = $dbh->prepare("INSERT INTO node
                                 (id,name,version,text,modified)
                                 VALUES (?,?,?,?,?)");

    $node_sth->execute( 10, "Ae Pub", 2, "foo", get_timestamp( days => 2 ) )
        or die $dbh->errstr;
    $content_sth->execute( 10, 2, "foo", get_timestamp( days => 2 ) )
        or die $dbh->errstr;
    $content_sth->execute( 10, 1, "foo", get_timestamp( days => 8 ) )
        or die $dbh->errstr;

    # Now write it as per usual, to get the categories in.
    my %data = $wiki->retrieve_node( "Ae Pub" );
    $wiki->write_node( "Ae Pub", $data{content}, $data{checksum},
                       { category => [ "Pubs" ] } )
      or die "Couldn't write Ae Pub node";

    # Now do Ae Bar the same way.
    $node_sth->execute( 20, "Ae Bar", 1, "foo", get_timestamp( days => 5 ) )
        or die $dbh->errstr;
    $content_sth->execute( 20, 1, "foo", get_timestamp( days => 5 ) )
        or die $dbh->errstr;
    %data = $wiki->retrieve_node( "Ae Bar" );
    $wiki->write_node( "Ae Bar", $data{content}, $data{checksum},
                       { category => [ "Bars" ] } )
      or die "Couldn't write Ae Bar node";

    # The other nodes are simple.
    $wiki->write_node( "Ae Restaurant", "lalalalala", undef,
                       { category => [ "Restaurants" ] } )
      or die "Couldn't write Ae Restaurant node";
    $wiki->write_node( "Ae Nother Pub", "beer", undef,
                       { category => [ "Pubs" ] } )
      or die "Couldn't write Ae Nother Pub node";
}
