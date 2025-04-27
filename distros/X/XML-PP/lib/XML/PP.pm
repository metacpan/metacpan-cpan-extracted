package XML::PP;

use strict;
use warnings;

use Log::Abstraction;
use Params::Get;
use Scalar::Util;

=head1 NAME

XML::PP - A simple XML parser

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use XML::PP;

  my $parser = XML::PP->new();
  my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from><heading>Reminder</heading><body importance="high">Don\'t forget me this weekend!</body></note>';
  my $tree = $parser->parse($xml);

  print $tree->{name};	# 'note'
  print $tree->{children}[0]->{name};	# 'to'

=head1 DESCRIPTION

You almost certainly do not need this module,
for most tasks use L<XML::Simple> or L<XML::LibXML>.
C<XML::PP> exists only for the most lightweight of scenarios where you can't get one of the above modules to install,
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

	my $params = Params::Get::get_params(undef, @_);

	# strict implies warn_on_error
	if($params->{strict}) {
		$params->{warn_on_error} = 1;
	}

	my $self = bless {
		strict => $params->{strict} // 0,
		warn_on_error => $params->{warn_on_error} // 0,
		$params ? %{$params} : {},
	}, $class;

	if(my $logger = $self->{'logger'}) {
		if(!Scalar::Util::blessed($logger)) {
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

	$xml_string =~ s/<\?xml.+?>//;	# Ignore the header

	$xml_string =~ s/^\s+|\s+$//g;	# Trim whitespace
	return $self->_parse_node(\$xml_string, {});
}

=head2 collapse_structure

Collapse an XML-like structure into a simplified hash (like L<XML::Simple>).

  use XML::PP;

  my $input = {
      name => 'note',
      children => [
          { name => 'to', children => [ { text => 'Tove' } ] },
          { name => 'from', children => [ { text => 'Jani' } ] },
          { name => 'heading', children => [ { text => 'Reminder' } ] },
          { name => 'body', children => [ { text => 'Don\'t forget me this weekend!' } ] },
      ],
      attributes => { id => 'n1' },
  };

  my $result = collapse_structure($input);

  # Output:
  # {
  #     note => {
  #         to      => 'Tove',
  #         from    => 'Jani',
  #         heading => 'Reminder',
  #         body    => 'Don\'t forget me this weekend!',
  #     }
  # }

The C<collapse_structure> subroutine takes a nested hash structure (representing an XML-like data structure) and collapses it into a simplified hash where each child element is mapped to its name as the key, and the text content is mapped as the corresponding value. The final result is wrapped in a C<note> key, which contains a hash of all child elements.

This subroutine is particularly useful for flattening XML-like data into a more manageable hash format, suitable for further processing or display.

C<collapse_structure> accepts a single argument:

=over 4

=item * C<$node> (Required)

A hash reference representing a node with the following structure:

  {
      name      => 'element_name',  # Name of the element (e.g., 'note', 'to', etc.)
      children  => [                # List of child elements
          { name => 'child_name', children => [{ text => 'value' }] },
          ...
      ],
      attributes => { ... },        # Optional attributes for the element
      ns_uri => ... ,               # Optional namespace URI
      ns => ... ,                   # Optional namespace
  }

The C<children> key holds an array of child elements. Each child element may have its own C<name> and C<text>, and the function will collapse all text values into key-value pairs.

=back

The subroutine returns a hash reference that represents the collapsed structure, where the top-level key is C<note> and its value is another hash containing the child elements' names as keys and their corresponding text values as values.

For example:

  {
      note => {
          to      => 'Tove',
          from    => 'Jani',
          heading => 'Reminder',
          body    => 'Don\'t forget me this weekend!',
      }
  }

=over 4

=item Basic Example:

Given the following input structure:

  my $input = {
      name => 'note',
      children => [
          { name => 'to', children => [ { text => 'Tove' } ] },
          { name => 'from', children => [ { text => 'Jani' } ] },
          { name => 'heading', children => [ { text => 'Reminder' } ] },
          { name => 'body', children => [ { text => 'Don\'t forget me this weekend!' } ] },
      ],
  };

Calling C<collapse_structure> will return:

  {
      note => {
          to      => 'Tove',
          from    => 'Jani',
          heading => 'Reminder',
          body    => 'Don\'t forget me this weekend!',
      }
  }

=back

=cut

sub collapse_structure {
	# my ($self, $node) = @_;
	my $self = shift;
	my $params = Params::Get::get_params('node', \@_);
	my $node = $params->{'node'};

	return {} unless ref $node eq 'HASH' && $node->{children};

	my %result;
	for my $child (@{ $node->{children} }) {
		my $name = $child->{name} or next;
		my $value;

		if ($child->{children} && @{ $child->{children} }) {
			if (@{ $child->{children} } == 1 && exists $child->{children}[0]{text}) {
				$value = $child->{children}[0]{text};
			} else {
				$value = $self->collapse_structure($child)->{$name};
			}
		}

		next unless defined $value && $value ne '';

		# Handle multiple same-name children as an array
		if (exists $result{$name}) {
			$result{$name} = [ $result{$name} ] unless ref $result{$name} eq 'ARRAY';
			push @{ $result{$name} }, $value;
		} else {
			$result{$name} = $value;
		}
	}
	return { $node->{name} => \%result };
}

=head2 _parse_node

  my $node = $self->_parse_node($xml_ref, $nsmap);

Recursively parses an individual XML node.
This method is used internally by the C<parse> method.
It handles the parsing of tags, attributes, text nodes, and child elements.
It also manages namespaces and handles self-closing tags.

=cut

# Internal method to parse an individual XML node
sub _parse_node {
	my ($self, $xml_ref, $nsmap) = @_;

	# Match the start of a tag (self-closing or regular)
	$$xml_ref =~ s{^\s*<([^\s/>]+)([^>]*)\s*(/?)>}{}s or do {
		$self->_handle_error('Expected a valid XML tag, but none found at position: ' . pos($$xml_ref));
		return;
	};

	my ($raw_tag, $attr_string, $self_close) = ($1, $2 || '', $3);

	# Check for malformed self-closing tags
	if ($self_close && $$xml_ref !~ /^\s*<\/(?:\w+:)?$raw_tag\s*>/) {
		$self->_handle_error("Malformed self-closing tag for <$raw_tag>");
		return;
	}

	# Handle possible trailing slash like <line break="yes"/>
	if ($attr_string =~ s{/\s*$}{}) {
		$self_close = 1;
	}

	my ($ns, $tag) = $raw_tag =~ /^([^:]+):(.+)$/
		? ($1, $2)
		: (undef, $raw_tag);

	my %local_nsmap = (%$nsmap);

	# XMLNS declarations
	while ($attr_string =~ /(\w+)(?::(\w+))?="([^"]*)"/g) {
		my ($k1, $k2, $v) = ($1, $2, $3);
		if ($k1 eq 'xmlns' && !defined $k2) {
			$local_nsmap{''} = $v;
		} elsif ($k1 eq 'xmlns' && defined $k2) {
			$local_nsmap{$k2} = $v;
		}
	}

	my %attributes;
	pos($attr_string) = 0;
	while ($attr_string =~ /(\w+)(?::(\w+))?="([^"]*)"/g) {
		my ($k1, $k2, $v) = ($1, $2, $3);
		next if $k1 eq 'xmlns';
		my $attr_name = defined $k2 ? "$k1:$k2" : $k1;
		$attributes{$attr_name} = $self->_decode_entities($v);
	}

	my $node = {
		name => $tag,
		ns => $ns,
		ns_uri => defined $ns ? $local_nsmap{$ns} : undef,
		attributes => \%attributes,
		children => [],
	};

	# Return immediately if self-closing tag
	return $node if $self_close;

	# Capture text
	if ($$xml_ref =~ s{^([^<]+)}{}s) {
		my $text = $self->_decode_entities($1);
		$text =~ s/^\s+|\s+$//g;
		push @{ $node->{children} }, { text => $text } if $text ne '';
	}

	# Recursively parse children
	while ($$xml_ref =~ /^\s*<([^\/>"][^>]*)>/) {
		my $child = $self->_parse_node($xml_ref, \%local_nsmap);
		push @{ $node->{children} }, $child if $child;
	}

	# Consume closing tag
	$$xml_ref =~ s{^\s*</(?:\w+:)?$tag\s*>}{}s;

	return $node;
}

# Internal helper to decode XML entities
sub _decode_entities {
	my ($self, $text) = @_;

	return undef unless defined $text;

	# Decode known named entities
	$text =~ s/&lt;/</g;
	$text =~ s/&gt;/>/g;
	$text =~ s/&amp;/&/g;
	$text =~ s/&quot;/"/g;
	$text =~ s/&apos;/'/g;

	# Decode decimal numeric entities
	$text =~ s/&#(\d+);/chr($1)/eg;

	# Decode hex numeric entities
	$text =~ s/&#x([0-9a-fA-F]+);/chr(hex($1))/eg;

	if ($text =~ /&([^;]*);/) {
		my $entity = $1;
		unless ($entity =~ /^(lt|gt|amp|quot|apos)$/ || $entity =~ /^#(?:x[0-9a-fA-F]+|\d+)$/) {
			my $msg = "Unknown or malformed XML entity: &$entity;";
			$self->_handle_error($msg);
		}
	}

	if ($text =~ /&/) {
		my $msg = "Unescaped ampersand detected: $text";
		$self->_handle_error($msg);
	}

	return $text;
}

sub _handle_error {
	my ($self, $message) = @_;

	my $error_message = __PACKAGE__ . ": XML Parsing Error: $message";

	if($self->{strict}) {
		# Throws an error if strict mode is enabled
		if($self->{'logger'}) {
			$self->fatal($error_message);
		}
		die $error_message;
	} elsif ($self->{warn_on_error}) {
		# Otherwise, just warn
		if($self->{'logger'}) {
			$self->warn($error_message);
		} else {
			warn $error_message;
		}
	} else {
		if($self->{'logger'}) {
			$self->notice($error_message);
		} else {
			print STDERR "Warning: $error_message\n";
		}
	}
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

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
