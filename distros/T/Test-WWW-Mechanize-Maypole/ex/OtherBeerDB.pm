package OtherBeerDB;
use Maypole::Application;
use Class::DBI::Loader::Relationship;

# This is like BeerDB, but calls setup at run time. Because of that, we can't 
# load the Exported classdata method, but we don't need it. 

# Note: we deliberately set up the wrong database here, to test that we can 
# successfully override that in other_beer.t

sub debug { $ENV{BEERDB_DEBUG} }
# This is the sample application.  Change this to the path to your
# database. (or use mysql or something)
use constant DBI_DRIVER => 'SQLite';
use constant DATASOURCE => $ENV{BEERDB_DATASOURCE} || 't/beerdb.db';

use NEXT;

my $dbi_driver;

BEGIN {
    $dbi_driver = DBI_DRIVER;
    
    if ($dbi_driver =~ /^SQLite/) 
    {
        die sprintf "SQLite datasource '%s' not found, correct the path or "
            . "recreate the database by running Makefile.PL", DATASOURCE
            unless -e DATASOURCE;
        
        eval "require DBD::SQLite";
        
        if ($@) 
        {
            eval "require DBD::SQLite2" and $dbi_driver = 'SQLite2';
        }
    }
    
}

# the WRONG database
__PACKAGE__->setup(join ':', "dbi", $dbi_driver, DATASOURCE);

# Give it a name.
__PACKAGE__->config->application_name('The Beer Database');

# Change this to the root of the web site for your maypole application.
__PACKAGE__->config->uri_base( $ENV{BEERDB_BASE} || "http://localhost/beerdb/" );

# Change this to the htdoc root for your maypole application.
__PACKAGE__->config->template_root( $ENV{BEERDB_TEMPLATE_ROOT} ) if $ENV{BEERDB_TEMPLATE_ROOT};

# Specify the rows per page in search results, lists, etc : 10 is a nice round number
__PACKAGE__->config->rows_per_page(10);

# Handpumps should not show up.
__PACKAGE__->config->display_tables([qw[beer brewery pub style]]);

OtherBeerDB::Brewery->untaint_columns( printable => [qw/name notes url/] );
OtherBeerDB::Style->untaint_columns( printable => [qw/name notes/] );
OtherBeerDB::Beer->untaint_columns(
    printable => [qw/abv name price notes url/],
    integer => [qw/style brewery score/],
    date =>[ qw/date/],
);
OtherBeerDB::Pub->untaint_columns(printable => [qw/name notes url/]);

__PACKAGE__->config->{loader}->relationship($_) for (
    "a brewery produces beers",
    "a style defines beers",
    "a pub has beers on handpumps");


1;
