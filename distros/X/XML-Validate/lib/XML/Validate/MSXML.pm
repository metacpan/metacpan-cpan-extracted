# XML::Validate::MSXML

package XML::Validate::MSXML;

use strict;
use Win32::OLE;
use XML::Validate::Base;
use vars qw( $VERSION @ISA $MSXML_VERSION);

@ISA = qw( XML::Validate::Base );
$VERSION = sprintf'%d.%03d', q$Revision: 1.18 $ =~ /: (\d+)\.(\d+)/;

use constant XSI_NS => 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"';

my $VALID_OPTIONS = { strict_validation => 1 };

sub new {
	my $class = shift;
	my %options = @_;
	my $self = {};
	bless ($self, $class);
	
	$self->clear_errors();
	$self->set_options(\%options,$VALID_OPTIONS);
	
	DUMP("Instantiating XML::Validate::MSXML", $self);
	
	return $self;
}

sub version {
	eval {create_doc_and_cache()};
	return $MSXML_VERSION;
}

sub validate {
	my ($self, $xml) = @_;
	
	$self->clear_errors();
	$self->{dom} = undef;
	
	die "validate called with no data to validate\n" unless defined $xml and length $xml > 0;

	DUMP("the xml to validate : $xml ", $self);

	my ($msxml,$msxmlcache) = create_doc_and_cache();

	$msxml->{async} = 0;
	$msxml->{validateOnParse} = 0;
	$msxml->{resolveExternals} = 1;
	
	TRACE("Starting to parse");
	$msxml->LoadXML($xml);
	TRACE("Parsed the document");
	
	my $xmlroot = $msxml->{documentElement};
	
	if ($msxml->parseError()->{errorCode} != 0) {
		TRACE("XML Parse Error (not syntactically valid)");
		my $error = $msxml->parseError();
		DUMP("Error", $error);
		$self->add_error({
			message => $error->{reason},
			line    => $error->{line},
			column  => $error->{linepos}
		});
		return;
	}
	
	if ($self->options->{strict_validation}) {
		TRACE("XML Syntactically valid");
		load_schemas($msxml, $msxmlcache);
		TRACE("Validate against schema/DTD ");
		if ($msxml->{doctype} || $msxml->{schemas}) {
			#DUMP($msxml->{doctype}, $msxml->{schemas});
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
			TRACE("No doctype or schema");
		}
	}

	#Valid
	$self->{dom} = $msxml;
	return 1;
}

sub last_dom {
	my $self = shift;
	return $self->{dom};
}

sub load_schemas {
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
		TRACE("Loading schema [$ns] -> $schema");
		$schema_cache->add($ns, $schema);
		if (my $schema_error = Win32::OLE::LastError()) {
			$schema_error =~ s/OLE exception .*\n\n//m;
			$schema_error =~ s/Win32::OLE.*//s;
			die $schema_error;
		}
	}
	$xml->{schemas} = $schema_cache if %schemas;
	return;
}

sub dependencies_available {
	create_doc_and_cache();
	return 1;
}

sub create_doc_and_cache {
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
}

# Note: Our use of TRACE and DUMP here is a bit weird. We explicitly pass to
# the TRACE and DUMP in the superclass (XML::Validate::Base) because we expect
# to be dynamically loaded and we assume that the calling class will have dealt
# with Base but not this module. (Note that Log::Trace now has some support for
# dynamic loading. It doesn't play well with some modules in 5.6.1, but it seems
# fine in 5.8. So someday this won't be necessary.)

sub TRACE { XML::Validate::Base::TRACE(@_) }
sub DUMP  { XML::Validate::Base::DUMP(@_)  }

dependencies_available();

__END__

=head1 NAME

XML::Validate::MSXML - Interface to MSXML validator

=head1 SYNOPSIS

  my $validator = new XML::Validate::MSXML(%options);
  if ($doc = $validator->validate($xml)) {
    ... Do stuff with $doc ...
  } else {
    print "Document is invalid\n";
  }

=head1 DESCRIPTION

XML::Validate::MSXML is an interface to Microsoft's MSXML parser (often
available in Windows environments) which can be used with the XML::Validate
module.

=head1 METHODS

=over

=item new(%options)

Returns a new XML::Validate::MSXML instance using the specified options. (See
OPTIONS below.)

=item validate($xml)

Returns true if $xml could be successfully parsed, undef otherwise.

=item last_dom()

Returns the MSXML DOM object of the document last validated.

=item last_error()

Returns the error from the last validate call. This is a hash ref with the
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

Note that the error gets cleared at the beginning of each C<validate> call.

=item version()

Returns the version of the MSXML component that is installed

=back

=head1 OPTIONS

XML::Validate::MSXML takes the following options:

=over

=item strict_validation

If this boolean value is true, the document will be validated during parsing.
Otherwise it will only be checked for well-formedness. Defaults to true.

=back

=head1 ERROR REPORTING

When a call to validate fails to parse the document, the error may be retrieved
using last_error.

On errors not related to the XML parsing, these methods will throw exceptions.
Wrap calls with eval to catch them.

=head1 PACKAGE GLOBALS

$XML::Validate::MSXML::MSXML_VERSION contains the version number of MSXML.

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
