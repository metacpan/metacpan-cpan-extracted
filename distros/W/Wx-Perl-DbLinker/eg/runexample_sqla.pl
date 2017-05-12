
use strict;
use warnings;
use lib qw(lib ../lib/ ../../hg_Gtk2-Ex-DbLinker-DbTools/lib/);
use DBI;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
#use Log::Log4perl;
#Log::Log4perl->init("log.conf");
use Forms::Langues;
use DataAccess::Sqla::Service;
#use Devel::Cycle;

sub get_dbh {
    my $dbfile = shift;
    my $dbh    = DBI->connect(
        "dbi:SQLite:dbname=$dbfile",
        "", "",
        {
            RaiseError => 1,
            PrintError => 1,
        }
    ) or die $DBI::errstr;
    return $dbh;
}

sub load_main_w {
my $data = DataAccess::Sqla::Service->new({dbh =>  get_dbh("./data/ex1_1") }); 
    my $app = Forms::Langues->new(
        { xrcfolder => "./xrc", data_broker => $data } );
    $app->GetTopWindow->Move( 10, 10 );
    $app->MainLoop;
    #find_cycle($app);
    #print "weakened\n";
    #find_weakened_cycle($app);
}

&load_main_w;

