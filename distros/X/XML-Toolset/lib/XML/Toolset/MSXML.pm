# XML::Toolset::MSXML

package XML::Toolset::MSXML;

use strict;

use vars qw( $VERSION @ISA $MSXML_VERSION);
use XML::Toolset::DOM;
use Win32::OLE;

$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw(XML::Toolset::DOM);

use constant XSI_NS => 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"';

my $VALID_OPTIONS = { validation => 1 };

sub new {
    &App::sub_entry if ($App::trace);
	my $class = shift;
	my %options = @_;
	my $self = {};
	bless ($self, $class);
	
	$self->set_options(\%options,$VALID_OPTIONS);
	
	#print("Instantiating XML::Toolset::MSXML", $self, "\n");
	
    &App::sub_exit($self) if ($App::trace);
	return $self;
}

sub version {
    &App::sub_entry if ($App::trace);
	eval {create_doc_and_cache()};
	my $version = $MSXML_VERSION;
    &App::sub_exit($version) if ($App::trace);
    return($version);
}

sub validate_document {
    &App::sub_entry if ($App::trace);
	my ($self, $doc) = @_;
    my ($xml);
    if (ref($doc)) {
        $xml = $doc->{xml};
    }
    else {
        $xml = $doc;
    }
	
	$self->{dom} = undef;
	
	die "validate_document called with no data to validate\n" unless defined $xml and length $xml > 0;

	#print("the xml to validate : $xml ", $self, "\n");

	my ($msxml,$msxmlcache) = create_doc_and_cache();

	$msxml->{async} = 0;
	$msxml->{validateOnParse} = 0;
	$msxml->{resolveExternals} = 1;
	
	#print("Starting to parse\n");
	$msxml->LoadXML($xml);
	#print("Parsed the document\n");
	
	my $xmlroot = $msxml->{documentElement};
	
	if ($msxml->parseError()->{errorCode} != 0) {
		#print("XML Parse Error (not syntactically valid)\n");
		my $error = $msxml->parseError();
		#print("Error", $error, "\n");
		$self->add_error({
			message => $error->{reason},
			line    => $error->{line},
			column  => $error->{linepos}
		});
		return;
	}
	
	if ($self->{validation}) {
		#print("XML Syntactically valid\n");
		load_schemas($msxml, $msxmlcache);
		#print("Toolset against schema/DTD \n");
		if ($msxml->{doctype} || $msxml->{schemas}) {
			#print($msxml->{doctype}, $msxml->{schemas}, "\n");
			$msxml->{validateOnParse} = 1;
			$msxml->LoadXML($xml);
			my $error = $msxml->parseError();
			if ($error->{errorCode} != 0) {
				$self->add_error({
					message => $error->{reason},
					line    => $error->{line},
					column  => $error->{linepos}
				});
				return;
			}
			$error = $msxml->validate();
			if ($error->{errorCode} != 0) {
				$self->add_error({
					message => $error->{reason},
					line    => $error->{line},
					column  => $error->{linepos}
				});
				return;
			}
		} else {
			# If there is nothing to validate against, treat it as valid.
			#print("No doctype or schema\n");
		}
	}

	#Valid
	$self->{dom} = $msxml;
    &App::sub_exit(1) if ($App::trace);
	return 1;
}

sub load_schemas {
    &App::sub_entry if ($App::trace);
	my ($xml, $schema_cache) = @_;
	
	my %schemas;
	
	$xml->setProperty('SelectionNamespaces', XSI_NS);
	my $no_ns_schema_xpath = q[//*/@xsi:noNamespaceSchemaLocation];
	my $no_ns_schema_nodes = $xml->{documentElement}->selectNodes($no_ns_schema_xpath);
	
	for (my $i=0; $i < $no_ns_schema_nodes->{length}; $i++){
		my $schema_txt = $no_ns_schema_nodes->item($i)->{text};
		my %add_schemas = ('', $schema_txt);
		%schemas = (%schemas, %add_schemas);
	}
	
	my $schema_xpath = q[//*/@xsi:schemaLocation];
	my $schema_location_nodes = $xml->{documentElement}->selectNodes($schema_xpath);

	for (my $i=0; $i < $schema_location_nodes->{length}; $i++){
		my $schema_txt = $schema_location_nodes->item($i)->{text};
		my %add_schemas = split ' ', $schema_txt;
		%schemas = (%schemas, %add_schemas);
	}
	
	while (my ($ns, $schema) = each %schemas) {
		#print("Loading schema [$ns] -> $schema\n");
		$schema_cache->add($ns, $schema);
		if (my $schema_error = Win32::OLE::LastError()) {
			$schema_error =~ s/OLE exception .*\n\n//m;
			$schema_error =~ s/Win32::OLE.*//s;
			die $schema_error;
		}
	}
	$xml->{schemas} = $schema_cache if %schemas;
    &App::sub_exit() if ($App::trace);
	return;
}

sub dependencies_available {
    &App::sub_entry if ($App::trace);
	create_doc_and_cache();
    &App::sub_exit(1) if ($App::trace);
	return 1;
}

sub create_doc_and_cache {
    &App::sub_entry if ($App::trace);
	# Stop Win32::OLE from being noisy
	my $warn_level = Win32::OLE->Option('Warn');
	Win32::OLE->Option(Warn => 0);

	foreach my $version ('5.0', '4.0') {
		my $doc   = Win32::OLE->new('MSXML2.DOMDocument.' . $version) or next;
		my $cache = Win32::OLE->new('MSXML2.XMLSchemaCache.' . $version) or next;
		$MSXML_VERSION = $version;
		Win32::OLE->Option(Warn => $warn_level); # restore warn level
		return ($doc,$cache);
	}
	die "Unable to instantiate MSXML DOMDocument and SchemaCache. (Do you have a compatible version of MSXML installed?)";
    &App::sub_exit() if ($App::trace);
}

dependencies_available();

__END__

=head1 NAME

XML::Toolset::MSXML - Interface to MSXML toolset

=head1 SYNOPSIS

  my $toolset = new XML::Toolset::MSXML(%options);
  if ($doc = $toolset->validate_document($xml)) {
    ... Do stuff with $doc ...
  } else {
    print "Document is invalid\n";
  }

=head1 DESCRIPTION

XML::Toolset::MSXML is an interface to Microsoft's MSXML parser (often
available in Windows environments) which can be used with the XML::Toolset
module.

=head1 METHODS

=over

=item new(%options)

Returns a new XML::Toolset::MSXML instance using the specified options. (See
OPTIONS below.)

=item validate_document($xml)

Returns true if $xml could be successfully parsed, undef otherwise.

=item last_error()

Returns the error from the last validate_document call. This is a hash ref with the
following fields:

=item create_doc_and_cache()

Internal method for instantiation of MSXML DOMDocument and SchemaCache objects
for use within the module.
 
=item dependencies_available()

Internal method to determine that the necessary dependencies are available for
instantiation of MSXML DOMDocument and SchemaCache objects.

=item load_schemas($msxml, $msxmlcache)

Internal method to perform loading of XML schema(s) into SchemaCache object.

=over

=item *

message

=item *

line

=item *

column

=back

Note that the error gets cleared at the beginning of each C<validate_document> call.

=item version()

Returns the version of the MSXML component that is installed

=back

=head1 OPTIONS

XML::Toolset::MSXML takes the following options:

=over

=item validation

If this boolean value is true, the document will be validated during parsing.
Otherwise it will only be checked for well-formedness. Defaults to true.

=back

=head1 ERROR REPORTING

When a call to validate_document fails to parse the document, the error may be retrieved
using last_error.

On errors not related to the XML parsing, these methods will throw exceptions.
Wrap calls with eval to catch them.

=head1 PACKAGE GLOBALS

$XML::Toolset::MSXML::MSXML_VERSION contains the version number of MSXML.

=head1 DEPENDENCIES

Win32::OLE, MSXML 4.0 or 5.0

=head1 VERSION

$Revision: 1.18 $ on $Date: 2006/04/18 10:00:31 $ by $Author: mattheww $

=head1 AUTHOR

Nathan Carr, Colin Robertson

E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
