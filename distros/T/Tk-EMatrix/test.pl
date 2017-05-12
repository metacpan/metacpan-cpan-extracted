# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

#BEGIN { $| = 1; print "1..last_test_to_print\n"; }
#END {print "not ok 1\n" unless $loaded;}
#use Tk-EMatrix-0.01;
#$loaded = 1;
#print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Tk;
use Tk::TableMatrix;
use EMatrix;

my $mw = MainWindow->new;

# These are the column headers and are immutable
my $titleHash = {
   "0,0" => "Header1",
   "0,1" => "Header2",
   "0,2" => "Header3",
   "0,3" => "Header4",
   "0,4" => "Header5",
};

my $buttonHash = {
   "1,0" => "Button2",
   "2,0" => "Button3",
   "3,0" => "Button4",
   "4,0" => "Button5",
};

my $table;
$table = $mw->Scrolled('EMatrix',
   -cols          => 5,
   -bd            => 2,
   -bg            => 'white',
   -titlerows     => 1,
#   -titlecols     => 1,
   -variable      => $titleHash,
   -colstretchmode => 'all',
#   -rowstretchmode => 'fill',
);

$table->tagConfigure('title', 
   -bg => 'tan',
   -fg => 'black',
   -relief => 'raised'
);

$table->pack(-expand => 1, -fill => 'both');

my $numrows = $table->cget(-rows);
my $index = 3;


$table->set('row',"1,3","Plane");
$table->set('row',"2,3","Car");
$table->set('row',"3,3","Truck");
$table->set('row',"1,1","Train");
$table->set('row',"1,2","Motorcycle");
$table->set('row',"1,0","Boat");

$table->bindRow(
   -index    => 0,
   -sequence => '<Button-3>',
   -command  => \&printMe,
);

$table->bindCol(
   -index    => 2,
   -sequence => '<Control-g>',
   -command  => \&printMe,
);

# Test the getRow(1) method in scalar context
print "\ngetRow() - scalar context (Columns 0-2)";
print "\n************************";
my $rec = $table->getRow(1,2);
foreach my $val (@$rec){ print "\nVal - $val" }

# Test the getRow(1) method in list context
print "\n\ngetRow() - list context (Columns 0-2)";
print "\n************************";
my @rec = $table->getRow(1,2);
foreach my $val (@rec){ print "\nVal - $val" }

# Test the getCol(3) method in scalar context
print "\n\ngetCol() - scalar context";
print "\n************************";
my $rec = $table->getCol(3);
foreach my $val (@$rec){ print "\nVal - $val" if $val ne "" }

# Test the getCol(3) method in list context
print "\n\ngetCol() - list context";
print "\n************************";
my $rec = $table->getCol(3);
foreach my $val (@$rec){ print "\nVal - $val" if $val ne "" }

# Test the getRowHash() method - scalar context (tied)
my $row = $table->getRowHash(1, 'tie');
print "\n\ngetRowHash - scalar context (tied)";
print "\n************************";
while(my($key,$val) = each(%$row)){
   print "\nKey is: $key - Val is: $val" if $val ne "";
}

# Test the getRowHash() method - list context
my %row = $table->getRowHash(1);
print "\n\ngetRowHash - list context";
print "\n************************";
while(my($key,$val) = each(%row)){
   print "\nKey is: $key - Val is: $val" if $val ne "";
}

# Test the getColHash() method - scalar context 
my $col = $table->getColHash(3, 'tie');
print "\n\ngetColHash - scalar context (tied)";
print "\n************************";
while(my($key,$val) = each(%$col)){
   print "\nKey is: $key - Val is: $val" if $val ne "";
}

# Test the getColHash() method - list context 
my %col = $table->getColHash(3);
print "\n\ngetColHash - list context";
print "\n************************";
while(my($key,$val) = each(%col)){
   print "\nKey is: $key - Val is: $val" if $val ne "";
}

my $labelText = "Right click in the 4th column or press Control-g in\n" 
. " the 3rd column and watch the terminal for output";

my $label = $mw->Label(-text=>$labelText)->pack;

MainLoop;

sub printMe{ print "\nYes, the binding worked!" }
