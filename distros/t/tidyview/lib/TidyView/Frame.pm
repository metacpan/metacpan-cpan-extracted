package TidyView::Frame;

# the whole idea here is to try to centralise the creation of Tk::Frame widgets to one point of the code.
# However, it turns out we usually over-ride at least one of the defaults every time we create a frame,
# so perhaps it was a bad idea.

use strict;
use warnings;

use Tk;

our $frameDefaults = {
		      -relief      => 'ridge',
		      -borderwidth => 5,
		     };

our $packDefaults = {
		     -side   => 'left',
		     -fill   => 'both',
		     -expand => 1,
		    };

sub new {
  my (undef, %args) = @_;

  my ($parent, $frameOptions, $packOptions)  = @args{qw(parent frameOptions packOptions)};

  $frameOptions ||= {};
  $packOptions  ||= {};

  my %frameOptions = (%$frameDefaults, %$frameOptions);

  my %packOptions  = (%$packDefaults,  %$packOptions);

  my $frame = $parent->Frame(%frameOptions);

  $frame->pack(%packOptions);

  return $frame;
}
