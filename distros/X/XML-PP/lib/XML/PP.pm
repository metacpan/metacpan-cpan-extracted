package XML::PP;

use strict;
use warnings;

use Carp qw(carp croak);
use Params::Get 0.13;
use Scalar::Util;
use Return::Set;

=head1 NAME

XML::PP - A simple XML parser

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

  use XML::PP;

  my $parser = XML::PP->new();
  my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from><heading>Reminder</heading><body importance="high">Don\'t forget me this weekend!</body></note>';
  my $tree = $parser->parse($xml);

  print $tree->{name};	# 'note'
  print $tree->{children}[0]->{name};	# 'to'

=head1 DESCRIPTION

You almost certainly do not need this module.
For most tasks,
use L<XML::Simple> or L<XML::LibXML>.
C<XML::PP> exists only for the most lightweight scenarios where you can't get one of the above modules to install,
for example,
CI/CD machines running Windows that get stuck with L<https://stackoverflow.com/questions/11468141/cant-load-c-strawberry-perl-site-lib-auto-xml-libxml-libxml-dll-for-module-x>.

C<XML::PP> is a simple, lightweight XML parser written in pure Perl.
It does not rely on external libraries like C<XML::LibXML> and is suitable for small XML parsing tasks.
This module supports basic XML document parsing, including namespace handling, attributes, and text nodes.

=head1 METHODS

=head2 new

  my $parser = XML::PP->new();
  my $parser = XML::PP->new(strict => 1);
  my $parser = XML::PP->new(warn_on_error => 1);

Creates a new C<XML::PP> object.
It can take several optional arguments:

=over 4

=item * C<strict> - If set to true, the parser dies when it encounters unknown entities or unescaped ampersands.

=item * C<warn_on_error> - If true, the parser emits warnings for unknown or malformed XML entities. This is enabled automatically if C<strict> is enabled.

=item * C<logger>

Used for warnings and traces.
It can be an object that understands warn() and trace() messages,
such as a L<Log::Log4perl> or L<Log::Any> object,
a reference to code,
a reference to an array,
or a filename.

=back

=cut

# Constructor for creating a new XML::PP object
sub new
{
	my $class = shift;
	my $params = Params::Get::get_params(undef, @_) || {};

	# strict implies warn_on_error
	if($params->{strict}) {
		$params->{warn_on_error} = 1;
	}

	my $self = bless { %{$params} }, $class;

	if(my $logger = $self->{'logger'}) {
		if(!Scalar::Util::blessed($logger)) {
			# Don't "use" at the top, because of circular dependancy:
			#	Log::Abstraction->Config::Abstraction->XML::PP
			eval { require Log::Abstraction };
			if($@) {
				croak $@;
			}
			Log::Abstraction->import();
			$self->{'logger'} = Log::Abstraction->new($logger);
		}
	}

	return $self;
}

=head2 parse

  my $tree = $parser->parse($xml_string);

Parses the XML string and returns a tree structure representing the XML content.
The returned structure is a hash reference with the following fields:

=over 4

=item * C<name> - The tag name of the node.

=item * C<ns> - The namespace prefix (if any).

=item * C<ns_uri> - The namespace URI (if any).

=item * C<attributes> - A hash reference of attributes.

=item * C<children> - An array reference of child nodes (either text nodes or further elements).

=back

=cut

# Parse the given XML string and return the root node
sub parse
{
	my $self = shift;
	my $params = Params::Get::get_params('xml', \@_);
	my $xml_string = $params->{'xml'};

	if(ref($xml_string) eq 'SCALAR') {
		$xml_string = ${$xml_string};
	}
	# Check if the XML string is empty
	# if (!$xml_string || $xml_string !~ /<\?xml/) {
		# $self->_handle_error("Invalid or empty XML document provided");
	if (!$xml_string) {
		# $self->_handle_error("Empty XML document provided");
		return {};
	}

	$xml_string =~ s/<!--.*?-->//sg;	# Ignore comments
	# .*? is lazy; avoids over-consuming if multiple ?> sequences exist on the line
	$xml_string =~ s/<\?xml.*?\?>//;	# Ignore the XML declaration header

	$xml_string =~ s/<!--.*?-->//sg;	# Strip comments
	$xml_string =~ s/<\?xml.*?\?>//;	# Strip XML declaration
	$xml_string =~ s/^\s+|\s+$//g;		# Trim surrounding whitespace

	# Re-check after preprocessing: comments/declaration/whitespace may have consumed everything
	return {} unless length($xml_string);

	return $self->_parse_node(\$xml_string, {});
}

=head2 collapse_structure

Collapses a parsed XML tree into a simplified nested hash,
similar in spirit to L<XML::Simple>.
It is designed to be called on the output of C<parse()>,
and the two methods compose cleanly as a pipeline.

=head3 Purpose

Transforms the verbose node-and-children structure produced by C<parse()>
into a compact hash that is easier to address with ordinary Perl hash
syntax.
Each element's tag name becomes a hash key and its text content becomes
the corresponding value.
Nested elements are recursed into rather than flattened.

=head3 Arguments

=over 4

=item * C<$node> (required)

A hash reference representing a parsed XML node,
as returned by C<parse()>.
Must contain a defined C<name> key and a C<children> array reference.
Returns an empty hash reference immediately if any of the following are
true: C<$node> is not a hash reference; C<$node> has no defined C<name>
key; C<$node> has no C<children> key.

=back

=head3 Returns

A hash reference whose single top-level key is the element's tag name.
Its value is a hash of collapsed children where each child's tag name maps
to its text content or to a recursively collapsed sub-hash.

If two or more children share the same tag name their values are collected
into an array reference in document order rather than overwriting each other.

Children whose text content is undefined or the empty string are silently
omitted.
Children with no tag name (bare text nodes) are silently skipped.
Attributes of child elements are not included in the collapsed output; use
the raw tree from C<parse()> if attribute values are needed.

=head3 Example

  use XML::PP;

  my $parser = XML::PP->new();
  my $xml    = '<note id="1">'
             .   '<to>Tove</to>'
             .   '<from>Jani</from>'
             .   '<heading>Reminder</heading>'
             .   '<body>Don\'t forget me this weekend!</body>'
             . '</note>';

  my $tree   = $parser->parse($xml);
  my $result = $parser->collapse_structure($tree);

  # $result = {
  #     note => {
  #         to      => 'Tove',
  #         from    => 'Jani',
  #         heading => 'Reminder',
  #         body    => "Don't forget me this weekend!",
  #     }
  # }

  print $result->{note}{to};       # Tove
  print $result->{note}{heading};  # Reminder

  # Repeated child elements become an array reference:
  my $list   = $parser->parse('<list><item>a</item><item>b</item></list>');
  my $flat   = $parser->collapse_structure($list);
  print $flat->{list}{item}[0];    # a
  print $flat->{list}{item}[1];    # b

=head3 API specification

=head4 Input

  {
      node => {
          type      => HASHREF,
          required  => 1,
          callbacks => {
              'has defined name key' => sub {
                  ref $_[0] eq 'HASH' && defined $_[0]->{name}
              },
              'has children key' => sub {
                  ref $_[0] eq 'HASH' && exists $_[0]->{children}
              },
          },
      },
  }

=head4 Output

  {
      type => HASHREF,
      min  => 1,
  }

The returned hash reference always has exactly one top-level key (the root
element's tag name) whose value is a plain hash reference of collapsed
children.
An empty hash reference C<{}> is returned when the input fails the guard
conditions.

=cut

sub collapse_structure {
	my ($self, $node) = @_;

	# Guard against missing name, missing children, or a non-hash-ref input;
	# children must be a reference (empty arrayref is still valid)
	return {} unless ref $node eq 'HASH'
		&& defined $node->{name}
		&& $node->{children};

	my %result;
	for my $child (@{ $node->{children} }) {
		# Skip any node that has no name (e.g. bare text nodes)
		my $name = $child->{name} or next;
		my $value;

		if($child->{children} && @{ $child->{children} }) {
			if(@{ $child->{children} } == 1 && exists $child->{children}[0]{text}) {
				# Single text child: map name => text directly
				$value = $child->{children}[0]{text};
			} else {
				# Multiple or non-text children: recurse and unwrap the result
				$value = $self->collapse_structure($child)->{$name};
			}
		}

		# Skip children whose text is undefined or the empty string;
		# note: "0" is a valid value and must not be skipped
		next unless defined $value && $value ne '';

		# Promote duplicate same-name siblings to an arrayref in document order
		if(exists $result{$name}) {
			$result{$name} = [ $result{$name} ] unless ref $result{$name} eq 'ARRAY';
			push @{ $result{$name} }, $value;
		} else {
			$result{$name} = $value;
		}
	}

	# Wrap the collapsed hash under the root element name
	return { $node->{name} => \%result };
}

# _parse_node($xml_ref, $nsmap)
#
# Purpose:
#   Recursively parses a single XML node from the front of the string
#   referenced by $xml_ref, building and returning a tree of hash nodes.
#
# Entry criteria:
#   $xml_ref  - scalar ref to the remaining unparsed XML string; consumed
#               in-place as tags and text are matched and stripped
#   $nsmap    - hash ref of namespace prefix => URI mappings inherited from
#               the parent node; must not be undef (pass {} at the root)
#
# Exit status:
#   Returns a hash ref representing the parsed node:
#     {
#       name       => $tag,        # local tag name (namespace prefix stripped)
#       ns         => $prefix,     # namespace prefix, or undef if none
#       ns_uri     => $uri,        # resolved namespace URI, or undef if none
#       attributes => \%attrs,     # decoded attribute key/value pairs
#       children   => \@children,  # text nodes ({ text => $str }) and child
#                                  # element nodes (recursive _parse_node results)
#     }
#   Returns undef if the opening tag regex fails to match.
#
# Side effects:
#   Modifies $$xml_ref in-place, consuming the matched node and its closing tag.
#
# Notes:
#   Namespace declarations (xmlns:prefix="uri") are extracted from the attribute
#   string and merged into a local copy of $nsmap for child nodes; they are not
#   included in the returned attributes hash.
#   Closing-tag namespace prefix is accepted without verifying it matches the
#   opening prefix — intentional given the lightweight scope of this module.
sub _parse_node {
	my ($self, $xml_ref, $nsmap) = @_;

	# Programmer error: xml_ref must always be a defined scalar ref
	if(!defined($xml_ref)) {
		if($self->{'logger'}) {
			$self->{'logger'}->fatal('BUG: _parse_node, xml_ref not defined');
		}
		die 'BUG: _parse_node, xml_ref not defined';
	}

	# Match the start of a tag; capture tag name, attribute string, and
	# any trailing slash that would indicate a self-closing tag
	$$xml_ref =~ s{^\s*<([^\s/>]+)([^>]*)\s*(/?)>}{}s or do {
		$self->_handle_error('Expected a valid XML tag, but none found at position: '
			. (pos($$xml_ref) // 0));
		return;
	};

	my ($raw_tag, $attr_string, $self_close) = ($1, $2 || '', $3);

	# The main regex's [^>]* greedily consumes any trailing '/', so $self_close
	# from capture group 3 is always empty; detect self-closing tags via attr_string
	if($attr_string =~ s{/\s*$}{}) {
		$self_close = 1;
	}

	# A self-closing tag is malformed if a redundant closing tag immediately follows;
	# e.g. <br/></br> is invalid XML
	if($self_close && $$xml_ref =~ /^\s*<\/(?:\w+:)?$raw_tag\s*>/) {
		$self->_handle_error(
			"Malformed self-closing tag: redundant closing tag found for <$raw_tag/>");
		return;
	}

	# Split the raw tag into optional namespace prefix and local name
	my ($ns, $tag) = $raw_tag =~ /^([^:]+):(.+)$/
		? ($1, $2)
		: (undef, $raw_tag);

	# Build a local namespace map inheriting from the parent scope
	my %local_nsmap = (%$nsmap);

	# Extract xmlns declarations and add them to the local namespace map
	while($attr_string =~ /(\w+)(?::(\w+))?="([^"]*)"/g) {
		my ($k1, $k2, $v) = ($1, $2, $3);
		if($k1 eq 'xmlns' && !defined $k2) {
			$local_nsmap{''} = $v;
		} elsif($k1 eq 'xmlns' && defined $k2) {
			$local_nsmap{$k2} = $v;
		}
	}

	# Normalise whitespace between attributes without touching quoted values;
	# collapse runs of whitespace outside quotes to a single space
	{
		my $tmp   = $attr_string;
		my @parts = $tmp =~ /"[^"]*"|'[^']*'|[^\s"'']+/g;
		$attr_string = join(' ', @parts);
	}

	my %attributes;

	# Parse name="value" and name='value' attribute pairs; /s lets .*? cross newlines
	# inside quoted values; skip xmlns declarations already handled above
	while($attr_string =~ /([A-Za-z_:][-A-Za-z0-9_.:]*)\s*=\s*(['"])(.*?)\2/gs) {
		my ($attr, undef, $v) = ($1, $2, $3);
		next if $attr =~ /^xmlns(?::|$)/;
		$attributes{$attr} = $self->_decode_entities($v);
	}

	my $node = {
		name       => $tag,
		ns         => $ns,
		ns_uri     => defined $ns ? $local_nsmap{$ns} : undef,
		attributes => \%attributes,
		children   => [],
	};

	# Self-closing tags have no content or children
	return $node if $self_close;

	# Parse text nodes and child elements interleaved to handle mixed content;
	# a single pre-loop text capture would miss text between sibling elements
	while(1) {
		# Consume any text preceding the next tag (covers mixed content between siblings)
		if($$xml_ref =~ s{^([^<]+)}{}s) {
			my $text = $self->_decode_entities($1);
			$text =~ s/^\s+|\s+$//g;
			# Whitespace-only text nodes are discarded
			push @{ $node->{children} }, { text => $text } if $text ne '';
		}

		# Stop when the next token is a closing tag, a self-closer, or end of input
		last unless $$xml_ref =~ /^\s*<([^\/>"][^>]*)>/;

		# Recurse to parse the next child element
		my $child = $self->_parse_node($xml_ref, \%local_nsmap);

		# $child should never be undef here since the while lookahead and the
		# inner s/// use equivalent patterns; the guard is retained defensively
		push @{ $node->{children} }, $child if $child;
	}

	# Consume the closing tag; flag it if absent or mismatched
	unless($$xml_ref =~ s{^\s*</(?:\w+:)?$tag\s*>}{}s) {
		# Closing-tag prefix is not verified against the opening prefix — intentional
		# given the lightweight scope of this module
		$self->_handle_error("Missing or mismatched closing tag for <$tag>");
	}

	return Return::Set::set_return($node, { 'type' => 'hashref', 'min' => 1 });
}

# _decode_entities($text)
#
# Purpose:
#   Decodes XML character and entity references in a string, converting them
#   to their literal UTF-8 character equivalents.
#
# Entry criteria:
#   $text - the string to decode; may be undef, in which case undef is returned
#
# Exit status:
#   Returns the decoded string with all recognised entities replaced.
#   Returns undef if $text is undef.
#
# Side effects:
#   Calls _handle_error() if an unknown named entity or an unescaped ampersand
#   is encountered; depending on the strict/warn_on_error settings this may
#   die, warn, or log silently.
#
# Notes:
#   Handles the five predefined XML named entities: &lt; &gt; &amp; &quot; &apos;
#   Handles decimal numeric references (&#nnnn;) and hex numeric references
#   (&#xhhhh;).  All other named entities are treated as unknown and trigger
#   _handle_error().  Unescaped ampersands that survive entity decoding are
#   also flagged via _handle_error().
sub _decode_entities {
	my ($self, $text) = @_;

	return undef unless defined $text;

	# Check for unescaped bare ampersands before any decoding, so that
	# legitimately encoded &amp; sequences do not trigger a false positive
	if ($text =~ /&(?![a-zA-Z#][^;]*;)/) {
		$self->_handle_error("Unescaped ampersand detected: $text");
	}

	# Decode the five predefined named entities
	$text =~ s/&lt;/</g;
	$text =~ s/&gt;/>/g;
	$text =~ s/&amp;/&/g;
	$text =~ s/&quot;/"/g;
	$text =~ s/&apos;/'/g;

	# Decode decimal and hex numeric character references
	$text =~ s/&#(\d+);/chr($1)/eg;
	$text =~ s/&#x([0-9a-fA-F]+);/chr(hex($1))/eg;

	# Flag any remaining unrecognised named entities
	if ($text =~ /&([^;]*);/) {
		my $entity = $1;
		unless ($entity =~ /^(lt|gt|amp|quot|apos)$/ || $entity =~ /^#(?:x[0-9a-fA-F]+|\d+)$/) {
			$self->_handle_error("Unknown or malformed XML entity: &$entity;");
		}
	}

	return $text;
}

# _handle_error($message)
#
# Purpose:
#   Centralised error handler for XML parsing failures; routes the error to
#   the appropriate output channel based on the object's configuration.
#
# Entry criteria:
#   $message - a plain-text description of the error; must not be undef
#
# Exit status:
#   Returns self (chainable)
#   Dies (via croak) if strict mode is enabled.
#   Otherwise returns normally after warning or logging.
#
# Side effects:
#   strict mode enabled    : logs as fatal via logger (if present) then dies
#   warn_on_error enabled  : logs as warn via logger (if present) or carps
#   neither flag set       : logs as notice via logger (if present) or prints
#                            a warning to STDERR
#
# Notes:
#   The emitted message is prefixed with the package name and the string
#   "XML Parsing Error:" for consistent identification in logs.
#   strict mode implies warn_on_error, enforced at construction time in new().
sub _handle_error {
	my ($self, $message) = @_;

	my $error_message = __PACKAGE__ . ": XML Parsing Error: $message";

	if($self->{strict}) {
		# Throws an error if strict mode is enabled
		if($self->{'logger'}) {
			$self->{'logger'}->fatal($error_message);
		}
		croak $error_message;
	} elsif ($self->{warn_on_error}) {
		# Otherwise, just warn
		if($self->{'logger'}) {
			$self->{'logger'}->warn($error_message);
		} else {
			carp $error_message;
		}
	} else {
		if($self->{'logger'}) {
			$self->{'logger'}->notice($error_message);
		} else {
			print STDERR "Warning: $error_message\n";
		}
	}

	return $self;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<XML::LibXML>

=item * L<XML::Simple>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
