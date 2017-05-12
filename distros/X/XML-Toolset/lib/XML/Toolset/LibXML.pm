# XML::Toolset::LibXML

package XML::Toolset::LibXML;

use strict;

use XML::Toolset::DOM;

use vars qw($VERSION @ISA);
$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw(XML::Toolset::DOM);

use XML::LibXML;
use Carp;

sub version {
    &App::sub_entry if ($App::trace);
	my $version = XML::LibXML->VERSION;
    &App::sub_exit($version) if ($App::trace);
    return($version);
}

sub parse {
    &App::sub_entry if ($App::trace);
	my ($self, $xml, $options) = @_;
	
    $options = {} if (!$options);
	my $parser = $self->parser();

	my $dom = eval { $parser->parse_string($xml) };
	if ($@) {
		print("We have a parsing error: $@\n");
		$options->{error} = $@;
	}
	
	#print("We have a doctype\n") if ($dom && $dom->internalSubset());
	
	if ($dom && $self->{validation} && $self->{schema_location} && $dom->internalSubset()) {
		#print("Parsing with strict validation\n");
		$parser->validation(1);
		#print("Base uri",$self->{schema_location}, "\n");
		$dom = eval { $parser->parse_string($xml, $self->{schema_location}) };
		if ($@) {
			#print("We have a validation error: $@\n");
			$options->{error} = $@;
		}
		$parser->validation(0);
	}
	
    if ($dom && $options) {
	    $options->{dom} = $dom;
    }

    &App::sub_exit($dom) if ($App::trace);
	return($dom);
}

sub new_parser {
    &App::sub_entry if ($App::trace);
	my ($self, $options) = @_;
	my $parser = XML::LibXML->new();
	$parser->line_numbers(1) if $parser->can('line_numbers'); # (XML::LibXML > 1.56)
	$parser->load_ext_dtd(1);
	$parser->expand_entities(1);
    &App::sub_exit($parser) if ($App::trace);
	return($parser);
}

1;

__END__

=head1 NAME

XML::Toolset::LibXML - Interface to LibXML toolset

=head1 SYNOPSIS

  my $toolset = new XML::Toolset::LibXML(%options);
  if ($doc = $toolset->validate($xml)) {
    ... Do stuff with $doc ...
  } else {
    print "Document is invalid\n";
  }

=head1 DESCRIPTION

XML::Toolset::LibXML is an interface to the LibXML validating parser which can
be used with the XML::Toolset module.

=head1 METHODS

=over

=item new(%options)

Returns a new XML::Toolset::LibXML instance using the specified options. (See
OPTIONS below.)

=item validate($xml)

Returns a true value if $xml could be successfully parsed, undef otherwise.

Returns a true (XML::LibXML::Document) if $xml could be successfully
parsed, undef otherwise.

=item last_error()

Returns a hash ref containing the error from the last validate call. This
backend currently only fills in the message field of hash. Note that the error
gets cleared at the beginning of each C<validate> call.

=item version()

Returns the version of the XML::LibXML module that is installed

=back

=head1 OPTIONS

XML::Toolset::LibXML takes the following options:

=over

=item validation

If this boolean value is true, the document will be validated during parsing.
Otherwise it will only be checked for well-formedness. Defaults to true.

=item schema_location

Since the XML document is supplied as a string, the toolset doesn't know the
document's URI. If the document contains any components referenced using
relative URI's, you'll need to set this option to the document's URI so that
the toolset can retrieve them correctly.

=back

=head1 ERROR REPORTING

When a call to validate fails to parse the document, the error may be retrieved using last_error.

On errors not related to the XML parsing, these methods will throw exceptions.
Wrap calls with eval to catch them.

=head1 DEPENDENCIES

XML::LibXML

=head1 BUGS

last_error currently returns a hash ref with only the message field filled. It
would be nice to also fill the line and column fields.

=head1 VERSION

$Revision: 1.20 $ on $Date: 2005/09/06 11:05:08 $ by $Author: johna $

=head1 AUTHOR

Nathan Carr, Colin Robertson

E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
