#!perl

package Ponfish::TermSize;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
#use Ponfish::Utilities;
use Ponfish::Config;

@ISA = qw(Exporter);
@EXPORT = qw(
);
$VERSION = '0.01';

my $singleton	= "";

##################################################################
sub new {
  my $type	= shift;
  if( ! $singleton ) {
    # Create the singleton
    $singleton	= bless {}, $type;
    $singleton->resize;

    # Install a signal handler for subsequent window resizes:
    $SIG{WINCH}	= sub {
      $singleton->resize;
    }
  }
  return $singleton;
}

sub COLUMNS {
  my $self	= shift;
  if( ! $self->{term_dimensions} ) {
    $self->resize;
  }
  return $self->{term_dimensions}{COLUMNS};
}
sub LINES {
  my $self	= shift;
  if( ! $self->{term_dimensions} ) {
    $self->resize;
  }
  return $self->{term_dimensions}{LINES} - 5;
}

sub resize {
  my $self	= shift;
  if( WINDOWS ) {
    my($width, $height)	= @_;
    $self->{term_dimensions}{COLUMNS}	= $width || $Global::args::columns || 80;
    $self->{term_dimensions}{LINES}	= $height || $Global::args::lines || 25;
  }
  else {
    my $resize_data	= `resize`;
    $_	= $resize_data;
    if ( /COLUMNS=(\d+)/m ) {
      $self->{term_dimensions}{COLUMNS}	= $1;
    }
    if ( /LINES=(\d+)/m ) {
      $self->{term_dimensions}{LINES}	= $1;
    }
  }
  if( $self->{CB_OBJECT} ) {
    my $METHOD	= $self->{CB_METHOD};
    my @ARGS	= ();
    if( $self->{CB_ARGS} ) {
      @ARGS	= @{$self->{CB_ARGS}};
    }
    $self->{CB_OBJECT}->$METHOD( @ARGS );
  }
}

=item register_callback OBJECT METHOD [ARGS]

Set a callback OBJECT through wich METHOD will be invoked with optional ARGS
when a resize event is processed.

=cut

sub register_callback {
  my $self	= shift;
  $self->{CB_OBJECT}	= shift || die "No OBJECT passed to register_callback";
  $self->{CB_METHOD}	= shift || die "No METHOD passed to register_callback";
  $self->{CB_ARGS}	= shift || undef;
}

=item clear_callback

Clears callback object / method / etc.

=cut

sub clear_callback {
  my $self	= shift;
  delete $self->{CB_OBJECT};
  delete $self->{CB_METHOD};
  delete $self->{CB_ARGS};
}


1;
