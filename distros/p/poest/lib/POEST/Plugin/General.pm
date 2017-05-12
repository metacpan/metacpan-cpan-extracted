# $Id: General.pm,v 1.3 2003/04/08 00:27:30 cwest Exp $
package POEST::Plugin::General;

=pod

=head1 NAME

POEST::Plugin::General - General SMTP commands implemented.

=head1 ABSTRACT

This class implements general SMTP commands, in order to get them
out of the way.

=head1 DESCRIPTION

There are some SMTP commands that are fairly straight forward
to implement, they are implemented here.

=cut

use strict;
$^W = 1;

use vars qw[$VERSION @ISA];
$VERSION = (qw$Revision: 1.3 $)[1];

use POEST::Plugin;
@ISA = qw[POEST::Plugin];

=head2 Events

=head3 HELO

Returns the response for C<HELO>.

=head3 ELOH

Returns a simple "Ok" response to C<ELOH>.

=head3 NOOP

Returns the response for C<NOOP>.

=head3 QUIT

Returns the response for C<QUIT>.

=head3 send_banner

Sends the banner for the SMTP server when a session initializes.  This
is how an SMTP server introduces itself to the client.

=cut

sub EVENTS () { [ qw[ HELO  ELOH NOOP QUIT send_banner ] ] }

=head2 Configuration

=head3 hostname

The hostname that we run as a primary.  This is used when sending the
banner.

=cut

sub CONFIG () { [ qw[ hostname ] ] }

sub send_banner {
	my ($kernel, $self, $heap) = @_[KERNEL, OBJECT, HEAP];
	my $client = $heap->{client};

	my $banner = "$self->{hostname} ESMTP poest/v0.1";

	$client->put( SMTP_SERVICE_READY, $banner );
}

sub HELO {
	my ($kernel, $self, $heap) = @_[KERNEL, OBJECT, HEAP];
	my $client = $heap->{client};

	$client->put( SMTP_OK, qq[$self->{hostname} Ok] );
}

sub ELOH {
	my ($kernel, $self, $heap) = @_[KERNEL, OBJECT, HEAP];
	my $client = $heap->{client};
	
	$client->put( SMTP_OK, qq[$self->{hostname} Ok] );
}

sub NOOP {
	my $client = $_[HEAP]->{client};

	$client->put( SMTP_OK, q[Ok] );
}

sub QUIT {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	my $client = $heap->{client};

	$client->put( SMTP_QUIT, q[Bye!] );
	$heap->{shutdown_now} = 1;
}

1;

__END__

=pod

=head1 AUTHOR

Casey West, <F<casey@dyndns.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 DynDNS.org

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

THIS PACKAGE IS PROVIDED WITH USEFULNESS IN MIND, BUT WITHOUT GUARANTEE
OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. USE IT AT YOUR
OWN RISK.

For more information, please visit http://opensource.dyndns.org

=head1 SEE ALSO

L<perl>, L<POEST::Server>, L<POEST::Plugin>.

=cut
