# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


# perldoc Test::More - for help writing this test script.
use Test::More tests => 24;
BEGIN { use_ok('DBI'); use_ok('XML::RDB') };
chdir('t');

my %drivers = map { $_ => 1 } DBI->available_drivers;
ok(($drivers{SQLite} || $drivers{mysql} || $drivers{Pg}), 'DBDs Check: SQLite, MySQL or PostgreSQL');

my %cfgs = (SQLite  => 'dbi_sqlite3_test.cfg',
            Pg      => 'dbi_pg_test.cfg'     ,
            mysql   => 'dbi_mysql_test.cfg'  );

while ( my($dbd, $cfg) = each(%cfgs))  {
  my $rdb = ( $drivers{$dbd} && (new XML::RDB(config_file => $cfg)));

  my ($why, $test_cnt) = ("Unable to Create DBI::$dbd connection using '$cfg', failed creating XML::RDB new.", 6 );
  SKIP: {
    skip $why, $test_cnt, unless (ref $rdb); 
    
    $rdb->drop_tables; # in the event of re-running the test. make sure we have an open spot
    ok( $rdb,                                             "XML::RDB, DBI::$dbd; created and connected." );
    ok( $rdb->make_tables('test.xml', 'test_schema.sql'), 'Generated DB DDL schema.');
    ok( $rdb->create_tables('test_schema.sql'),           'DB loaded DDL');
    ok( $rdb->populate_tables('test.xml'),                'DB loaded XML');
    ok( $rdb->unpopulate_tables('test_new.xml'),          'Generated XML from DB');
    ok( $rdb->drop_tables,                                'DB dropped tables');
    ok( $rdb->done,                                       'Cleanup; DB, close DOM Doc');
    unlink('test_schema.sql');
    unlink('test_new.xml');
    unlink('test');
  }
}

done_testing();

