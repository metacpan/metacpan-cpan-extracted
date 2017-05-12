
use strict;
use warnings;
use lib qw(lib ../lib/ ../../hg_Gtk2-Ex-DbLinker-DbTools/lib/);
use Dbc::Schema;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
#Log::Log4perl->init("log.conf");
use Forms::Langues;
use DataAccess::Dbc::Service;
#use Devel::Cycle;

sub get_schema {
    my $file = shift;
    my $dsn  = "dbi:SQLite:dbname=$file";

    #$globals->{ConnectionName}= $conn->{Name};
    my $s = Dbc::Schema->connect(
        $dsn,

    );
    return $s;
}

sub load_main_w {
  my $data = DataAccess::Dbc::Service->new({schema => get_schema("./data/ex1_1") });  
    my $app = Forms::Langues->new(
        { xrcfolder => "./xrc", data_broker => $data } );
    $app->GetTopWindow->Move( 10, 10 );
    $app->MainLoop;
    #find_cycle($app);
    #print "Weakened\n";
    #find_weakened_cycle($app);

}

&load_main_w;

