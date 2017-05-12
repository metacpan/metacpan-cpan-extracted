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
    plan tests => ( 4 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

# These tests are related to ticket #41: http://www.wiki-toolkit.org/ticket/41 
# "If you list the Recent Changes with minor edits excluded, then it
# returns not only the most recent changes, but also some more ancient
# changes to nodes that have been edited recently."
#
# We set things up so that we have the following nodes and edit types.  All
# nodes added "9 days ago".
# - Red Lion, edited 3 days ago (normal) and today (minor)
# - Blue Lion, edited 7 days ago (minor), 5 days ago (normal) & today (minor) 

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
               [ "Blue Lion", "Red Lion" ],
               "All nodes returned when no criteria given except time" );

    @nodes = $wiki->list_recent_changes(
        days         => 4,
        metadata_was => { edit_type => "Normal edit" },
    );
    my @names_vers = sort map { "$_->{name} (version $_->{version})" } @nodes;
    my %namehash = map { $_->{name} => 1 } @nodes;
    ok( !$namehash{"Blue Lion"},
       "Normal edits only: nodes not returned if not edited recently enough" );
    ok( $namehash{"Red Lion"}, "...those edited recently enough are returned");
    is_deeply( \@names_vers, [ "Red Lion (version 2)" ],
               "...but only their versions within the stated time period" );
    print "# Found nodes: " . join(", ", @names_vers) . "\n";
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

    # Write directly to the database so we can fake having
    # written something in the past (white box testing).  It might be a good
    # idea at some point to factor this out into Wiki::Toolkit::TestLib, as
    # it's used in other tests too.

    my $dbh = $wiki->store->dbh;
    my $content_sth = $dbh->prepare( "INSERT INTO content
                                     (node_id,version,text,modified)
                                     VALUES (?,?,?,?)");
    my $node_sth = $dbh->prepare( "INSERT INTO node
                                  (id,name,version,text,modified)
                                  VALUES (?,?,?,?,?)");
    my $md_sth = $dbh->prepare( "INSERT INTO metadata
                                 (node_id,version,metadata_type,metadata_value)
                                 VALUES (?,?,?,?)");

    # Red Lion first.
    $node_sth->execute( 10, "Red Lion", 2, "red 2",
                        get_timestamp( days => 3 ) )
        or die $dbh->errstr;
    $content_sth->execute( 10, 2, "red 2", get_timestamp( days => 3 ) )
        or die $dbh->errstr;
    $content_sth->execute( 10, 1, "red 1", get_timestamp( days => 9 ) )
        or die $dbh->errstr;
    $md_sth->execute( 10, 2, "edit_type", "Normal edit" );
    $md_sth->execute( 10, 1, "edit_type", "Normal edit" );

    # Now write it as per usual.
    my %data = $wiki->retrieve_node( "Red Lion" );
    $wiki->write_node( "Red Lion", "red 3", $data{checksum},
                       { edit_type => [ "Minor tidying" ] } )
      or die "Couldn't write Red Lion node";

    # Now Blue Lion.
    $node_sth->execute( 20, "Blue Lion", 3, "blue 3",
                        get_timestamp( days => 5 ) )
        or die $dbh->errstr;
    $content_sth->execute( 20, 3, "blue 3", get_timestamp( days => 5 ) )
        or die $dbh->errstr;
    $content_sth->execute( 20, 2, "blue 2", get_timestamp( days => 7 ) )
        or die $dbh->errstr;
    $content_sth->execute( 20, 1, "blue 1", get_timestamp( days => 9 ) )
        or die $dbh->errstr;
    $md_sth->execute( 20, 3, "edit_type", "Normal edit" );
    $md_sth->execute( 20, 2, "edit_type", "Minor tidying" );
    $md_sth->execute( 20, 1, "edit_type", "Normal edit" );

    # Now write it as per usual.
    %data = $wiki->retrieve_node( "Blue Lion" );
    $wiki->write_node( "Blue Lion", "blue 4", $data{checksum},
                       { edit_type => [ "Minor tidying" ] } )
      or die "Couldn't write Blue Lion node";
}
