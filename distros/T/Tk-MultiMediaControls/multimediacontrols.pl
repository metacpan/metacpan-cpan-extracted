#!/usr/local/bin/perl -w

use Tk::Animation;
use lib '.'; use Tk::MultiMediaControls;
use Tk;
use strict;

my $mw = MainWindow->new;
my $file = ( @ARGV ) ? shift : 'images/penguin.gif';

my $img = $mw->Animation( '-format' => 'gif', -file => $file );
my $lab = $mw->Label( -image => $img );

my $controls = $mw->MultiMediaControls(

    # Define, from left to right, the application's controller buttons.

    -buttons                     => [ qw/ home rewind play stop fastforward / ],

    # Define callbacks for the buttons' various states.

    -fastforwardhighlightcommand => [ $img => 'fast_forward',   4 ],
    -fastforwardcommand          => [ $img => 'fast_forward',   1 ],
    -homecommand                 => [ $img => 'set_image',      0 ],
    -pausecommand                => [ $img => 'pause_animation'   ],
    -playcommand                 => [ $img => 'resume_animation'  ],
    -rewindhighlightcommand      => [ $img => 'fast_reverse',  -4 ],
    -rewindcommand               => [ $img => 'fast_reverse',   1 ],
    -stopcommand                 => [ $img => 'stop_animation'    ],

    # Define callbacks for the left and right arrow keys.

    -leftcommand                 => [ $img => 'prev_image'        ],
    -rightcommand                => [ $img => 'next_image'        ],

);

my $quit  = $mw->Button( -text => 'Quit', -command => [ destroy => $mw ] );

$lab->pack( $controls, $quit );

MainLoop;
