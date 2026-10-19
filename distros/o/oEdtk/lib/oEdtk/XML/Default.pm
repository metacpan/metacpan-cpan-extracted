package oEdtk::XML::Default;

use strict;
use warnings;

use Encode qw(encode);
use Fcntl  qw(:seek);
use XML::LibXML;

# This is so we can refer to Unicode characters by their name.
use charnames ':full';

use Exporter;
our $VERSION   = 2.1126;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(cameleon_open cameleon_extract);

# Wrapper for Encode::encode that warns about characters that cannot be
# converted, but doesn't insert any replacement text.
sub my_encode {
	my ( $enc, $data ) = @_;
	my $check = sub {
		warn sprintf( "<U+%04X> does not map to $enc", shift );
		return '';
	};
	encode( $enc, $data, $check );
}

# Extract the key/value pairs from the Cameleon XML file and
# return them in a hash.
sub cameleon_open {
	my ( $fh, $path ) = @_;

	binmode($fh);    # Make sure to drop any PerlIO layer.
	my $xml = XML::LibXML->load_xml( IO => $fh );
	my $xpc = XML::LibXML::XPathContext->new($xml);

	return $xpc;
}

sub cameleon_extract {
	my ( $xpc, $path ) = @_;
	my $cond = "[\@cpe=\"$path\"]";
	my @nodes =
		$xpc->findnodes( '//conf:GenerativeProcess//'
			. 'conf:ItemSalesBreakdownLine'
			. $cond
			. '/conf:Sig//conf:BusinessProperties' );

	my $data = {};
	foreach my $line (@nodes) {
		my ($knode) = $xpc->findnodes(
			'./conf:SingleBusinessProperty[@name="bpTypeDonnee"]/conf:Value/conf:textValue',
			$line );
		my ($vnode) = $xpc->findnodes(
			'./conf:SingleBusinessProperty[@name="bpValeur"]/conf:Value/conf:longTextValue',
			$line );
		if (   !defined($vnode)
			|| !defined($knode)
			|| $vnode->nodeType != XML_ELEMENT_NODE
			|| $knode->nodeType != XML_ELEMENT_NODE )
		{
			return;
		}
		my $key = $knode->textContent();
		my $val = $vnode->textContent();

		# We substitute the unicode character "RIGHT SINGLE
		# QUOTATION MARK" by the common apostrophe character,
		# because there is no other corresponding character
		# when encoding in ISO-8859-15.
		# http://ascii-table.com/unicode-index-e.php
		$val =~ s/\N{RIGHT SINGLE QUOTATION MARK}/'/g;
		$val =~ s/\N{HORIZONTAL ELLIPSIS}/.../g;

		$data->{$key} = my_encode( 'iso-8859-15', $val );    # alias = latin9
	}
	return $data;
}

1;

=head1 NAME

oEdtk::XML::Default - the default Cameleon XML reader

=head1 SYNOPSIS

    use oEdtk::XML::Default qw(cameleon_open cameleon_extract);

    my $xpc  = cameleon_open($fh);
    my $data = cameleon_extract($xpc, '/some/cpe/path');

=head1 DESCRIPTION

Read the key/value pairs a Cameleon generative process writes into its XML
output. Moved from C<oEUser::XML::Default> into the mainline at S21 of the
fork-merge plan (decision D23); the old name stays available as a delegate.

=head1 FUNCTIONS

=head2 cameleon_open

    my $xpc = cameleon_open($fh, $path);

Load the Cameleon XML from the open filehandle C<$fh> and return an
L<XML::LibXML::XPathContext> over it.

=head2 cameleon_extract

    my $data = cameleon_extract($xpc, $path);

Return the C<bpTypeDonnee> / C<bpValeur> pairs of the C<ItemSalesBreakdownLine>
whose C<cpe> attribute is C<$path>, or C<undef> when a pair is incomplete. Values
are encoded to ISO-8859-15, with the typographic apostrophe and ellipsis folded to
their ASCII equivalents.

The internal helper C<my_encode>, which encodes a value to ISO-8859-15 while
warning about any character it cannot map, is not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
