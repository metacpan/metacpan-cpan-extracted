# ##############################################################################
# # Script     : Canvasprintbox.pl                                             #
# # -------------------------------------------------------------------------- #
# # Copyright  : This program is free software; you can redistribute it and/or #
# #              modify it under the same terms as Perl itself.                #
# # Author     : Jürgen von Brietzke                                   JvBSoft #
# # Version    : 1.2.01                                            16.Jun.2013 #
# ##############################################################################
# # http://incrtcl.sourceforge.net/iwidgets/iwidgets/canvasprintbox.html       #
# ##############################################################################

use strict;
use warnings;

use Tkx::TclTk::Bind::IWidgets;

# ##############################################################################

my $main_window = Tkx::widget->new(q{.});
$main_window->Tkx::wm_title('Canvasprintbox Example');
my $canvasprintbox = $main_window->new_iwidgets__canvasprintbox(
   -stretch  => 0,
   -filename => 'canvas_out.ps',
   -orient   => 'portrait',
   -output   => 'file',
   -pagesize => 'Letter',
);
Tkx::pack($canvasprintbox);
my $canvas = $main_window->new_tk__canvas();
Tkx::pack( $canvas, -expand => 'true', -fill => 'both' );
$canvas->create( 'oval', 50,  50, 100, 100, -fill => 'red' );
$canvas->create( 'oval', 100, 50, 150, 100, -fill => 'green' );
$canvasprintbox->setcanvas($canvas);
Tkx::pack( forget => $canvas );
my $label = $main_window->new_ttk__label( -relief => 'raised' );
Tkx::pack( $label, -fill => 'x', -expand => 'true' ),
   $label->configure(
   -text => 'The output will go to: ' . $canvasprintbox->getoutput );

Tkx::MainLoop();

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
