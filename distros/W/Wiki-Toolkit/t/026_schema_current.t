use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 3 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    my $store = $wiki->store;
    my ($cur_ver, $db_ver);
    ($cur_ver, $db_ver) = $store->schema_current;
    cmp_ok( $cur_ver, '==', $db_ver,
        "schema_current returns matching versions when schema is current" );
    
    # Now we munge the database to simulate an old schema
    my $dbh = $store->dbh;
    my $sth = $dbh->prepare("UPDATE schema_info SET version = 1");
    $sth->execute;
    ($cur_ver, $db_ver) = $store->schema_current;
    cmp_ok ($cur_ver, '>', $db_ver,
       "schema_current returns \$cur_ver > \$db_ver when schema is older" );

    # Now we get rid of the schema table to simulate a really old DB
    $sth = $dbh->prepare("DROP TABLE schema_info");
    $sth->execute;
    ($cur_ver, $db_ver) = $store->schema_current;
    cmp_ok ($cur_ver, '>', $db_ver,
       "schema_current returns \$cur_ver > \$db_ver when schema is missing" );
    
}

