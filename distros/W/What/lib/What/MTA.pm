#$ Id: $;
package What::MTA;
use strict;
use vars qw($VERSION @ISA);
use Socket 1.3;
use Carp;
use IO::Socket;
use Net::Cmd;
 
$VERSION = "1.00";

@ISA = qw(Net::Cmd IO::Socket::INET);

=head1 NAME

What::MTA - Find out about running MTA

=head1 SYNOPSIS

  $what = What->new( 
             Host => my.domain.org, 
             Port => 25, 
          );  

  $what->mta;
  $what->mta_version;
  $what->mta_banner;
  
=head1 DESCRIPTION

What::MTA is a part of C<What> package. It provides basic information
about running MTA: name, version and banner that MTA prints out upon
connection to it. It is not meant to be used directly, but via its
interface, class C<What>. MTA's supported are: Exim, Postfix (version
only on localhost), Sendmail, Courier (name only), XMail, MaswMail.

The What::MTA class is a subclass of Net::Cmd and IO::Socket::INET.

=head1 CONSTRUCTOR

=over

=item new ( OPTIONS )

This is the constructor for a new What object. 

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

=back

=over 4

B<Host> - is the name, or address, of the remote host to which a
connection to a running service is required to. It may be a single
scalar, as defined for the C<PeerAddr> option in L<IO::Socket::INET>.
C<Host> is optional, default value is C<localhost>.

B<LocalAddr> and B<LocalPort> - These parameters are passed directly
to IO::Socket to allow binding the socket to a local port.

B<Timeout> - Maximum time, in seconds, to wait for a response from the
server (default: 120)

B<Port> - Port to which to connect to (default: 25)

B<Debug> - Enable debugging information

=back

Example:

    $what = What->new( 
                       Host    => 'my.mail.domain'
		       Timeout => 30,
                       Debug   => 1,
		     );

    $what = What->new(
		       Host => '10.10.10.1',
                       Port => 25,
		     );

=cut

sub new {
    my $self = shift;
    my $type = ref($self) || $self;
    my %arg = @_;

    my $PeerAddr = $arg{Host} || 'localhost';
    my $PeerPort = $arg{Port} || 'smtp(25)';
    my $Timeout = defined $arg{Timeout} ? $arg{Timeout} : 120;
    my $LocalAddr = $arg{LocalAddr} || undef;
    my $LocalPort = $arg{LocalPort} || undef;

    my $obj = $type->SUPER::new(PeerAddr => $PeerAddr, 
				PeerPort => $PeerPort,
				LocalAddr => $LocalAddr,
				LocalPort => $LocalPort,
				Proto    => 'tcp',
				Timeout  => $Timeout,
				);
    
    if (not defined($obj)) {
       my $msg = "Couldn't create What::MTA object with\n" . 
	   "PeerAddr=$PeerAddr,\nPeerPort=$PeerPort,\n" . 
	   "Proto=tcp,\nTimeout=$Timeout";
       $msg .= "LocalAddr=$LocalAddr,\n" if defined $LocalAddr;
       $msg .= "LocalPort=$LocalPort,\n" if defined $LocalPort;
       croak $msg;
    }
    
    $obj->autoflush(1);
    $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

    unless ($obj->response() == CMD_OK) {
	$obj->close();
	return undef;
    }

    (${*$obj}{'mta_banner'})  = $arg{Banner} || $obj->message;
    (${*$obj}{'mta_banner'})  =~ s/\n$//;

    $obj->_extract_name_version();
        
    $obj;
}

sub _EHLO { shift->command("EHLO", @_)->response()  == CMD_OK }   
sub _HELO { shift->command("HELO", @_)->response()  == CMD_OK }   
sub _HELP { shift->command("HELP", @_)->response()  == CMD_OK }   

=head1 METHODS

=over

=item mta()

Returns the name of the MTA running.

=back

=cut

sub mta {
    my $self = shift;
    return ${*$self}{'mta_name'};
};

=over

=item mta_version()

Returns the version of the MTA running.

=back

=cut

sub mta_version {
    my $self = shift;
    return ${*$self}{'mta_version'};
};

=over

=item mta_banner()

Returns the banner message which the server replied with when the
initial connection was made.

=back

=head1 EXAMPLES OF MTA BANNERS

=over 4

=item Exim

  localhost ESMTP Exim 4.60 Mon, 20 Feb 2006 22:38:53 +0000

=item Postfix

  localhost ESMTP Postfix (Debian/GNU)

=item Sendmail

  galeb.somedomain.org ESMTP Sendmail 8.13.5/8.13.5/Debian-3; Mon, 20
  Feb 2006 22:41:04 GMT; (No UCE/UBE) logging access from:
  localhost(OK)-localhost [127.0.0.1]

=item XMail

  <1140475332.2874633136@mast> [XMail 1.22 ESMTP Server] service ready;
  Mon, 20 Feb 2006 22:42:12 -0000

=item MasqMail

  mast MasqMail 0.2.21 ESMTP

=back

=cut

sub mta_banner {
    my $self = shift;
    return ${*$self}{'mta_banner'};
};

=head1 DIAGNOSTICS

=over

=item Can not connect to the serice host/port specified

  Couldn't create What::MTA object with
  PeerAddr=localhost,
  PeerPort=26,
  Proto=tcp,
  Timeout=120 at lib/What.pm line 68

=back

=head1 DEPENDENCIES

Class::Std depends on the following modules:

=over

=item *

L<Net::Cmd>

=item *

L<IO::Socket::INET>

=item *

L<Socket>

=back



=cut

sub _extract_name_version {
    my $self = shift;

    if ( (${*$self}{'mta_banner'}) =~ m/Exim/ ) { 
        ### Exim ###

	(${*$self}{'mta_version'}) =
	    (${*$self}{'mta_banner'}) =~ m/^.+ESMTP Exim (\d+\.\d+) .+/;

	(${*$self}{'mta_name'}) = "Exim";

    } elsif ( (${*$self}{'mta_banner'}) =~ m/Postfix/ ) {
	### Postfix ###

	my $v;
	eval { 
	    $v = `postconf mail_version`;
	};
	if (defined($@)) {
	    (${*$self}{'mta_version'}) = "unknown"; 
	} else {
	    (${*$self}{'mta_version'}) = $v =~ m/.+ = (.+)/;
	}
	(${*$self}{'mta_name'}) = "Postfix";

    } elsif ( (${*$self}{'mta_banner'}) =~ m/Sendmail/ ) {
	### Sendmail ###

	(${*$self}{'mta_version'}) =
	    (${*$self}{'mta_banner'}) =~ m/^.+Sendmail (\d+\.\d+?.\d+)\/.+/;

	(${*$self}{'mta_name'}) =  "Sendmail";
	
    } elsif ( (${*$self}{'mta_banner'}) =~ m/XMail/ ) {
	### XMail ###

	(${*$self}{'mta_version'}) =
	    (${*$self}{'mta_banner'}) =~ m/^.+XMail (.+) ESMTP.+/;

	(${*$self}{'mta_name'}) =  "XMail";

    } elsif ( (${*$self}{'mta_banner'}) =~ m/MasqMail/ ) {
	### MasqMail ###

	(${*$self}{'mta_version'}) =
	    (${*$self}{'mta_banner'}) =~ m/^.+MasqMail (.+) ESMTP?.+/;

	(${*$self}{'mta_name'}) =  "MasqMail";

    } elsif ( (${*$self}{'mta_banner'}) =~ m/\w ESMTP$/ ) {
	### Courier? ###

	(${*$self}{'mta_version'}) = "see syslog";
	(${*$self}{'mta_name'}) =  "Courier";

    } else {
	### unkown ###

	(${*$self}{'mta_version'}) = "unknown";
	(${*$self}{'mta_name'}) =  "unknown";

    };
};


1;

=head1 BUGS

Please report any bugs or feature requests to
C<bug-what@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Lot of code taken from Net::Cmd, without which this class probably
wouldn't have been written.

=head1 AUTHOR

Toni Prug <toni@irational.org>

=head1 COPYRIGHT

Copyright (c) 2006. Toni Prug. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

See L<http://www.gnu.org/licenses/gpl.html>

=cut
