#!/usr/bin/perl -w
# $Id: test-no-crash.pl,v 1.20 2005/01/16 10:24:14 mertz Exp $
# This non-regression / memory leak test has been developped by Christophe Mertz <mertz@intuilab.com>

use Tk;
use Tk::Zinc;
use Getopt::Long;
use TestLog;

use strict;

use constant ERROR => '--an error--';


# the following list be coherent with the treatments done in the TEST section.
my @testsList = (
		 1 => 'test_mapitems (quick)',
		 2 => 'test_every_field_attributes (long)',
		 3 => 'test_attributes (medium)',
		 4 => 'test_cloning (quick)',
		 5 => 'test_coords (quick)',
		 );
my %testsHash;
{ my @tests = @testsList;
  while (@tests) {
      my $num = shift (@tests);
      my $comment = shift (@tests);
      $testsHash{ $num } = $comment;
  }
}

# les variables positionnées en fonction des options de la ligne de commande
my $opt_log = 0;
my $opt_trace = "";
my $opt_render = -1;
my $opt_type = 0;
my $outfile;
my $opt_tests = "all";
my $opt_memoryleak = 0;

# on récupère les options
Getopt::Long::Configure('pass_through');
my $optstatus = GetOptions('log=i' => \$opt_log,
			   'out=s' => \$outfile,
			   'trace=s' => \$opt_trace,
			   'render:s' => \$opt_render,
			   'type=s' => \$opt_type,
			   'help' => \&usage,
			   'memoryleak' => \$opt_memoryleak,
			   'tests:s' => \$opt_tests,
			   );

# on teste la validité de l'option -render!
if ($opt_render eq '') {
    print "-render option have no value!\n";
    &usage;
}
$opt_render = 1 if $opt_render == -1;
unless ($opt_render==0 or $opt_render==1 or $opt_render==2) {
    print "-render option value must be 0, 1 or 2!\n";
    &usage;
}


$outfile = "no-crash-$Tk::Zinc::VERSION.log" if (!defined $outfile);

## in case of memoryleak test, logs are not written in a file
##  and logs are limited to high level logs on the standard output
##  (only those with a loglevel <= -1000 will be written on stdout)
my $nolog_file = 0;
if ($opt_memoryleak) {
  $opt_log = -1000;
  my $nolog_file = 1;
}




&openLog($outfile, $opt_log, $nolog_file);

sub usage {
    my ($text) = @_;
    print $text,"\n" if (defined $text);
    print "test-no-crash [options]\n";
    print "       A non-regression test suite for zinc.\n";
    print "       Some exhaustive test of zinc. Of course everything is not tested yet\n";
    print " options are:\n";
    print " -help           to print this short help\n";
    print " -log <n>        trace level, defaulted to 0; higher level trace more infos\n";
    print " -out filename   the log filename. defaulted to no-crash.log\n";
    print "      NB: the previous log file is always renamed with a .prev suffix\n";
    print " -memoryleak     to try to detect some memoryleak between first iteration of the test \n";
    print "                 and the following iteration. This test NEVER finish automatically\n";
    print "                 it is up to the tester to stop the memoryleak test after\n";
    print "                 a significative number of iterations\n";
    print " -render 0|1|2   to select the render option of zinc (defaulted to 1)\n";
    print " -trace <an_item_option>  to better trace usage of an option\n";
    print " -type <a_zinc_item_type> to limits tests to this item type.\n";
    print " -tests to get the list of available tests.\n";
    print " -tests i,j,k... to define the list of tests to pass.\n";
    exit;
}

my $mw = MainWindow->new();

&log (-1000, "#testing Zinc-perl Version=" . $Tk::Zinc::VERSION . " - ", $mw->zinc(), "\n");

## must be done after the LOG file is open:

my @tests = &parseTestsOpt($opt_tests);
my %tests;
foreach my $t (@tests) {$tests{$t} = $t }


# The explanation displayed when running this demo
my $label=$mw->Label(-text => "This is a non-regression test, testing that
zinc is not core-dumping! It can also be used for detecting memory leaks",
		     -justify => 'left')->pack(-padx => 10, -pady => 10);


# Creating the zinc widget
my $zinc = $mw->Zinc(-width => 500, -height => 500,
		     -trackmanagedhistorysize => 10,
		     -font => "10x20", # usually fonts are sets in resources
		                       # but for this example it is set in the code!
		     -borderwidth => 0, -relief => 'sunken',
		     -render => $opt_render,
		     )->pack;

&setZincLog($zinc);


my %itemtypes;
my @itemtypes = qw(arc tabular track waypoint
		   curve rectangle triangles
		   group icon map reticle text window
		   );

if ($opt_type) { @itemtypes = ($opt_type); }

foreach my $type (@itemtypes) { $itemtypes{$type}=1 }

#### some global variables needed as attributes values
my ($text1, $text2, $text3, $text4);
my ($image1, $image2, $image3, $image4);

&creating_items ("unused");
&verifying_item_completion;

sub creating_items {
    # first removing all remaining items
    foreach my $item (&test_eval (1, 'find', 'withtag', 'all')) {
	&test_eval (1, "remove", $item);
    }


    my $labelformat = "x82x60+0+0 x60a0^0^0 x32a0^0>1 a0a0>2>1 x32a0>3>1"; 
    # and then creating items
    &test_eval (1, "add", 'group', 1);
    &test_eval (1, "add", 'group', 1);
    &test_eval (1, "add", 'icon', 1);
    &test_eval (1, "add", 'map', 1);
    &test_eval (1, "add", 'map', 1);
    &test_eval (1, "add", 'reticle', 1);
    $text1 = &test_eval (1, "add", 'text', 1,  -position => [300,120], -text => "hello world1");
    $text2 = &test_eval (1, "add", 'text', 1,  -position => [350,170], -text => "hello world2");
    $text3 = &test_eval (1, "add", 'text', 1,  -position => [400,220], -text => "hello world3");
    &test_eval (1, "add", 'window', 1);
#    &test_eval (1, "add", 'track', 1, 5, -position => [100,200]);
    &test_eval (1, "add", 'track', 1, 5, -position => [100,200], -labelformat => $labelformat);
    &test_eval (1, "add", 'waypoint', 1, 5, -position => [200,100], -labelformat => $labelformat);
    &test_eval (1, "add", 'tabular', 1, 5, -position => [100,20], -labelformat => $labelformat);
    &test_eval (1, "add", 'group', 1);

    &test_eval (1, "mapinfo", 'mapinfo1', 'create');
    &test_eval (1, "mapinfo", 'mapinfo2', 'create');
    &test_eval (1, "mapinfo", 'mapinfo3', 'create');
    
#$zinc->itemconfigure ('tabular', -labelformat => "200x10");
#$zinc->update;



    &test_eval (1, "add", 'arc', 1, [10,10 , 50,50]);
    &test_eval (1, "add", 'curve', 1, [30,0 , 150,10, 100,110, 10,100, 50,140]);
    &test_eval (1, "add", 'rectangle', 1, [400,400 , 450,220]);
    &test_eval (1, "add", 'triangles', 1, [200,200 , 300,200 , 300,300, 200,300],
		-colors => ["blue;50", "red;20", "green;80"]);
    
    # images are initialised ONLY ONCE! (to avoid memoryleaks)
    $image1 = $zinc->Photo(-file => Tk::findINC("Tk/icon.gif") ) unless $image1;
    $image2 = $zinc->Photo(-file => Tk::findINC("Tk/Xcamel.gif") ) unless $image2;
    $image3 = $zinc->Photo(-file => Tk::findINC("Tk/tranicon.gif") ) unless $image3;
    $image4 = $zinc->Photo(-file => Tk::findINC("Tk/anim.gif") ) unless $image4;

    &creating_datas;  # some of the data are using items!
} # end creating_items

# verifies that we create an item of every existing type
sub verifying_item_completion {
    my @all_types = $zinc->add();  ## this use of add is not documented yet XXX!
    my @all_items = $zinc->find ('withtag', 'all');
    my %created_item_types;
    foreach my $item (@all_items) {
	$created_item_types{$zinc->type($item)} = 1;
    }
    foreach my $type (@all_types) {
	if (defined $created_item_types{$type}) {
	    delete $created_item_types{$type};
	}
	else {
	    &log(-100, "item type \"type\" which exist in Zinc is not tested!\n");
	}
    }
    foreach my $type (sort keys %created_item_types) {
	&log(-100, "This tested item type \"$type\" is supposed not to exist in Zinc!\n");
    }
}


my %options;
my %types;


foreach my $itemType (@itemtypes) {
    my ($anItem) = $zinc->find('withtype', $itemType);
    if (!defined $anItem) { &log (-10, "no item $itemType\n"); next;};
    my @options = $zinc->itemconfigure($anItem);
    foreach my $elem (@options) {
	my ($optionName, $optionType, $readOnly, $empty, $optionValue) = @$elem;
	$options{$itemType}{$optionName} = [$optionType, $readOnly, $empty, $optionValue];
	$types{$optionType} = 1;
    }
}

my %fieldOptions;

{
my ($aTrack) = $zinc->find('withtype', 'track');
if (!defined $aTrack) { &log (-10, "no item track\n") }
else {
    my @fieldOptions = $zinc->itemconfigure($aTrack, 0);
    for my $elem (@fieldOptions) {
	my ($optionName, $optionType, $readOnly, $empty, $optionValue) = @$elem;
	$fieldOptions{$optionName} = [$optionType, $readOnly, $empty, $optionValue];
	$types{$optionType} = 1;
    }
}
}

foreach my $type (sort keys %types) {
#    print "$type\n";
}

# a hash giving samples of valid data for attributes types
my %typesValues;

# the following hash associated to types valid value that should be all different from
# default value and from value initiated when creating items (see up...)
my %typesNonStandardValues;

# a hash giving samples of NOT valid data for attributes types
my %typesIllegalValues;

sub creating_datas {
  return if defined $typesValues{'alignment'};
  %typesValues =
	('alignment' => ['left', 'right', 'center'],
	 'alpha' => [0, 50, 100, 23],
	 'anchor' => ['n', 's', 'e', 'w', 'nw', 'ne', 'sw', 'se', 'center'],
	 'angle' => [0, 90, 180, 270, 360, 12, 93, 178, 272, 359],
	 'autoalignment' => ['lll', 'llr', 'llc', 'lrl', 'lrr', 'lrc', 'lcl', 'lcr', 'lcc',
			     'rll', 'rlr', 'rlc', 'rrl', 'rrr', 'rrc', 'rcl', 'rcr', 'rcc',
			     'cll', 'clr', 'clc', 'crl', 'crr', 'crc', 'ccl', 'ccr', 'ccc',
			     '-',],
	 'boolean' => [0..1],
	 'bitmap' => ['AlphaStipple0', 'AlphaStipple3', 'AlphaStipple14', 'AlphaStipple11', 'AlphaStipple7'], ####?!
	 'bitmaplist' => [['AlphaStipple0', 'AlphaStipple3', 'AlphaStipple14', 'AlphaStipple11', 'AlphaStipple7'], ['AlphaStipple0']], ##TBC
	 'capstyle' => ['butt', 'projecting', 'round'],
	 'gradient' => ['green', 'LemonChiffon', '#c84', '#4488cc', '#888ccc444', 'red'], ## TBC
	 'gradientlist' => [['green'], ['LemonChiffon'], ['#c84'], ['#4488cc'], ['#888ccc444'],
			    ['red', 'green'], ['red', 'green', 'blue'],
			    ['red;50', 'green;50', 'blue;50'],
			    ['blue;0', 'green;50', 'red;90'],
			    ], ## TBC
	 'dimension' => [0..5, 10, 50, 100, 0.0, 5.5, 100.5, 4.5],  ## and floats ?!
	 'edgelist' => ['left', 'right', 'top', 'bottom', 'contour', 'oblique', 'counteroblique'], ## +combinations!
         'filerule', => ['odd', 'negative','positive', 'abs_ge_eq2'],
	 'font' => ['10x20', '6x10', '6x12', '6x13'],
	 'image' => [$image1, $image2, $image3], ## TBC
	 'integer' => [-10000, -100, -1, 0, 1, 10, 10000], ## pour quoi?
	 'item' => [$text1, $text2],
	 'joinstyle' => ['bevel', 'miter', 'round'],
	 'labelformat' => ["200x10", ## BUG BUG
#		       "200x100 x100x20+0+0 x100x20+0+20 x200x40+100+20"
			   ],
	 'leaderanchors' => ["%10x30", "|0|0", "%40x20", "|1|1", "|100|100", "%67x21" ], ## TBC! non exchaustif!! BUG non conforme à la doc
	 # illegal et fait planter: "%50" 
	 'lineend' => [ [10,10,10], [10,100,10], [100,10,10], [10,10,100], [100,10,100] ],
	 'lineshape' => ['straight', 'rightlightning', 'leftlightning', 'rightcorner', 'leftcorner', 'doublerightcorner', 'doubleleftcorner'],
	 'linestyle' => ['dotted', 'simple', 'dashed', 'mixed', 'dotted'],
	 'mapinfo' => ['mapinfo1','mapinfo2','mapinfo3'], ## TBC
#     'number' => [2.3, 1.0, 5.6, 2.1],
	 'point' => [ [0,0] , [10,10], [20,20], [30,30], [20,20], [0,0] , [10,10] ],
	 'priority' => [ 1, 10, 50, 1000, 10000 ],  # positif ou nul
	 'relief' => ['flat', 'groove', 'raised', 'ridge', 'sunken',
		      'roundraised', 'roundsunken', 'roundgroove',
		      'roundridge', 'sunkenrule', 'raisedrule'],
	 'string' => ['teststring', 'short', 'veryverylongstring'],
	 'taglist' => [ [1], [1..2], ['a','b'], ['tag1','tag2','tag3']],
	 'unsignedint' => [ 0..5 , 10, 20, 30, 100 ],
	 'window' => [], ## TBC
	 );
    
# the following valid value associated to types should be all different from
# default value and from value initiated when creating items (see up...)
    %typesNonStandardValues = 
	('alignment' => 'right',
	 'alpha' => 50,
	 'anchor' => 'w',
	 'angle' => 45,
	 'autoalignment' => 'llc',
	 'bitmap' => 'AlphaStipple14',
	 'bitmaplist' => ['AlphaStipple0', 'AlphaStipple3', 'AlphaStipple14', 'AlphaStipple11', 'AlphaStipple7'],
	 'capstyle' => 'butt',
	 'gradient' => 'LemonChiffon',
	 'gradientlist' => ['red;50', 'green;50', 'blue;50'],
	 'dimension' => 45,
	 'edgelist' => 'contour',
	 'font' => '6x10',
         'fillrule' => 'nonzero',
	 'image' => $image4,
	 'integer' => 7,
	 'item' => $text3,
	 'joinstyle' => 'miter',
	 'labelformat' => "200x30", ## BUG BUG
	 'leaderanchors' => "%10x45", ## BUG BUG
	 'lineend' => [13,7,20],
	 'lineshape' => 'rightlightning',
	 'linestyle' => 'dotted',
	 'mapinfo' => 'mapinfo2', ## TBC
	 'number' => 7.6,
	 'point' => [100,100],
	 'priority' => 50,
	 'relief' => 'groove',
	 'string' => 'notsoshort',
	 'taglist' => ['tag1','tag11','tag111'],
	 'unsignedint' => 7, # 22,    # 22 is to high for -visiblehistorysize and 5 is, the default value for reticle -period
	 'window' => undef, ### TBC
	 );
    
    %typesIllegalValues =
	('alpha' => [0..100],
	 'anchor' => ['n', 's', 'e', 'w'], ##TBC
	 'angle' => [0..360],
	 'boolean' => [0..1],
	 'capstyle' => [],
	 'dimension' => [0..100],
	 'font' => ['10x20', '6x10', '6x12', '6x13'],
	 'leaderanchors' => ["%50"  ], ## TBC! non exchaustif!! BUG non
	 'relief' => ['flat', 'groove', 'raised', 'ridge', 'sunken',
		      'roundraised', 'roundsunken', 'roundgroove',
		      'roundridge', 'sunkenrule', 'raisedrule'],
	 );
}

$mw->Button(-text => "Exit",
	    -command => sub { exit },
	    )->pack(-pady => 4);

sub test_attributes {
    &log (-1000, "#---- Start of test_attributes ----\n");
    foreach my $type (@itemtypes) {
	my @items = $zinc->find('withtype', $type);
	&log (0, "#--------- Testing ", (1+$#items), " ",$type," attributes ----------------\n");
	if ($#items == -1) {
	    &log (-100, "No such item: $type\n");
	    next;
	}
        &log(0,"no such type '$type'\n"), next unless defined $options{$type};
#        print $options{$type}, "\t\t", %{$options{$type}}, "\n";
	my %theoptions = %{$options{$type}};
	foreach my $item (@items) {
	    ## il faudrait tester les options selon un ordre défini à l'avance
	    ## en passant par plusieurs occurences pour les options et en forçant
	    ## certaines valeurs, par exemple les valeurs booléennees... (visible/sensible/filled)
	    my @boolean_attributes;
	    my %boolean_attributes;
	    foreach my $option (sort keys %theoptions) {
		my ($optionType, $readOnly, $empty, $optionValue) = @{$theoptions{$option}};
		if ($optionType eq 'boolean') {
		    next if $option eq -composerotation;
		    next if $option eq -composescale;
		    next if $option =~ /-\w+sensitive/ ;   # to get rid of many track options!
		    next if $option =~ /-filled\w+/ ;      # to get rid of many track options!
		    next if $option =~ /-speed\w+/ ;      # to get rid of many track options!
		    next if $option =~ /-\w+history/ ;      # to get rid of many track options!
		    push @boolean_attributes, $option;
		    $boolean_attributes{$option}=1;
		}
	    }
	    &log (0, "# $type (id $item) : ", ((2**(1+$#boolean_attributes)) , " Combinations (", join (', ' , @boolean_attributes),")\n"));
	    foreach my $i (0 .. (2**(1+$#boolean_attributes) -1) ) {
		my $format = "%0" . ($#{boolean_attributes} +1) . "b";
		my $binary = sprintf ($format,$i);
		&log (0, "# $i/", (2**(1+$#boolean_attributes)), "  $binary\n");
		my @binary = split (//,$binary);
		foreach my $j (0 .. $#boolean_attributes) {
		    &test_eval (0, "itemconfigure", $item, $boolean_attributes[$j] => $binary[$j] );
#		    &log (0, "setting $type ($item) ", $boolean_attributes[$j], " to ", $binary[$j], "\n");
		}
		foreach my $option (sort keys %theoptions) {
		    next if ($option eq -numfields); # BUG? makes the appli stop
		    next if ($option eq "-clip" and $type = "group"); # BUG? This test cannot be random clipping item must belong to the group
		    next if ($boolean_attributes{$option}); # skipping boolean attributes which are exhaustively tested

		    my ($optionType, $readOnly, $empty, $optionValue) = @{$theoptions{$option}};
		    my $typeValues = $typesValues{$optionType};
		    if (!defined $typeValues) {&log (-100, "No values for type $optionType (option $option)\n");next;}
		    my @values = @{$typeValues};

		    if (!@values) {&log (-100, "No values for type $optionType (option $option)\n");next;}
			

		    my $valueRef = ref ($values[0]);
		    my $previous_val;
		    my @previous_val;

		    if ($valueRef eq '') {
			$previous_val = $zinc->itemcget($item, $option);
		    }
		    else {
			@previous_val = $zinc->itemcget($item, $option);
		    }
		    &log (1, "#**  itemconfigure of $item ($type), $option => ",&printableList (@values),"\n");
		    my $log_lev = ($opt_trace eq $option || $opt_trace eq $optionType ) ? 0 : 2 ;
		    foreach my $value (@values) {
			&test_eval ($log_lev, "itemconfigure", $item, $option => $value);
			$zinc->update;
			$zinc->after(10);
		    }
		    
		    if ($valueRef eq '') {
			&test_eval ($log_lev, "itemconfigure", $item, $option => $previous_val);
		    }
		    else {
			&test_eval ($log_lev, "itemconfigure", $item, $option => \@previous_val);
		    }
		    
		}
	    }
	}
    }
    &log (0, "#---- End of test_attributes ----\n");
} # end test_attributes


# test2: configurer les fields des track / waypoint / tabular
#        jouer avec les labelformats

# test3: tester toutes les fonctions aléatoirement selon les signatures


# test4: tester qu'en clonant on obtient bien une copie de tous les attributs

sub test_cloning {
    &log (-1000, "#---- Start of test_cloning ----\n");
    &creating_items;
    foreach my $type (@itemtypes) {
	my ($item) = $zinc->find('withtype', $type);
	&log (0, "#--------- Cloning and testing item ",$type," $item ----------------\n");
	if (!defined $item) { &log (-10, "No such item: $type\n"); next;};
	my $clone = &test_eval(1, "clone", $item);

	&log (0, "#---- Modifying the clone $clone\n");
	&test_a_clone ($type, $item, $clone);
	&test_enclosed_overlapping_closest($type, 'original', $item, $zinc->bbox ($item));
	&test_enclosed_overlapping_closest($type, 'clone', $clone, $zinc->bbox ($clone));
	&log (0, "#---- Modifying the original\n");
	&test_a_clone ($type, $clone, $item);
	&test_enclosed_overlapping_closest($type, 'original', $item, $zinc->bbox ($item));
	&test_enclosed_overlapping_closest($type, 'clone', $clone, $zinc->bbox ($clone));
	&log (0, "#---- Deleting the original\n");
	&test_eval (1, "remove", $item);
	&test_every_attributes_once($type,$clone);
	&log (0, "#---- Deleting the clone\n");
	&test_eval (1, "remove", $clone);
    }
    # tester le find enclosed / overlapping avec un rectangle un peu plus grand que la bbox
    # tester le closest avec le centre de la bbox
    
    # faire la même chose que juste avant, mais en interchangeant clone et original
    # tester le find enclosed / overlapping avec un rectangle un peu plus grand que la bbox
    # tester le closest avec le centre de la bbox
    
    # supprimer l'item original

    # tester le find enclosed / overlapping avec un rectangle un peu plus grand que la bbox
    # tester le closest avec le centre de la bbox

    # modifier tous les attributs du clone
    # supprimer le clone

    # tester le find enclosed / overlapping avec un rectangle un peu plus grand que la bbox
    # tester le closest avec le centre de la bbox
     
    &log (0, "#---- End of test_cloning ----\n");
} # end test_cloning

## teste le find enclosed / overlapping avec un rectangle un peu plus grand
#  que la bbox donnée en paramètre.
#  si $item est différent de '', vérifie que l'item est enclosed/overlapping 
## Vérifie aussi le fonctionnement ud closest pour le centre de la bbox
sub test_enclosed_overlapping_closest {
    my ($type, $clone_or_original, $item, @bbox) = @_;
    if ($#bbox == -1) {
	&log(-100, "Undef bbox of a $type ($clone_or_original)\n");
    }
    else {
	@bbox = ( $bbox[0]-10, $bbox[1]-10, $bbox[2]+10, $bbox[3]+10 );
	my @items = &test_eval (1, "find", 'enclosed', @bbox);
	goto TESTOVERLAPPING if ($item eq '');
	foreach my $i (@items) {
	    goto TESTOVERLAPPING if ($i eq $item); # the item is included!
	}
	&log(-100, "The $type ($clone_or_original) is not enclosed in its bbox!\n");
  TESTOVERLAPPING:
#	@items = $zinc->find ('overlapping', @bbox);
	@items = &test_eval (1, "find", 'overlapping', @bbox);
	goto TESTCLOSEST if ($item eq '');
	foreach my $i (@items) {
	    goto TESTCLOSEST if ($i eq $item);
	}
	&log(-100, "The $type ($clone_or_original) is not overlapping its bbox!\n");
  TESTCLOSEST:
	my $x = ($bbox[0] + $bbox[2] )/2;
	my $y = ($bbox[1] + $bbox[3] )/2;
#	my $closest = $zinc->find ('closest', $x,$y);
	my $closest = &test_eval (1, "find", 'closest', $x,$y);
    }
} # end test_enclosed_overlapping_closest

sub test_a_clone {
    my ($type, $original, $clone) = @_;
    my %theoptions = %{$options{$type}};
    foreach my $option (sort keys %theoptions) {
	next if ($option eq -numfields); # BUG? makes the appli stop
	next if ($option eq "-clip" and $type = "group"); # BUG? This test cannot be random. Clipping item must belong to the group
        next if ($option eq '-connecteditem'); ## XXX this test should be corrected implemented,
	my ($optionType, $readOnly, $empty, $optionValue) = @{$theoptions{$option}};
	my $value = $typesNonStandardValues{$optionType};
	if ($optionType ne 'boolean' && !defined $value) {
	    &log (-100, "No value for type $optionType (option $option)\n");
	    next;
	}
	
	my $valueRef = ref ($value);
	my $previous_val;
	my @previous_val;
	
	# memoryzing previous value of the clone 
	if ($valueRef eq '') {
	    $previous_val = &test_eval (2, "itemcget", $clone, $option);
	}
	else {
	    @previous_val = &test_eval (2, "itemcget", $clone, $option);
	}

	# in the case of boolean, we must always take the not value:
	if ($optionType eq 'boolean') { $value = !$previous_val }
	
	my $log_lev = ($opt_trace eq $option || $opt_trace eq $optionType) ? 0 : 2 ;
	&test_eval ($log_lev, "itemconfigure", $clone, $option => $value);
	$zinc->update;

	if ($valueRef eq 'ARRAY') {  # the value is a list
	    my @original_value = &test_eval (2, "itemcget", $original, $option);
	    my @clone_value = &test_eval (1, "itemcget", $clone, $option);
	    if ( &equal_flat_arrays (\@original_value, \@clone_value) ) {
		&log (-100, "Modified cloned $type gets the same value for $option (type $optionType) ". &printableArray(@original_value) . "\n");
	    }
	}
	else {  # the value is either a scalar or a class instance
	    my $original_value = &test_eval (2, "itemcget", $original, $option);
	    my $clone_value = &test_eval (2, "itemcget", $clone, $option);
	    if (defined $original_value && $original_value eq $clone_value) {
#		print "ORIGIN = ",$original_value, " $original_value CLONE = ",$clone_value,"\n";
		&log (-100, "Modified cloned $type gets the same value for $option (type $optionType) " .
		      "(original=cloned: " . &printableItem($original_value) .
		      "?=" . &printableItem($previous_val) .
		      " :previous)\n");
	    }
	}
	
	# setting back the previous value
	if ($valueRef eq '') {
	    &test_eval (1, "itemconfigure", $clone, $option => $previous_val);
	}
	else {
	    &test_eval (1, "itemconfigure", $clone, $option => \@previous_val);
	}
	
    }
} # end test_a_clone

sub test_every_attributes_once {
    my ($type, $item) = @_;
    my %theoptions = %{$options{$type}};
    foreach my $option (sort keys %theoptions) {
	next if ($option eq -numfields); # BUG? makes the appli stop
	next if ($option eq "-clip" and $type = "group"); # BUG? This test cannot be random. Clipping item must belong to the group
        next if ($option eq '-connecteditem'); ## XXX this test should be corrected implemented,
	my ($optionType, $readOnly, $empty, $optionValue) = @{$theoptions{$option}};
	my $value = $typesNonStandardValues{$optionType};
	if ($optionType ne 'boolean' && !defined $value) {
	    &log (-100, "No value for type $optionType (option $option)\n");
	    next;
	}
	# in the case of boolean, we must always take the not value:
	if ($optionType eq 'boolean') { $value = !$zinc->itemcget($item, $option) }
	
	my $log_lev = ($opt_trace eq $option || $opt_trace eq $optionType) ? 0 : 2 ;
	&test_eval ($log_lev, "itemconfigure", $item, $option => $value);
	$zinc->update;
    }
} # end test_every_attributes_once


sub test_every_field_attributes {
    &log (-1000, "#---- Start of test_every_field_attributes ----\n");
    foreach my $type qw(waypoint track tabular) {
	next unless $itemtypes{$type};
	my %theoptions = %fieldOptions;
	my @items = $zinc->find('withtype', $type);
	&log (0, "#--------- Testing field attributes of ", (1+$#items), " ",$type,"(s) ----------------\n");
	if ($#items == -1) {
	    &log (-100, "No such item: $type\n");
	    next;
	}
	foreach my $item (@items) {
	    ## il faudrait tester les options selon un ordre défini à l'avance
	    ## en passant par plusieurs occurences pour les options et en forçant
	    ## certaines valeurs, par exemple les valeurs booléennees... (visible/sensible/filled)
	    my @boolean_attributes;
	    my %boolean_attributes;
	    foreach my $option (sort keys %theoptions) {
		my ($optionType, $readOnly, $empty, $optionValue) = @{$theoptions{$option}};
		if ($optionType eq 'boolean') {
#		    next if $option =~ /-\w+sensitive/ ;   # to get rid of many track options!
#		    next if $option =~ /-filled\w+/ ;      # to get rid of many track options!
#		    next if $option =~ /-speed\w+/ ;      # to get rid of many track options!
#		    next if $option =~ /-\w+history/ ;      # to get rid of many track options!
		    push @boolean_attributes, $option;
		    $boolean_attributes{$option}=1;
		}
	    }
	    &log (0, "# $type (id $item) : ", ((2**(1+$#boolean_attributes)) , " Combinations (", join (', ' , @boolean_attributes),")\n"));
	    foreach my $i (0 .. (2**(1+$#boolean_attributes) -1) ) {
		my $format = "%0" . ($#{boolean_attributes} +1) . "b";
		my $binary = sprintf ($format,$i);
		&log (0, "# $i/", (2**(1+$#boolean_attributes)), "  $binary\n");
		my @binary = split (//,$binary);
		foreach my $j (0 .. $#boolean_attributes) {
		    &log (0, "# setting $type ($item) field 0..",$zinc->itemcget($item, -numfields)-1,  " ", $boolean_attributes[$j], " to ", $binary[$j], "\n");
		    foreach my $field (0 .. $zinc->itemcget($item, -numfields)-1 ) {
			&test_eval (1, "itemconfigure", $item, $field, $boolean_attributes[$j] => $binary[$j] );
		    }
		}
		foreach my $field (0 .. $zinc->itemcget($item, -numfields)-1 ) {
		    foreach my $option (sort keys %theoptions) {
			next if ($boolean_attributes{$option}); # skipping boolean attributes which are exhaustively tested
			
			my ($optionType, $readOnly, $empty, $optionValue) = @{$theoptions{$option}};

			my $typeValues = $typesValues{$optionType};
			if (!defined $typeValues) {&log (-100, "No values for type $optionType (option $option)\n");next;}
			my @values = @{$typeValues};
			
			if (!@values) {&log (-100, "No values for type $optionType (option $option)\n");next;}
			

			my $valueRef = ref ($values[0]);
			my $previous_val;
			my @previous_val;
			
			if ($valueRef eq '') {
			    $previous_val = &test_eval (1, "itemcget", $item, $field, $option);
			}
			else {
			    @previous_val = &test_eval (1, "itemcget", $item, $field, $option);
			}
			&log (1, "#**  itemconfigure ($item ($type), $field, $option => ",&printableList (@values),"\n");
			foreach my $value (@values) {
			    my $log_lev = ($opt_trace eq $option || $opt_trace eq $optionType) ? 0 : 2 ;
			    &test_eval ($log_lev, "itemconfigure", $item, $field, $option => $value);
			    $zinc->update;
			    $zinc->after(10);
			}
			
			if ($valueRef ne 'ARRAY') {
			    &test_eval (1, "itemconfigure", $item, $field, $option => $previous_val);
			}
			else {
			    &test_eval (1, "itemconfigure", $item, $field, $option => \@previous_val);
			}
		    
		    }}
	    }
	}
    }
    &log (0, "#---- End of test_every_field_attributes ----\n");
} # end test_every_field_attributes


sub createMapInfo {
    my ($name, $N,$deltaN, $radius, $centerX,$centerY) = @_;
    &test_eval (1, "mapinfo", $name, 'create'); 

    my @lineTypes=(qw/simple dashed dotted mixed marked/), 
    my $deltaAngle=6.283/$N;
    for (my $i = 0; $i < $N; $i++) {
	my $x1 = $centerX + $radius * sin($i * $deltaAngle); 
	my $y1 = $centerY + $radius * cos($i * $deltaAngle);
	my $x2 = $centerX+ $radius * sin( ($i + $deltaN) * $deltaAngle); 
	my $y2 = $centerY + $radius * cos( ($i + $deltaN)* $deltaAngle);
	my $linetype = $lineTypes[$i%5];
	$mw->mapinfo($name, 'add', 'line', $linetype, 1+$i%3, +$x1,$y1,$x2,$y2);
    }
} # end of createMapInfo

sub test_mapitems {
    my @mapinfoNames = @_;
    &log (-1000, "#---- Start of test_mapitems ----\n");
    my @maps = $zinc->find('withtype', 'map');
    my $counter=0;
    foreach my $map (@maps) {
	&test_eval (1, "itemconfigure", $map, -mapinfo => $mapinfoNames[$counter]);
	if ($counter == $#maps) { $counter=0 }
	$counter++;
    }
    &log (0, "#---- End of test_mapitems ----\n");
} # end test_mapitems

## testing the returned value of coords
sub test_coords {
    &log (-1000, "#---- Start of test_coords ----\n");
    foreach my $it ($zinc->find('withtag','*')) {
	$zinc->remove($it);
    }
    ## creationg again items
    &creating_items;
    foreach my $type ($zinc->add()) {
	next if $type eq 'map'; ## map item does not support coords method
	my ($it) = $zinc->find('withtype',$type);
	my @coordsAll= &test_eval (1, "coords", $it);
	my $coordsAll = &printableArray(@coordsAll);
	&log (1, "=> $coordsAll\n");
	my @coordsContour= &test_eval (1, "coords", $it,0); # all items have 1 contour
	my $coordsContour = &printableArray(@coordsContour);
	&log (1,"=> $coordsContour\n");
	my @coordsPoint= &test_eval (1, "coords", $it,0,0); # all items have 1 contour with at least one point
	my $coordsPoint = &printableArray(@coordsPoint);
	&log (1,"=> $coordsPoint\n");
    }
    &log (0, "#---- End of test_coords ----\n");
}
    
sub parseTestsOpt {
    my ($opt) = @_;
    my @tests;
    if ($opt eq '') {
	print "Availables tests are:\n";
	while (@testsList) {
	    my $i = shift @testsList;
	    my $comment = shift @testsList;
	    print "\t$i => $comment\n";
	}
	exit;
    } elsif ( $opt eq 'all' ) { ## default!
	&log (0, "# all tests will be passed through\n");
	@tests = sort keys %testsHash;
    } elsif ( $opt =~ /^\d+(,\d+)*$/ ) {
	@tests = split (/,/ , $opt);
	my $testnumb = (scalar @testsList) / 2;
	foreach my $test (@tests) {
	    die "tests num must not exceed $testnumb" if $test > $testnumb;
	}
	&log(0,  "# Tests to be done:\n");
	foreach my $test (@tests) {
	    &log(0,  "\t# $test => " . $testsHash{$test} . "\n");
	}
    } else {
	print "bad -tests value. Must be a list of integer separated by ,\n";
	&usage;
    }
    return @tests;
} # end of parseTestsOpt



# ---------- TEST ------------------
# the following code must be coherent with the tests list described
# on the very beginning of this file (see @testsList definition)

&createMapInfo ('firstmap', 50, 20, 200, 200, 300);
&createMapInfo ('secondmap', 12, 3, 200, 300, 50);

sub theTest {
  if ($tests{1}) {
    &test_mapitems ('firstmap', 'secondmap'); # should be done before really testing map items attributes
  }
  # #### &test_labelcontent; # should be done before really testing track/waypoint/tabular items attributes
  
  if ($tests{2}) {
    &test_every_field_attributes;
  }
  
  if ($tests{3}) {
    &test_attributes; # on peut configurer tous les attributs
  }

  ### we SHOULD test that setting a bad type value ofr an option does not core dump zinc!

  if ($tests{4}) {
    &test_cloning; # we test that cloning items and modifiyng/removing them does not core dump
  }

  ### we should also test multicontour curves
  if ($tests{5}) {
    &test_coords;
  }

# #### &test_fonts;  ## and specially big fonts with render = 1;
# #### &test_path_tags;
# #### &test_illegal_tags;

# #### &test_illegal_call
# for example:
#  calling a method for an non-existing item
#  getting coords, contours, fields, etc... of non-existing index
#
#  cloning, deleting topgroup
#
}

sub getMemoryUsage {
  open (PROC, "/proc/$$/status");
  my ($totalMemory,$dataMemory);
  while (<PROC>) {
    if (/^VmSize:\s+(\d+)/) {
      $totalMemory = $1;
    }
    elsif (/^VmData:\s+(\d+)/) {
      $dataMemory = $1;
      last;
    }
  }
  close PROC;
  return ($totalMemory,$dataMemory);
}



if ($opt_memoryleak) {
  my $iteration = 0;
  while (1) {
    my ($total,$data) = &getMemoryUsage;
    ## get here the current memory state
    &log(-1000, "#---- MemoryState iteration=$iteration totalMemory=$total  dataMemory=$data ----\n");
    $iteration++;
    &theTest;
  }
} else {
  &theTest;
}


&log (0, "#---- End of test_no_crash ----\n");

MainLoop();
