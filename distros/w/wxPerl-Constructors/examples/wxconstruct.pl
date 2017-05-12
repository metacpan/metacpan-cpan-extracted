#!/usr/bin/perl

use warnings;
use strict;

use wxPerl::Constructors;

# every application must create an application object
package MyApp;

use base 'Wx::App';

# this method is called automatically when an application object is
# first constructed, all application-level initialization is done here
sub OnInit {

    # create a new frame (a frame is a top level window)
    my $frame = wxPerl::Frame->new(undef,
                                'wxPerl rules',
                                size => [250, 150],
                               );

    my $menu = 'Wx::Event::EVT_MENU';
    $frame->$menu(0,0);

    # show the frame
    $frame->Show( 1 );
    print 4 * (split(/\s/, `cat /proc/$$/statm`))[0], "\n";
}

package main;

# create the application object, this will call OnInit
my $app = MyApp->new;
  #Wx::Event::EVT_IDLE($app, sub {warn "bye"; shift->ExitMainLoop});
# process GUI events from the application this function will not
# return until the last frame is closed
$app->MainLoop;
# vim:ts=2:sw=2:et:sta
