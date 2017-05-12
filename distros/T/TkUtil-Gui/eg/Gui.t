# the BEGIN block is only needed for this test before install
BEGIN { unshift(@INC, "lib"); unshift(@INC, "../lib") }

use Tk;
use Tk::BrowseEntry;
use TkUtil::Gui;
use Data::Dumper;
use strict;
use warnings;

my $mw = MainWindow->new;
my $frame1 = $mw->Frame->pack;
my $frame2 = $mw->Frame->pack;
my $gui = TkUtil::Gui->new(top => $frame1);

my $be = $gui->BrowseEntry(name => 'BE')->pack;
$be->insert('end', $_) foreach qw(one two three);
$gui->set('BE', 'two');
$gui->Entry(name => 'EntryBox', default => "foobar", -width => 30)->pack;

my $lb = $gui->Listbox(name=>'LB', -exportselection => 0)->pack;
$lb->insert('end', $_) foreach qw(this that theother);

my %RBopts = (name => 'RB', vfrom => 'RB', default => 'A');
$gui->Radiobutton(%RBopts, -text => "Selection A", -value => 'A')->pack;
$gui->Radiobutton(%RBopts, -text => "Selection B", -value => 'B')->pack;
#$gui->set('RB', 'A');

my %onoff = (onoff => 'yes|no');
$gui->Checkbutton(name => 'EastWest', %onoff, -text => "East/West")->pack;
$gui->Checkbutton(name => 'NorthSouth', %onoff, -text => "North/South")->pack;

# shows how easy it is to discover gui contents
$gui->top($frame2);
$gui->Button(name=>'junk', default=>'20', -text=>'Show', -command => 
    sub { my %r = $gui->as_hash; print Dumper(\%r) }
)->pack;

# get a widget via the name assigned to it
print ref($gui->widget('junk')), "\n";
$gui->widget('junk')->configure(-text => "Show State", -foreground => 'red');

MainLoop;
