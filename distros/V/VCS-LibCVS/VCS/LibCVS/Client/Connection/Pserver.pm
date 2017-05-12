#
# Copyright (c) 2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Client::Connection::Pserver;

use strict;
use Carp;
use IO::Socket::INET;

=head1 NAME

VCS::LibCVS::Client::Connection::Pserver - a connection to a cvs pserver

=head1 SYNOPSIS

  my $conn = VCS::LibCVS::Client::Connection->new($root);

=head1 DESCRIPTION

A connection to cvs process on a remote machine using the pserver protocol.
See VCS::LibCVS::Client::Connection for an explanation of the API.

The connection is establised through the network.  The default port is the
standard pserver port, 2401.

=head1 SUPERCLASS

  VCS::LibCVS::Client::Connection

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Client/Connection/Pserver.pm,v 1.7 2005/10/10 12:52:11 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Client::Connection");

###############################################################################
# Initializer
###############################################################################

# register protocols supported by this connection, and authentication functions
sub BEGIN {
  my $class = "VCS::LibCVS::Client::Connection::Pserver";
  $VCS::LibCVS::Client::Connection::Protocol_map{"pserver"} = $class;

  push @VCS::LibCVS::Authentication_Functions, \&auth_cvspass;
}

###############################################################################
# Class variables
###############################################################################

=head2 $Admin_Dir_Name    scalar string, default "CVS"

The name of the sandbox admin directory.

=cut

use vars ('$Search_CvsPass', '$Prompt', '$Store_CvsPass');
$Search_CvsPass = 1;
$Prompt         = 1;
$Store_CvsPass  = 1;


###############################################################################
# Private variables
###############################################################################

# $self->{Root}    VCS::LibCVS::Datum::Root object for my repository.
# $self->{Socket}  IO::Socket::INET object for connection to repository.

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$pserver_connection = VCS::LibCVS::Client::Connection::Ext->new($root)

=over 4

=item argument 1 type: VCS::LibCVS::Datum::Root

=item return type: VCS::LibCVS::Client::Connection::Pserver

=back

Construct a new external CVS connection.

=cut

sub new {
  my $class = shift;
  my $root = shift;

  my $that = bless {}, $class;
  $that->{Root} = $root;
  return $that;
}

=head2 B<auth_cvspass()>

An authentication routine which does pserver logins using the ~/.cvspass file.
By default it will search for the necessary password in ~/.cvspass.  If the
password isn't there (and it's running on a tty) it will prompt for it, and
write it to the ~/.cvspass file.  This behaviour can be customized by several
variables, described below.

This function is loaded into the LibCVS authentication function list, and
observes the parameters and return values of those functions.  See the
documentation for @VCS::LibCVS::Authentication_Functions for more details.

The following configuration parameters are available:

=over

=item $VCS::LibCVS::Client::Connection::Pserver::Search_CvsPass

Boolean, whether or not to search the ~/.cvspass file.

=item $VCS::LibCVS::Client::Connection::Pserver::Prompt

Boolean, whether or not to prompt for a password.

=item $VCS::LibCVS::Client::Connection::Pserver::Store_CvsPass

Boolean, whether or not to write a prompted password to ~/.cvspass.
Search_CvsPass and Prompt must also be true for this to happen.

=back

=cut

sub auth_cvspass {
  my ($scheme, $needed, $info) = @_;
  return if ($scheme ne "pserver");

  my $scrambled;

  # Search the ~/.cvspass file if requested.
  if ($Search_CvsPass) {
    my $cvspass = VCS::LibCVS::Client::Connection::CvsPass->new();
    $scrambled = $cvspass->get_password($info->{CVSRoot});
  }

  # Prompt for the password if requested, necessary and on a tty.
  if ((! defined $scrambled) && ($Prompt) && (-t)) {
    my $password;
    print "CVS pserver is insecure, don't use it\n";
    print "CVS pserver password for " . $info->{CVSRoot}->as_string() . ":";
    system "stty -echo"; chomp($password = <STDIN>); system "stty echo";
    print "\n";
    $scrambled = pserver_scramble($password);

    # Write the newly acquired password to the ~/.cvspass file, if requested.
    if ($Search_CvsPass && $Store_CvsPass) {
      my $cvspass = VCS::LibCVS::Client::Connection::CvsPass->new();
      $cvspass->store_password($info->{CVSRoot}, $scrambled);
    }
  }

  my %ret = ("scrambled_password" => $scrambled);
  return \%ret;
}

###############################################################################
# Private routines
###############################################################################

# The pserver cipher, copied from cvsclient.info
use vars ('%pserver_cipher');
my %pserver_cipher =
(
                 '0' => 111,               'P' => 125,               'p' =>  58,
    '!' => 120,  '1' =>  52,  'A' =>  57,  'Q' =>  55,  'a' => 121,  'q' => 113,
    '"' =>  53,  '2' =>  75,  'B' =>  83,  'R' =>  54,  'b' => 117,  'r' =>  32,
                 '3' => 119,  'C' =>  43,  'S' =>  66,  'c' => 104,  's' =>  90,
                 '4' =>  49,  'D' =>  46,  'T' => 124,  'd' => 101,  't' =>  44,
    '%' => 109,  '5' =>  34,  'E' => 102,  'U' => 126,  'e' => 100,  'u' =>  98,
    '&' =>  72,  '6' =>  82,  'F' =>  40,  'V' =>  59,  'f' =>  69,  'v' =>  60,
    '\'' => 108, '7' =>  81,  'G' =>  89,  'W' =>  47,  'g' =>  73,  'w' =>  51,
    '(' =>  70,  '8' =>  95,  'H' =>  38,  'X' =>  92,  'h' =>  99,  'x' =>  33,
    ')' =>  64,  '9' =>  65,  'I' => 103,  'Y' =>  71,  'i' =>  63,  'y' =>  97,
    '*' =>  76,  ':' => 112,  'J' =>  45,  'Z' => 115,  'j' =>  94,  'z' =>  62,
    '+' =>  67,  ';' =>  86,  'K' =>  50,               'k' =>  93,
    ',' => 116,  '<' => 118,  'L' =>  42,               'l' =>  39,
    '-' =>  74,  '=' => 110,  'M' => 123,               'm' =>  37,
    '.' =>  68,  '>' => 122,  'N' =>  91,               'n' =>  61,
    '/' =>  87,  '?' => 105,  'O' =>  35,  '_' =>  56,  'o' =>  48,
);

# Scramble a password pserver style

sub pserver_scramble {
  # Reverse, since chop works from the end
  my $plain_r = reverse(shift);
  my $scrambled = "A";

  while ($plain_r) {
    $scrambled .= chr($pserver_cipher{chop($plain_r)});
  }

  return $scrambled;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<connect()>

$client->connect()

=over 4

=item return type: undef

=back

Connect to a CVS repository via a pserver.  This opens the connection to the
pserver and authenticates, leaving IO::Handles available for talking to the
server.

=cut

sub connect {
  my $self = shift;

  return if $self->connected();

  $self->SUPER::connect();

  # Ask the authentication callbacks for the pserver password
  my %info = ( "CVSRoot" => $self->{Root} );
  my @needed = ("scrambled_password");
  my $password;

  foreach my $auth_func (@VCS::LibCVS::Authentication_Functions) {
    my $result = &$auth_func("pserver", \@needed, \%info);
    if (defined $result && defined $result->{"scrambled_password"}) {
      $password =  $result->{"scrambled_password"};
      last;
    }
  }

  confess "No password for " . $self->{Root}->as_string if ! defined $password;

  # Open the connection to the pserver
  my $host = $self->{Root}->{HostName};
  my $port = $self->{Root}->{Port} || 2401;
  $self->{Socket} = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port);

  confess "Could not connect to " . $self->{Root}->as_string
    if ! defined $self->{Socket};

  # Do the pserver authentication
  $self->{Socket}->print("BEGIN AUTH REQUEST\n");
  $self->{Socket}->print($self->{Root}->{RootDir} . "\n");
  $self->{Socket}->print($self->{Root}->{UserName} . "\n");
  $self->{Socket}->print($password . "\n");
  $self->{Socket}->print("END AUTH REQUEST\n");

  # Check that the authentication succeeded
  my $result = $self->{Socket}->getline();
  if ($result !~ /^I LOVE YOU$/) {
    my $message = "";
    while ($result !~ /I HATE YOU|^error/) {
      $message .= $result;
      $result = $self->{Socket}->getline();
    }
    $message .= $result;
    confess("Pserver authentication failed: $message");
  }

  # Use the socket for both reading and writing.
  $self->{SubFromServer} = $self->{Socket};
  $self->{SubToServer} = $self->{Socket};
  $self->connect_fin();
}

sub disconnect {
  my $self = shift;

  return if ! $self->connected();
  $self->SUPER::disconnect();
  $self->{Socket}->shutdown(2);
}

###############################################################################
# Private routines
###############################################################################

=head1 SEE ALSO

  VCS::LibCVS::Client
  VCS::LibCVS::Client::Connection

=cut

1;
