package Video::PlaybackMachine::TimeLayout;

our $VERSION = '0.09'; # VERSION

####
#### Interface: Video::PlaybackMachine::TimeLayout
####
#### $Revision$
####
#### The one-dimensional equivalent of a Java LayoutManager.
#### Tells us the minimum and preferred times that a bit of Java
#### programming can last.
####
###
####

use Moo::Role;

requires qw/min_time preferred_time/;

no Moo::Role;

1;
