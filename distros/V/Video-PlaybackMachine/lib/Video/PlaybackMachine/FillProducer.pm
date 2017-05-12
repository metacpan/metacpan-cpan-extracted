package Video::PlaybackMachine::FillProducer;

our $VERSION = '0.09'; # VERSION

use Moo::Role;

####
#### Video::PlaybackMachine::FillProducer
####
#### $Revision$
####
#### Interface for different ways of producing Fill content.
####

requires qw/start time_layout is_available has_audio/;

############################# Class Constants #############################

############################## Class Methods ##############################

############################# Object Methods ##############################

##
## start()
##
## Arguments:
##  TIME: int -- time in seconds that we're to fill
##
## Starts production of fill content. When it's ready, the
## FillProducer will send a 'still_ready' or 'movie_ready'
## signal.
##

##
## get_time_layout()
##
## Returns:
##   Video::PlaybackMachine::TimeLayout
##
## Returns a TimeLayout that tells us how long the given
## content should be played.
##

##
## is_available()
##
## Returns:
##   boolean
##
## Returns true if this producer has something it can do, false otherwise.
##

##
## has_audio()
##
## Returns:
##  boolean
##
## Returns true if this producer will produce audio content.
##

no Moo::Role;

1;
