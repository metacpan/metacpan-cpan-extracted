#!/usr/bin/perl -w

package XML::SAX::ExpatNB;
use base qw/XML::SAX::Expat::Incremental/;

use strict;
#use warnings;

use vars qw/$VERSION/;
$VERSION = "0.01";

use IO::Handle ();
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

sub parse {
	my $p = shift;
	my $opts = $p->get_options(@_);
	
	if ($p->{Parent}){
		return $p->{Parent}->parse($opts);
	} else {
		if (defined $opts->{Source}{ByteStream}){
			if ($opts->{ReadOnce}){
				return $p->_parse_bytestream_once($opts->{Source}{ByteStream}, $opts->{ReadOnce});
			} else {
				return $p->_parse_bytestream($opts->{Source}{ByteStream});
			}
		} else {
			croak "Nonblocking reads only make sense if you're giving me file handles, y'know (well, actually sockets). Use parse_file";
		}
	}
}

sub parse_once {
	my $p = shift;
	my $fh = shift;
	my $bytes = shift || 4096;
	$p->parse_file($fh, @_, ReadOnce => $bytes);
}

sub _parse_bytestream {
	my $p = shift;
	my $fh = shift;
	$fh = IO::Handle->new_from_fd($fh, "<") unless blessed $fh;

	$fh->blocking(0);

	while($fh->sysread(my $buffer, 4096)){
		$p->_parse_string($buffer);
	}
}

sub _parse_bytestream_once {
	my $p = shift;
	my $fh = shift;
	$fh = IO::Handle->new_from_fd($fh, "<") unless blessed $fh;
	my $bytes = shift;

	$fh->blocking(0);	

	my $buffer;
	$fh->sysread($buffer, $bytes)
		and $p->_parse_string($buffer);
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::SAX::ExpatNB - A nonblocking filehandle oriented XML::SAX parser, and a
namespace consistency link, from XML::Parser::ExpatNB to
XML::SAX::Expat::Incremental.

=head1 SYNOPSIS

	use XML::SAX::ExpatNB;
	my $nb_parser = XML::SAX::ExpatNB->new; # use XML::SAX::ParserFactory

	$nb->parse_file($fh)
		if $data;

=head1 DESCRIPTION

L<XML::Parser::Expat> has a variation, called
L<XML::Parser::ExpatNB|XML::Parser::Expat/"XML::Parser::ExpatNB Methods"> which
is rather stupidly named, IMHO. It's a useful module, though, and in case you
got here from there looking for an L<XML::SAX> based wrapper for it, then one
exists, but is not named L<XML::SAX::ExpatNB>. It's called
L<XML::SAX::Expat::Incremental>.

This module implements nonblocking reads on a handle, and parses that data
using L<XML::SAX::Expat::Incremental>. It relies on L<IO::Handle/blocking>.

=head1 METHODS

=over 4

=item parse_file FH

Reads as much data as possible from FH, without blocking, and parse it.

Accepts the parameter C<ReadOnce>, whose value is the number of bytes to read,
as an option.

=item parse_once FH [ BYTES ]

Reads BYTES bytes from FH (defaults to 4096), and parse them, without blocking.

=back

=head1 SEE ALSO

L<XML::Parser>, L<XML::SAX>, L<XML::SAX::Expat>, L<XML::SAX::Expat::Incremental>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
