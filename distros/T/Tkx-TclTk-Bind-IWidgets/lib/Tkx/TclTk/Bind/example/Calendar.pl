# ##############################################################################
# # Script     : Calendar.pl                                                   #
# # -------------------------------------------------------------------------- #
# # Copyright  : This program is free software; you can redistribute it and/or #
# #              modify it under the same terms as Perl itself.                #
# # Author     : Jürgen von Brietzke                                   JvBSoft #
# # Version    : 1.2.01                                            16.Jun.2013 #
# ##############################################################################
# # http://incrtcl.sourceforge.net/iwidgets/iwidgets/calendar.html             #
# ##############################################################################

use strict;
use warnings;

use Tkx::TclTk::Bind::IWidgets;

# ##############################################################################

my $main_window = Tkx::widget->new(q{.});
$main_window->Tkx::wm_title('Calendar Example');
my $calendar = $main_window->new_iwidgets__Calendar(
   -startday          => 'monday',
   -days              => 'M T W T F S S',
   -outline           => 'black',
   -weekendbackground => '#CCCCCC',
   -width             => 250,
   -height            => 200,
);
Tkx::pack( $calendar, -expand => 'yes', -fill => 'both' );
$calendar->select('yesterday');
print "Yesterday was: " . $calendar->get;
Tkx::MainLoop();

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
