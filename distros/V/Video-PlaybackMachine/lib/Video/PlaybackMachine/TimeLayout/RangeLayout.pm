package Video::PlaybackMachine::TimeLayout::RangeLayout;

our $VERSION = '0.09'; # VERSION

####
#### Video::PlaybackMachine::TimeLayout::RangeLayout
####
#### $Revision$
####
#### A TimeLayout that indicates that the FillProducer can produce
#### content for a certain minimum and a certain maximum amount of
#### time.
####
#### An example is the FillShort producer, which plays short films.
#### It has short films available to it in a certain range of sizes.
#### It would return a RangeLayout consisting of the time of the
#### shortest short for the minimum and the time of the longest
#### fitting short for the maximum.
####
#### NOTE: Not currently in use. May be removed shortly.
####

use Moo;

use Carp;

############################ Class Constants #########################

############################# Class Methods ##########################

has 'min_time' => ( is => 'ro' );

has 'max_time' => ( is => 'ro' );

##
## new()
##
## Arguments:
##   min_time: int -- minimum amount of time we can run
##   max_time: int -- maximum amount of time we can run
##
sub BUILDARGS {
  my $type = shift;
  my ($min_time, $max_time) = @_;

  return { min_time => $min_time,
	       max_time => $max_time
	     };
}


############################ Object Methods ####################

##
## min_time()
##
## Returns the minimum amount of time the fill can take.
##

no Moo;

1;