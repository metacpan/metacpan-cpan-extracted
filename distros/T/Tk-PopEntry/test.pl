use Tk;
use PopEntry;

$mw = MainWindow->new;
$pe = $mw->PopEntry(-pattern=>'alphanum');

$pe->pack;

$label = $mw->Label(-text => "Enter some text and right-click somewhere in the Entry widget!");
$label->pack;

$label2 = $mw->Label(-text => "Only alpha-numeric text allowed in this example");
$label2->pack(-pady=>15);

$exitbutton = $mw->Button(-text=>"Exit", -command=>sub{exit});
$exitbutton->pack;

$pe->addItem(["Exit", 'main::exitApp', '<Control-g>', 1]);

MainLoop;

sub exitApp{ exit }
