#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::Root;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::Root - A CVS datum for a CVS Root specification

=head1 SYNOPSIS

  $root = VCS::LibCVS::Datum::Root->new(':pserver:user@cvs.cvshome.org:/cvs');

=head1 DESCRIPTION

A CVS Root specification.

  [ : <protocol> : [ <username> @ <hostname> [ : <port> ] ] ] <rootdir>

If only the rootdir is specified, protocol will be reported as "local".

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/Root.pm,v 1.19 2005/10/10 12:52:12 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Protocol}  "local", "ext", "pserver", . . .
# $self->{UserName}  for ext and pserver
# $self->{HostName}  for ext and pserver
# $self->{Port}      for ext and pserver
# $self->{RootDir}

###############################################################################
# Class routines
###############################################################################

sub new {
  my $class = shift;

  my $that = $class->SUPER::new(@_);

  # If it starts with a /, it's a local directory name.
  if ($that->{Root} =~ m/^\//) {
    $that->{Protocol} = "local";
    $that->{RootDir}  = $that->{Root};

  # If it starts with a :, then the protocol has been specified, and the
  # hostname is optional.
  } elsif ($that->{Root} =~ /^:[^\/]+\//) {
    $that->{Root} =~ /^:([^:]*):?(([^\@]*)\@)?([^:\/]*)(:([0-9]*))?(\/.*)$/;
    $that->{Protocol} = $1;
    $that->{UserName} = $3 || getlogin();
    $that->{HostName} = $4;
    $that->{Port}     = $6;
    $that->{RootDir}  = $7;

  # Otherwise it's remote without the protocol specified, starting with the
  # hostname.  This allows for the perverse case, where there are no :'s, such
  # as fire/var/cvs which is on host fire, in directory /var/cvs.
  } elsif ($that->{Root} =~ /^[^\/]+\//) {
    $that->{Root} =~ /^(([^\@]*)\@)?([^:\/]*)(:([0-9]*))?(\/.*)$/;
    $that->{Protocol} = "ext";
    $that->{UserName} = $2 || getlogin();
    $that->{HostName} = $3;
    $that->{Port}     = $5;
    $that->{RootDir}  = $6;

  } else {
    confess "Couldn't parse Root: $that->{Root}";
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_dir()>

$dir = $root->get_dir()

=over 4

=item return type: scalar string

The name of the root directory.

=back

=cut

sub get_dir {
  my $self = shift;
  return $self->{RootDir};
}


###############################################################################
# Private routines
###############################################################################

sub _data_names { return ("Root"); }

# Should have accessors for each chunk of data.

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
