# ##############################################################################
# # Script     : Canvasprintdialog.pl                                          #
# # -------------------------------------------------------------------------- #
# # Copyright  : This program is free software; you can redistribute it and/or #
# #              modify it under the same terms as Perl itself.                #
# # Author     : Jürgen von Brietzke                                   JvBSoft #
# # Version    : 1.2.01                                            16.Jun.2013 #
# ##############################################################################
# # http://incrtcl.sourceforge.net/iwidgets/iwidgets/canvasprintdialog.html    #
# ##############################################################################

use strict;
use warnings;

use Tkx::TclTk::Bind::IWidgets;

# ##############################################################################

our $sz = "A4";
our $or = "landscape";

my $main_window = Tkx::widget->new(q{.});
$main_window->Tkx::wm_title('Canvasprintdialog Example');

my $canvasprintdialog = $main_window->new_iwidgets__Canvasprintdialog(
   -printcmd       => 'lpr',
   -modality       => 'application',
   -pagesize       => $sz,
   -orient         => $or,
   -posterize      => 1,
   -hpagecnt       => 1,
   -vpagecnt       => 2,
   -textbackground => 'ghostwhite',
);
$canvasprintdialog->buttonconfigure( 'OK', -text => 'Print' );
$canvasprintdialog->buttonconfigure( 'Apply',
   -command => $canvasprintdialog->refresh );
my $x1     = "1.0c";
my $x2     = "20.0c";
my $y1     = "1.0c";
my $y2     = "28.7c";
my $canvas = $main_window->new_tk__canvas();
Tkx::pack( $canvas, -expand => 'true', -fill => 'both' );
$canvas->create( 'rectangle', $x1, $y1, $x2, $y2 );
my $y = 150;
my $j = 0;

while ( $j < 3 ) {
   my $i = 0;
   my $x = 150;
   while ( $i < 15 ) {
      my $item;
      $item = $canvas->create( 'oval', -50, -50, 50, 50, -fill => 'red' );
      $canvas->move( $item, $x, $y );
      $item = $canvas->create( 'rectangle', -10, 0, 70, 100, -fill => 'blue' );
      $canvas->move( $item, $x, $y );
      $item = $canvas->create( 'text', 10, 130, -text => 'TEST!!!!' );
      $canvas->move( $item, $x, $y );
      $item = $canvas->create( 'bitmap', 20, 150, -bitmap => 'hourglass' );
      $canvas->move( $item, $x, $y );
      $x += 50;
      $i++;
   }
   $y += 200;
   $j++;
}
$canvasprintdialog->setcanvas($canvas);
Tkx::pack( forget => $canvas );

$canvasprintdialog->activate();
Tkx::MainLoop();

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
