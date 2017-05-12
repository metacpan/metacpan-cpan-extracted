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
    plan tests => ( 1 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Write directly to the database so we can fake having written something
    # a week ago (white box testing).
    my $dbh = $wiki->store->dbh;
    my $content_sth = $dbh->prepare("INSERT INTO content
                                    (node_id,version,text,modified)
                                    VALUES (?,?,?,?)");
    my $node_sth = $dbh->prepare("INSERT INTO node
                                 (id,name,version,text,modified)
                                 VALUES (?,?,?,?,?)");

    my $now = localtime; # overloaded by Time::Piece
    my $two_days_ago = $now - (2 * ONE_DAY );
    my $week_ago = $now - ONE_WEEK;
    my $ts_now = Wiki::Toolkit::Store::Database->_get_timestamp;
    my $ts_two_days_ago = Wiki::Toolkit::Store::Database->_get_timestamp( $two_days_ago );
    my $ts_week_ago = Wiki::Toolkit::Store::Database->_get_timestamp( $week_ago );

    $node_sth->execute( 10, "Home", 3, "foo", $ts_now ) or die $dbh->errstr;
    $content_sth->execute( 10, 1, "foo", $ts_week_ago )
        or die $dbh->errstr;
    $content_sth->execute( 10, 2, "foo", $ts_two_days_ago )
        or die $dbh->errstr;
    $content_sth->execute( 10, 3, "foo", $ts_now ) or die $dbh->errstr;

    my @nodes = $wiki->list_recent_changes(
                                            include_all_changes => 1,
                                            between_days => [ 1, 3 ],
                                          );
    is (scalar @nodes, 1, "between_days flag to list_recent_changes works" );
}
