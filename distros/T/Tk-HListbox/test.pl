#!/usr/bin/perl -w

## THIS THE TEST SCRIPT THAT HANS PROVIDED WITH SMLISTBOX

## SMListbox demonstration application. This is a simple directory browser
## Original Author: Hans J. Helgesen, December 1999.
## Modified by: Rob Seegel, to work in Win32 as well
## Use and abuse this code. I did - RCS

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::stat;
use Tk;
use Tk::HListbox;
$loaded = 1;
print "ok 1\n";
if ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
	print "skipping 2\n";
	print "skipping 3\n";
	print "skipping 4\n";
	print "skipping 5\n";
	print "..done: 1 tests completed, 4 tests skipped.\n";
	exit (0);
}

	my ( @array, $scalar, $other );
	my %options = ( ReturnType => "index" );

## Create main perl/tk window.
	my $MW = MainWindow->new;

print $MW ? "ok 2\n" : "not ok 2 main Tk window not created?!\n";

	my $licon=$MW->Photo(-file => './licon.xpm');
	my $wicon=$MW->Photo(-file => './wicon.xpm');

print $MW ? "ok 3\n" : "not ok 3 ($@$? - image object not created (icon.xpm MISSING)?!)\n";

	my $lbox = $MW->Scrolled('HListbox',
			-scrollbars => 'se', 
			-selectmode => 'extended',
			-itemtype => 'imagetext',
			-indicator => 1,
			-indicatorcmd => sub {
				print STDERR "---indicator clicked---(".join('|',@_).")\n";
			},
			-browsecmd => sub { 
				print STDERR "---browsecmd!---(".join('|',@_).")\n";
			},
	)->pack(-fill => 'y', -expand => 1);

	$MW->Button(   #MAIN WINDOW BUTTON TO QUIT.
			-text => 'Bonus Tests', 
			-underline => 0,
			-command => sub
	{
	#FETCH THE 2ND ITEM AND DISPLAY IT'S TEXT:
		$_ = $lbox->get(1);
		if (ref $_) {
			print "-2nd value=$_= TEXT=".$_->{'-text'}."=\n";
		} else {
			print "-2nd value=$_=\n";
		}
	#FETCH AND PRINT OUT THE SELECTED ITEMS:
		my @v = $lbox->curselection;
		print "--SELECTED=".join('|', @v)."= vcnt=$#v= MODE=".$lbox->cget('-selectmode')."=\n";
		for (my $i=0;$i<=$#v;$i++)
		{
			my $ent = $lbox->get($v[$i]);
			print "--selected($i)=$ent=\n";
			print "-----TEXT=".$ent->{'-text'}."=\n"  if (defined $ent->{'-text'});
		}
	#PRINT WHETHER THE LAST ITEM IS CURRENTLY SELECTED (2 WAYS):
		print "--select includes last one =".$lbox->selectionIncludes('end')."=\n";
		print "--select includes last one =".$lbox->selection('includes','end')."=\n";
	#FETCH THE OLD ANCHOR AND SET THE ANCHOR TO THE 2ND ITEM:
		my $anchorWas = $lbox->index('anchor');
		$lbox->selectionAnchor(8);
		my $anchorNow = $lbox->index('anchor');
	#DELETE THE 4TH ITEM & ****TURN OFF INDICATORS!**** TO SHOW NORMAL VIEW:
		$lbox->delete(4);
		$lbox->configure(-indicator => 0);
	#SET THE VIEWPORT TO SHOW THE FIRST SELECTED ITEM:
		$lbox->yview($v[0]);
	#PRINT THE DATA RETURNED BY yview() AND THE LAST ITEM;
		my @yview = $lbox->yview;
		my $last = $lbox->index('end');
		print "--YVIEW=".join('|',@yview)."= last=$last=\n";
	#FETCH THE INDEX OF THE LAST ITEM:
		#FETCH AND DISPLAY SOME ATTRIBUTES:
		print "--anchor was=$anchorWas= now=$anchorNow= yview=".join('|',@yview)."=\n";
		print "--active=".$lbox->index('active')."=\n";
		print "-reqheight=".$lbox->reqheight."= height=".$lbox->cget('-height')."= size=".$lbox->size."=\n";
	#PRINT OUT THE VALUES OF THE TIED VARIABLES:
		print "-scalar=".join('|',@{$scalar})."=\n-array=".join('|',@array)."=\n-other=".join('|',@{$other})."=\n";
		foreach my $e (@{$other}) {
			my $ent = $lbox->get($e);
			print "----selected index($e)=$ent=\n";
			print "-----TEXT=".$ent->{'-text'}."=\n"  if (defined $ent->{'-text'});
		}
	#RECONFIGURE 2ND ITEM TO FOREGROUND:=GREEN:
		$lbox->itemconfigure(1,'-fg', 'green');
	#FETCH THE HList STYLE OBJECT FOR 2ND ITEM:
		print "-itemcget(1)=".$lbox->itemcget(1, '-style')."=\n";
	#FETCH JUST THE Listbox FOREGROUND COLOR FOR 2ND ITEM:
		print "-itemcget(2)=".$lbox->itemcget(1, '-fg')."=\n";
	#FETCH THE "NEAREST" INDEX TO THE 2ND ITEM:
		print "-nearest(1)=".$lbox->nearest(1)."=\n";
	#ADD AN ELEMENT VIA THE TIED ARRAY:
		push @array, {-image => $licon, -text => 'ArrayAdd0!'};
	#DELETE THE LAST ITEM USING THE TIED ARRAY:
		pop @array;
	#ADD IT BACK VIA THE TIED ARRAY:
		push @array, {-image => $licon, -text => 'ArrayAdd!'};
	}
	)->pack(
			-side => 'bottom'
	);
	$MW->Button(   #MAIN WINDOW BUTTON TO QUIT.
			-text => 'Quit', 
			-underline => 0,
			-command => sub { print "ok 5\n..done: 5 tests completed.\n"; exit(0) }
	)->pack(
			-side => 'bottom'
	);

	#ADD SOME ITEMS (IMAGE+TEXT) TO OUR LISTBOX THE TRADITIONAL WAY:
		my @list = ( 
			{-image => $licon, -text => 'a'},
			{-image => $wicon, -text => 'bbbbbbbbbbbbbbbbbbbB', -foreground => '#0000FF' },
			{-text => 'c', -image => $licon},
			{-text => 'd:image & indicator!', -image => $licon, -indicatoritemtype, 'image', -indicatorimage => $wicon},
			{-image => $licon, -text => 'e'},
			{-image => $licon, -text => 'f'},
			{-image => $licon, -text => 'z:Next is Image Only!'},
			$licon
		);
		$lbox->insert('end', @list );
		@list = ();
	#ADD A BUNCH MORE JUST BEFORE THE 7TH ITEM ("
		foreach my $i ('G'..'Y')
		{
			push @list, {-image => $licon, -text => $i};
		}
		$lbox->insert(6, @list );

	#SET THE 3RD AND 5TH ITEMS AS INITIALLY-SELECTED:
		$lbox->selectionSet(2,4);
	#AND ONE WITH AN "INDICATOR IMAGE" JUST BEFORE THE 4TH ITEM:
		$lbox->insert(3, 'TextOnly at 3', 
				{'-text' => '<Click Indicator Icon', '-indicatoritemtype', 'image', '-indicatorimage' => $wicon});

	#TIE SOME VARIABLES TO THE LISTBOX:
		tie @array, "Tk::HListbox", $lbox;
		tie $scalar, "Tk::HListbox", $lbox;
		tie $other, "Tk::HListbox", $lbox, %options;

	MainLoop;
