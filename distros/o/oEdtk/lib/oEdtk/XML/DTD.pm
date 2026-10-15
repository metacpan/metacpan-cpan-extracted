package oEdtk::XML::DTD;
use strict;
use warnings;
use Carp          qw( carp croak );
use oEdtk::Config qw(config_read);
use XML::LibXML;
use Data::Dumper qw( Dumper );
use English      qw( -no_match_vars );
use feature 'say';
use Try::Tiny qw(try catch);

use Readonly;

Readonly my $TYPE_FILE   => 'file';
Readonly my $TYPE_STRING => 'string';

sub found_in_list {
	my ( $elt, $l ) = @_;
	foreach my $v ( @{$l} ) {
		return 1 if $elt eq $v;
	}
	return;
}

sub load_xml_catalogs {
	my ($parser) = @_;
	my $cfg = config_read('MAIL');
	if (   ( exists $cfg->{'EDTK_XML_CATALOG_FILES'} )
		&& ( defined $cfg->{'EDTK_XML_CATALOG_FILES'} ) )
	{
		my $catalog_files = $cfg->{'EDTK_XML_CATALOG_FILES'};
		warn "Using XML_CATALOG_FILES=$catalog_files";
		$parser->load_catalog($_) foreach split m/:/, $catalog_files;
	}
	else {
		warn "No XML_CATALOG_FILES found";
	}
	return;
}

sub list_children_nodes {
	my ( $doc, @names ) = @_;
	my %names = map { $_ => 1 } @names;
	my @res   = ();
	foreach my $node ( $doc->childNodes() ) {
		my $type = $node->nodeType();
		if ( $type eq XML_TEXT_NODE ) {
			croak "Non-empty text in node: " . $node
				if $node->to_literal =~ m{\S}sx;
		}
		elsif ( $type eq XML_ELEMENT_NODE ) {
			my $name = $node->nodeName();
			croak "Unexpected node name '$name'. Authorized: " . join( ' ', @names )
				if ( scalar @names ) && !exists $names{$name};
			push @res, $node;
		}
		elsif ( $type eq XML_COMMENT_NODE ) { }                                        # ignore
		else                                { croak "Unexpected node type '$type'" }
	}
	return @res;
}

sub validate_xml {
	my ( $dom, $dtds, $msg, $flag_fatal ) = @_;

	# The DTD node comes back from internalSubset: this XML::LibXML build returns the
	# XML::LibXML::Dtd (publicId included) when the document declares a DOCTYPE and
	# undef otherwise, so a document without a DOCTYPE reports an empty public id
	# rather than dying. Probing externalSubset instead is wrong twice over: it always
	# returns undef here, and calling it corrupts the DTD node ownership, so a later
	# is_valid on the same DOM double-frees (see t/int/35_xml_dtd_xsd.t).
	my $dtd      = $dom->internalSubset;
	my $publicId = ( $dtd ? $dtd->publicId : undef ) // q{};
	if ( !found_in_list( $publicId, $dtds ) ) {
		my $str = "Unexpected DTD public id '$publicId':" . Dumper($dtds);
		return $flag_fatal ? ( croak $str ) : ( carp $str );
	}
	if ( !$dom->is_valid ) {
		my $str = "$msg does not validate against its DTD: " . XML::LibXML->get_last_error();
		return $flag_fatal ? ( croak "ERROR: $str" ) : ( carp "WARNING: $str" );
	}
	say STDERR "$msg validates against its DTD";
	return ( $dom, $publicId );
}

sub parse_xml {
	my ( $input, $type, $dtds, $msg, $flag_fatal ) = @_;
	$flag_fatal //= 1;
	my $sub    = ( $type eq $TYPE_FILE ) ? 'parse_file' : 'parse_string';
	my $parser = XML::LibXML->new( validation => 1 );
	load_xml_catalogs($parser);
	my $dom;
	if ($flag_fatal) {
		$dom = $parser->$sub($input);
	}
	else {
		eval { $dom = $parser->$sub($input); };
		return carp $EVAL_ERROR if $EVAL_ERROR;
	}
	return validate_xml( $dom, $dtds, $msg, $flag_fatal );
}

sub parse_and_validate_xml_file {
	my ( $file, $dtds, $flag_fatal ) = @_;
	return parse_xml( $file, $TYPE_FILE, $dtds, "File '$file'", $flag_fatal );
}

sub parse_and_validate_xml_string {
	my ( $str, $dtds, $flag_fatal ) = @_;
	my $s =
		( length $str < 20 )
		? $str
		: substr( $str, 0, 8 ) . '...' . substr( $str, -8 );
	return parse_xml( $str, $TYPE_STRING, $dtds, "String '$s'", $flag_fatal );
}

# XSLT with output method="text" should not include the <?xml decl; see
# https://github.com/sparklemotion/nokogiri/issues/1750 and the lab/seb notes.
sub xml_to_txt {
	my ($str) = @_;
	if ( $str =~ s{^(<\?xml\b[^<>]*\?>\n?)}{}sx ) {
		my $n = $str =~ s{\&\#x(\w+);}{chr(hex($1))}gsex;
		croak "Remaining numerical entities: $1" if $str =~ m{(\&\#\w+;)}sx;
		croak "Remaining entities: $1"           if $str =~ m{(\&\w+;)}sx;
	}
	return $str;
}

# Kept for the fork's callers: the XSD variant is the single source in
# oEdtk::XML::XSD.
sub parse_and_validate_xml_file_xsd {
	my ( $file, $cfg ) = @_;
	require oEdtk::XML::XSD;
	return oEdtk::XML::XSD::parse_and_validate_xml_file_xsd( $file, $cfg );
}

# Returns the first valid id for the document (in the shared DTD);
# as a business rule one of these should exist.
sub first_id {
	my ($root) = @_;
	return
		   xpath( $root, 'id/@numaba', 0 )
		|| xpath( $root, 'id/@external', 0 )
		|| xpath( $root, 'id/@phoenix',  0 )
		|| croak "No id found in " . $root->toString;
}

# Returns the value of an xpath attribute; fatal if not found and was required.
sub xpath {
	my ( $node, $path, $required ) = @_;
	$required //= 1;
	return
		  $node->exists($path) ? $node->findvalue($path)
		: $required ? croak join "\n", "XPath '$path' does not exist for node:",
		$node->toString, q{}
		: q{};
}

1;

=head1 NAME

oEdtk::XML::DTD - parse and validate XML documents against their DTD

=head1 SYNOPSIS

    use oEdtk::XML::DTD;

    my ($dom, $public_id) =
        oEdtk::XML::DTD::parse_and_validate_xml_file($file, \@accepted_ids);

=head1 DESCRIPTION

Parse an XML document and check its DTD public identifier against a list of
accepted ones before checking that the document validates. The module was formed
at S21 of the fork-merge plan by merging the 0.8032 fork's F<oEdtk::XML::DTD> and
F<oEdtk::XML::DTD::Utils> (about 90% identical); the XSD variant it used to carry
now lives in L<oEdtk::XML::XSD>, and L<oEdtk::XML::DTD::Utils> remains loadable as a
delegate.

=head1 FUNCTIONS

=head2 parse_and_validate_xml_file

    parse_and_validate_xml_file($file, \@accepted_public_ids, $flag_fatal);

Parse C<$file> and validate it. When C<$flag_fatal> is false the failures are
reported and the function returns instead of dying. Returns C<($dom, $public_id)>.

=head2 parse_and_validate_xml_string

    parse_and_validate_xml_string($xml, \@accepted_public_ids, $flag_fatal);

The same, from a string.

=head2 parse_xml

    parse_xml($input, $type, \@accepted_public_ids, $msg, $flag_fatal);

The shared step behind the two wrappers above; C<$type> is C<'file'> or
C<'string'>.

=head2 validate_xml

    my ($dom, $public_id) = validate_xml($dom, \@accepted_public_ids, $msg, $flag_fatal);

Check the public identifier of an already parsed document and that it validates.
The public identifier is read through C<internalSubset>, which returns the DTD
node when the document declares a DOCTYPE and undef otherwise, so a document
without a DOCTYPE reports an empty public id rather than crashing.

=head2 parse_and_validate_xml_file_xsd

    parse_and_validate_xml_file_xsd($file, $xsd_schema);

Forward to L<oEdtk::XML::XSD>, kept so the fork's callers keep working.

=head2 load_xml_catalogs

    load_xml_catalogs($parser);

Load the XML catalogs named by the C<EDTK_XML_CATALOG_FILES> configuration key.

=head2 list_children_nodes

    my @nodes = list_children_nodes($node, @authorized_names);

Return the element children of C<$node>, refusing unexpected names, non-empty
text and unexpected node types.

=head2 xml_to_txt

    my $text = xml_to_txt($string);

Drop a leading C<< <?xml ... ?> >> declaration and decode the hexadecimal
numeric entities that follow it; croak on any entity left undecoded.

=head2 first_id / xpath

    my $id = first_id($root);
    my $v  = xpath($node, $path, $required);

C<first_id> returns the first of the C<id/@numaba>, C<id/@external> and
C<id/@phoenix> attributes. C<xpath> returns an attribute value and croaks when it
is missing and C<$required> is true.

=head2 found_in_list

    my $ok = found_in_list($value, \@list);

True when C<$value> equals one element of C<\@list>.

=head1 AUTHOR

The oEdtk team.

=cut
