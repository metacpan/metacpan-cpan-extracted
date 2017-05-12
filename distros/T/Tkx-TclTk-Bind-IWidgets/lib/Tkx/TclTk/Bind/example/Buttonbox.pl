# ##############################################################################
# # Script     : Buttonbox.pl                                                  #
# # -------------------------------------------------------------------------- #
# # Copyright  : This program is free software; you can redistribute it and/or #
# #              modify it under the same terms as Perl itself.                #
# # Author     : Jürgen von Brietzke                                   JvBSoft #
# # Version    : 1.2.01                                            16.Jun.2013 #
# ##############################################################################
# # http://incrtcl.sourceforge.net/iwidgets/iwidgets/buttonbox.html            #
# ##############################################################################

use strict;
use warnings;

use Tkx::TclTk::Bind::IWidgets;

# ##############################################################################

our $current = 0;
our $last    = 5;
our $buttonbox;

my $main_window = Tkx::widget->new(q{.});
$main_window->Tkx::wm_title('Buttonbox Example');
$buttonbox = $main_window->new_iwidgets__buttonbox(
   -padx => 10,
   -pady => 10,
);
foreach my $t (qw(more less)) {
   no strict;
   $buttonbox->add( $t, -text => $t, -command => \&{$t} );
   use strict;
}
foreach my $i ( 1 .. 5 ) {
   $buttonbox->add( "button$i", -text => "Button$i" );
   $buttonbox->hide("button$i");
}
$buttonbox->default('more');
Tkx::pack( $buttonbox, -expand => 'yes', -fill => 'both' );
Tkx::MainLoop();

# ------------------------------------------------------------------------------

sub more {
   if ( $current < $last ) {
      $buttonbox->show( $current + 2 );
      $current++;
   }
   if ( $current == $last ) {
      $buttonbox->default('less');
   }
   return;
} # end of sub more

sub less {
   if ( $current != 0 ) {
      $buttonbox->hide("button$current");
      $current--;
   }
   else {
      $buttonbox->default("more");
   }
   return;
} # end of sub less

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
