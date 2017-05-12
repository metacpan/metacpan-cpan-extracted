package XML::Validate::Xerces;

use strict;
use XML::Validate::Base;
use XML::Xerces;

use vars qw($VERSION $CATCH_ERROR @ISA);
$VERSION = sprintf"%d.%03d", q$Revision: 1.21 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw(XML::Validate::Base);

# This should happen in the XML::Xerces INIT block, but we expect this module to
# be dynamically loaded, so the INIT block probably won't happen.
XML::Xerces::XMLPlatformUtils::Initialize();

my $VALID_OPTIONS = {
	strict_validation => 1,
	base_uri => '',
};

sub new {
	my $class = shift;
	my %options = @_;
	my $self = {};
	bless ($self, $class);
	
	$self->clear_errors();
	$self->set_options(\%options,$VALID_OPTIONS);
	
	DUMP("Instantiating XML::Validate::Xerces", $self);
	
	return $self;
}

sub version {
	return XML::Xerces->VERSION;
}

sub validate {
	my $self = shift;
	my ($xml) = @_;
	TRACE("Validating with Xerces. XML => " . defined($xml) ? $xml : 'undef' );
	
	$self->clear_errors();
	$self->{DOMParser} = undef;

	die "validate called with no data to validate\n" unless defined $xml and length $xml > 0;

	my $DOMparser = new XML::Xerces::XercesDOMParser;
	# set various validation arguments based on argument
	$self->_set_validation($DOMparser, $self->options->{strict_validation});

	# error handler
	my $ErrorHandler = XML::Validate::Xerces::ErrorHandler->new($self);
	$DOMparser->setErrorHandler($ErrorHandler);

	# Use Memory buffer input source to read the XML string
	my $input = XML::Xerces::MemBufInputSource->new($xml,$self->options->{base_uri});

	$DOMparser->parse($input);

	if ($self->last_error) {
		TRACE("Exception found",$self->last_error);
		return;
	}
	
	$self->{DOMParser} = $DOMparser;
	return 1;
}

sub last_dom {
	my $self = shift;
	return undef unless defined $self->{DOMParser};
	return $self->{DOMParser}->getDocument();
}

sub _set_validation {
	my $self = shift;
	my $DOMparser = shift;
	my $strict = shift;
	
	TRACE("_set_validation called");
	
	if ($strict) {
		TRACE("Using strict validation");
		$DOMparser->setValidationScheme("$XML::Xerces::AbstractDOMParser::Val_Auto");
		$DOMparser->setIncludeIgnorableWhitespace(0);
		$DOMparser->setDoSchema(1);
		$DOMparser->setDoNamespaces(1);
		$DOMparser->setValidationSchemaFullChecking(1);
		$DOMparser->setLoadExternalDTD(1);
		$DOMparser->setExitOnFirstFatalError(1);
		$DOMparser->setValidationConstraintFatal(1);
	} else {
		TRACE("Using no validation");
		$DOMparser->setValidationScheme("$XML::Xerces::AbstractDOMParser::Val_Never");
		$DOMparser->setDoSchema(0);
		$DOMparser->setDoNamespaces(0);
		$DOMparser->setValidationSchemaFullChecking(0);
		$DOMparser->setLoadExternalDTD(0);
	}
}

# Note: Our use of TRACE and DUMP here is a bit weird. We explicitly pass to
# the TRACE and DUMP in the superclass (XML::Validate::Base) because we expect
# to be dynamically loaded and we assume that the calling class will have dealt
# with Base but not this module. (Note that Log::Trace now has some support for
# dynamic loading. It doesn't play well with some modules in 5.6.1, but it seems
# fine in 5.8. So someday this won't be necessary.)

sub TRACE { XML::Validate::Base::TRACE(@_) }
sub DUMP  { XML::Validate::Base::DUMP(@_)  }

1;

# Override XML::Xerces errors into warnings we can catch
package XML::Validate::Xerces::ErrorHandler;

use vars '@ISA';
@ISA = qw(XML::Xerces::PerlErrorHandler);

sub new {
	my $class = shift;
	my ($validator) = @_;
	my $self = {
		validator => $validator,
	};
	return bless($self,$class)
}

sub warning {
	my ($self, $exception) = @_;
	$self->add_error($exception,"Warning");
}

sub error {
	my ($self, $exception) = @_;
	$self->add_error($exception,"Invalid XML");
}

sub fatal_error {
	my ($self, $exception) = @_;
	$self->add_error($exception,"XML error");
}

sub add_error {
	my $self = shift;
	my ($exception,$message_prefix) = @_;
	my $error = {
		line    => $exception->getLineNumber,
		column  => $exception->getColumnNumber,
		message => "$message_prefix: " . $exception->getMessage,
	};
	$self->{validator}->add_error($error);
}

1;

__END__

=head1 NAME

XML::Validate::Xerces - Interface to Xerces validator

=head1 SYNOPSIS

	my $validator = new XML::Validate::Xerces(%options);
	if ($doc = $validator->validate($xml)) {
		... Do stuff with $doc ...
	} else {
		print "Document is invalid\n";
	}

=head1 DESCRIPTION

XML::Validate::Xerces is an interface to the Xerces parser which can
be used with the XML::Validate module.

=head1 METHODS

=over

=item new(%options)

Returns a new XML::Validate::Xerces instance using the specified options. (See
OPTIONS below.)

=item validate($xml)

Returns a true value if $xml could be successfully parsed, undef otherwise.

=item last_dom()

Returns the Xerces DOM object of the document last validated.

=item last_error()

Returns the error from the last validate call. This is a hash ref with the
following fields:

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

Returns the version of the XML::Xerces module that is installed

=back

=head1 OPTIONS

XML::Validate::Xerces takes the following options:

=over

=item strict_validation

If this boolean value is true, the document will be validated during parsing.
Otherwise it will only be checked for well-formedness. Defaults to true.

=item base_uri

Since the XML document is supplied as a string, the validator doesn't know the
document's URI. If the document contains any components referenced using
relative URI's, you'll need to set this option to the document's URI so that
the validator can retrieve them correctly.

=back

=head1 ERROR REPORTING

When a call to validate fails to parse the document, the error may be retrieved
using last_error.

On errors not related to the XML parsing, these methods will throw exceptions.
Wrap calls with eval to catch them.

=head1 DEPENDENCIES

XML::Xerces

=head1 BUGS

XML::Xerces contains an INIT block that doesn't get run because we load the
module in an eval. This causes a warning message to be printed. We then run the
code in XML::Xerces ourselves, but this is fragile because XML::Xerces might
change. We need to keep an eye on this.

XML::Xerces reacts badly to code which does "use UNIVERSAL" (see
L<http://issues.apache.org/bugzilla/show_bug.cgi?id=25788>).
XML::Validate::Xerces inherits this bug. Modules that are known to cause
problems include Time::Piece and versions of XML::Twig prior to April 2005).

=head1 VERSION

$Revision: 1.21 $ on $Date: 2005/09/06 11:05:09 $ by $Author: johna $

=head1 AUTHOR

Nathan Carr, Colin Robertson

E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
