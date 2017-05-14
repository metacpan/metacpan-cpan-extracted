#!perl
use strict;

use lib '/Homes/xpix/projekts/Tk-Moduls', 
	'X:\projekts\Tk-Moduls';

    use Tk;
    use Tk::HList;
    use Tk::ResizeButton;

    my $mw = MainWindow->new();

    # CREATE MY HLIST
    my $hlist = $mw->Scrolled('HList',
         -columns=>2, 
         -header => 1
         )->pack(-side => 'left', -expand => 'yes', -fill => 'both');

    # CREATE COLUMN HEADER 0
    my $headerstyle   = $hlist->ItemStyle('window', -padx => 0, -pady => 0);
    my $header0 = $hlist->ResizeButton( 
          -text => 'Test Name', 
          -relief => 'flat', -pady => 0, 
          -command => sub { print "Hello, world!\n";}, 
          -widget => \$hlist,
          -column => 0
    );
    $hlist->header('create', 0, 
          -itemtype => 'window',
          -widget => $header0, 
          -style=>$headerstyle
    );

    # CREATE COLUMN HEADER 1
    my $header1 = $hlist->ResizeButton( 
          -text => 'Status', 
          -relief => 'flat', 
          -pady => 0,
          -command => sub { print "Hello, world!\n";}, 
          -widget => \$hlist, 
          -column => 1
    );
    $hlist->header('create', 1,
          -itemtype => 'window',
          -widget   => $header1, 
          -style    =>$headerstyle
    );

MainLoop;
