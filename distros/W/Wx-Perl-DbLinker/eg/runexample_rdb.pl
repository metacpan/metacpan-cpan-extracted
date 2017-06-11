
use strict;
use warnings;
use lib qw(lib ../lib/ ../../hg_Gtk2-Ex-DbLinker-DbTools/lib/);
use DBI;
use Log::Log4perl qw(:easy);
#use Log::Log4perl;
#Log::Log4perl->init("log.conf");
Log::Log4perl->easy_init($DEBUG);
use Log::Any::Adapter;
use Forms::Langues;
use DataAccess::Rdb::Service;
#use Devel::Cycle;
Log::Any::Adapter->set('Log::Log4perl');
=for comment
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
=cut

sub load_main_w {
 my $data = DataAccess::Rdb::Service->new(); 
    my $app = Forms::Langues->new(
        { xrcfolder => "./xrc", data_broker => $data } );
    $app->GetTopWindow->Move( 10, 10 );
    $app->MainLoop;
    #find_cycle($app);
    #print "weakened\n";
    #find_weakened_cycle($app);
}

&load_main_w;

