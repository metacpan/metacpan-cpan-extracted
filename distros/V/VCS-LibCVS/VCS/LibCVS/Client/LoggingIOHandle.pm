#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::LoggingIOHandle;

use strict;
use IO::Handle;

#
# An IO::Handle which logs everything that goes through it.  Useful for
# debugging protcol implementations
#

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/LoggingIOHandle.pm,v 1.5 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("IO::Handle");

###############################################################################
# Private variables
###############################################################################

# $self->{next}        The wrapped IOHandle, to which calls are forwarded
# $self->{Prefix}      String to prepend to each line
# $self->{LogOutput}   IOHandle where output is duplicated, with optional prefix
# $self->{NotNewLine}  False when a new line has just been printed, so the next
#                      line can be prepended with the prefix.

###############################################################################
# Class routines
###############################################################################

# A new LoggingIOHandle is built around an existing IO::Handle.  The
# constructor takes one arg, which is an IO::Handle.
sub new {
  my $class = shift;
  my $ioh   = shift;

  my $that = bless {}, $class;
  $that->{next} = $ioh;
  $that->logfile();
  $that->{NotNewLine} = 0;
  return $that;
}

###############################################################################
# Instance routines
###############################################################################

# It doesn't put the prefix on each line of multiple line prints
# and doesn't handle multiple line prints properly
sub print {
  my $self = shift;
  if ($self->{Prefix} && (!$self->{NotNewLine})) {
    $self->{LogOutput}->print($self->{Prefix});
  }

  # Set NotNewLine
  if (!$self->{NotNewLine}) {
    $self->{NotNewLine} = 1;
  }
  map { $self->{NotNewLine} = 0 if /\n/ } @_;

  $self->{LogOutput}->print(@_);
  $self->{LogOutput}->flush;

  return $self->{next}->print(@_);
}

sub getc {
  my $self = shift;
  my $char = $self->{next}->getc();

  if (($self->{Prefix}) && (!$self->{NotNewLine})) {
    $self->{LogOutput}->print($self->{Prefix});
  }

  $self->{NotNewLine} = ($char ne "\n");
  $self->{LogOutput}->print($char);
  $self->{LogOutput}->flush();

  return $char;
}

sub getline {
  my $self = shift;
  my $line = $self->{next}->getline();

  if (($self->{Prefix}) && (!$self->{NotNewLine})) {
    $self->{LogOutput}->print($self->{Prefix});
  }

  $self->{NotNewLine} = 0;
  $self->{LogOutput}->print($line);
  $self->{LogOutput}->flush();

  return $line;
}

sub read {
  my $self = shift;
  return $self->{next}->read(@_);
}

# set and get the prefix to use
# Undefined means don't print a prefix
sub prefix {
  my ($self, $new_prefix) = @_;
  $self->{Prefix} = $new_prefix if (defined $new_prefix);
  return $self->{Prefix};
}

# set the output filename
# If it's undefined, STDERR is used
sub logfile {
  my ($self, $filename) = @_;
  if (defined $filename) {
    $self->{LogOutput} = IO::File->new(">> $filename");
  } else {
    $self->{LogOutput} = IO::Handle->new_from_fd(fileno(STDERR), ">>");
  }
}

###############################################################################
# Private routines
###############################################################################

1;
