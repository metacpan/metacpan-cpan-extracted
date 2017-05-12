use Tk;

use lib 'C:\MyPrograms\MyCreations\Tk-LabPopEntry';
require LabPopEntry;

my $mw = MainWindow->new;

my $lpe = $mw->LabPopEntry(
   -nospace      => 0,
   -pattern      => 'float',
   -label        => 'Float Value: ',
   -labelPack    => [-side=>'left'], 
);
$lpe->pack;

my $button = $mw->Button(-text=>"Exit", -command=>sub{exit})->pack;
my $label = $mw->Label(-text=>"Right click in the entry widget")->pack;

#$lpe->deleteItem(2,'end');
#$lpe->addItem('end',["Exit", 'main::exitApp', '<Control-g>', 1]);

MainLoop;

sub exitApp{ exit }
