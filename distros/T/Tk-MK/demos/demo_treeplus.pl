    use Tk;
    use Tk::Treeplus;
	use FindBin;

# 	Tk::CmdLine::LoadResources(-file => "$FindBin::Bin/Treeplus.xrdb", -priority => '61',
# 								#, -echo => \*STDOUT
# 	);

    my $mw = MainWindow->new();
	print "Tk Version: >" . $Tk::version. " (" . $Tk::VERSION. ")\n";

    # CREATE MY HLIST
    my $hlist = $mw->Scrolled('Treeplus',
		-columns => 5, 
		-width => 70, height => 30,
#		-browsecmd => sub { print "DBG: browsecmd [".((caller(0))[3])."] with >@_<\n";  },
		-browsecmd => sub {  },
		-wrapsearch => 1,
#		-indicator => 0, # If this is a flat list, we may drop the empty indicator space
		
    )->pack(-expand => '1', -fill => 'both');

    $hlist->headerCreate(0, 
          -itemtype => 'advancedheader',
          -text => 'ColorName', 
		  -activeforeground => 'white',
		  -is_primary_column => 1,
    );
    $hlist->headerCreate(1, 
          -itemtype => 'advancedheader',
          -text => 'Red Value', 
          -activebackground => 'orange',
		  -resize_column => 1,
    );
#     $hlist->headerCreate(2, 
#           -itemtype => 'advancedheader',
    $hlist->advancedHeaderCreate(
          -text => 'Green Value', 
          -background => 'khaki',
          -foreground => 'red',
		  -command => sub { print("Hello World >@_<, pressed Header #2\n"); },
		  -resize_column => 1,
    );
#     $hlist->headerCreate(3, 
#           -itemtype => 'advancedheader',
    $hlist->advancedHeaderCreate(
          -text => 'Blue Value', 
          -activebackground => 'skyblue',
		  # NOTE: The prototyping ($$) is MANDATORY for this search-func to work !!!
		  -sort_func_cb => sub ($$) { my ($a, $b) = @_; 
									  print "EXT: a=>$a<>" . join(',',@$a) . "<\n";
									  $a->[1] <=> $b->[1] },
    );
#     $hlist->headerCreate(4, 
#           -itemtype => 'advancedheader',
    $hlist->advancedHeaderCreate(
          -text => 'ColorID', 
		  -sort_numeric => 1,
		  -resize_column => 1,
    );

	my $image = $hlist->Pixmap(-data => <<'img_demo_EOP'
	/* XPM */
	static char *Up[] = {
	"8 5 3 1",
	". c none",
	"X c black",
	"Y c red",
	"...YY...",
	"..YXXY..",
	".YXXXXY.",
	"..YXXY..",
	"...YY...",
	};
img_demo_EOP
	);
	my $style = $hlist->ItemStyle(qw(imagetext -padx 0 -pady 5 -anchor sw -background forestgreen));
	my $child;
	foreach (qw( orange red green blue purple wheat)) {
		my ($r, $g, $b) = $mw->rgb($_);
		$hlist->add($_, -data => '*1*:data+' . $_, (/blue/ ? (-itemtype => 'imagetext') : ()) );
		$hlist->itemCreate($_, 0, -text => $_, (/blue/ ? (-itemtype => 'imagetext', -image => $image) : ()));
		$hlist->itemCreate($_, 1, -text => sprintf("%#x", $r), style => $style);
		$hlist->itemCreate($_, 2, -text => sprintf("%#x", $g));
		$hlist->itemCreate($_, 3, -text => sprintf("%#x", $b));
		$hlist->itemCreate($_, 4, -text => sprintf("%d", (($r<<16) | ($b<<8) | ($g)) ));
	}
	# Create smoe more dummy entries
	foreach (qw(red green blue)) {
		$child = $hlist->addchild('purple', -data => '*2*:data+purple+' . $_);
		create_columns($child, $_);
	}
	foreach (qw(cyan magenta yellow)) {
		my $gchild = $hlist->addchild($child, -data => '*3*:data+'.$child.'+' . $_);
		create_columns($gchild, $_);
	}
	
	#-------------------------------------------------------------------
	### Uncomment either none, #1 or #2 for different scenarios
	#--------------------------------------
	# #1 Test for single closed branch
	#$hlist->setmode($child, 'close');
	#--------------------------------------
	# #2 Test for 'full tree mode'
	$hlist->autosetmode();
	#-------------------------------------------------------------------

	# Refresh the content - sort according primary sort columns
 	$hlist->initSort();

	$mw->Button(
		-text => 'Exit',
		-command => sub { exit(0) },
	)->pack(qw(-side bottom -pady 10));
	
    Tk::MainLoop;

sub create_columns
{
	my ($path, $value) = @_;
	my ($r, $g, $b) = $mw->rgb($_);
	$hlist->itemCreate($path, 0, -text => $value);
	$hlist->itemCreate($path, 1, -text => sprintf("%#x", $r));
	$hlist->itemCreate($path, 2, -text => sprintf("%#x", $g));
	$hlist->itemCreate($path, 3, -text => sprintf("%#x", $b));
	$hlist->itemCreate($path, 4, -text => sprintf("%d", (($r<<16) | ($b<<8) | ($g)) ));
}
