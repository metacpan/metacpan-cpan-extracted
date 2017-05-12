use strict;
use Wiki::Toolkit;
use Wiki::Toolkit::TestLib;
use Test::More tests => ( 1 + 3 * scalar @Wiki::Toolkit::TestLib::wiki_info );

# Test failed creation.  Note this has a few tests missing.
eval { Wiki::Toolkit->new; };
ok( $@, "Creation dies if no store supplied" );

# Test successful creation, for each configured store/search combination.
my @wiki_info = @Wiki::Toolkit::TestLib::wiki_info;

foreach my $infoid ( @wiki_info ) {
    my %wiki_config;

    # Test store instantiation.
    my %datastore_info = %{ $infoid->{datastore_info } };
    my $class =  $datastore_info{class};
    eval "require $class";
    my $store = $class->new( %{ $datastore_info{params} } );
    isa_ok( $store, $class );
    $wiki_config{store} = $store;

    # Test search instantiation.
    SKIP: {
        skip "No search configured for this combination", 1
          unless ($infoid->{dbixfts_info} or $infoid->{sii_info}
                  or $infoid->{plucene_path} );
        if ( $infoid->{dbixfts_info} ) {
            my %fts_info = %{ $infoid->{dbixfts_info} };
            require Wiki::Toolkit::Store::MySQL;
            my %dbconfig = %{ $fts_info{db_params} };
            my $dsn = Wiki::Toolkit::Store::MySQL->_dsn( $dbconfig{dbname},
                                                     $dbconfig{dbhost}  );
            my $dbh = DBI->connect( $dsn, $dbconfig{dbuser}, $dbconfig{dbpass},
                       { PrintError => 0, RaiseError => 1, AutoCommit => 1 } )
              or die "Can't connect to $dbconfig{dbname} using $dsn: "
                        . DBI->errstr;
            require Wiki::Toolkit::Search::DBIxFTS;
            my $search = Wiki::Toolkit::Search::DBIxFTS->new( dbh => $dbh );
            isa_ok( $search, "Wiki::Toolkit::Search::DBIxFTS" );
            $wiki_config{search} = $search;
        } elsif ( $infoid->{sii_info} ) {
            my %sii_info = %{ $infoid->{sii_info} };
            my $db_class = $sii_info{db_class};
            my %db_params = %{ $sii_info{db_params} };
            eval "require $db_class";
            my $indexdb = $db_class->new( %db_params );
            require Wiki::Toolkit::Search::SII;
            my $search = Wiki::Toolkit::Search::SII->new(indexdb =>$indexdb);
            isa_ok( $search, "Wiki::Toolkit::Search::SII" );
            $wiki_config{search} = $search;
        } elsif ( $infoid->{plucene_path} ) {
            require Wiki::Toolkit::Search::Plucene;
            my $search = Wiki::Toolkit::Search::Plucene->new( path => $infoid->{plucene_path} );
            isa_ok( $search, "Wiki::Toolkit::Search::Plucene" );
            $wiki_config{search} = $search;
        } elsif ( $infoid->{lucy_path} ) {
            require Wiki::Toolkit::Search::Lucy;
            my $search = Wiki::Toolkit::Search::Lucy->new(
                             path => $infoid->{lucy_path} );
            isa_ok( $search, "Wiki::Toolkit::Search::Lucy" );
            $wiki_config{search} = $search;
        }
    } # end of SKIP for no search

    # Test wiki instantiation.
    my $wiki = Wiki::Toolkit->new( %wiki_config );
    isa_ok( $wiki, "Wiki::Toolkit" );

}
