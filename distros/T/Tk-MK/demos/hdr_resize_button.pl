    use Tk;
    use Tk::HList;
    use Tk::HdrResizeButton;

    my $mw = MainWindow->new();

    # CREATE MY HLIST
    my $hlist = $mw->Scrolled('HList',
         -columns=>2, 
         -header => 1
         )->pack(-side => 'left', -expand => 'yes', -fill => 'both');

    # CREATE COLUMN HEADER 0
    my $headerstyle   = $hlist->ItemStyle('window', -padx => 0, -pady => 0);
    my $header0 = $hlist->HdrResizeButton( 
          -text => 'Test Name', 
          -relief => 'flat', -pady => 0, 
          -command => sub { print "Hello, world!\n" }, 
          -column => 0,
		  -resizerwidth => 3,
		  -closedminwidth => 20,
    );
	
    $hlist->header('create', 0, 
          -itemtype => 'window',
          -widget => $header0, 
          -style=>$headerstyle
    );

    # CREATE COLUMN HEADER 1
    my $header1 = $hlist->HdrResizeButton( 
          -text => 'Status', 
          -command => sub { print "Hello, world2!\n" }, 
          -column => 1,
		  
    );
    $hlist->header('create', 1,
          -itemtype => 'window',
          -widget   => $header1, 
          -style    => $headerstyle
    );


MainLoop;
