package XML::Toolset::Xerces;

use strict;
use XML::Toolset::DOM;
use XML::Xerces;

use vars qw($VERSION $CATCH_ERROR @ISA);
$VERSION = sprintf"%d.%03d", q$Revision: 1.21 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw(XML::Toolset::DOM);

# This should happen in the XML::Xerces INIT block, but we expect this module to
# be dynamically loaded, so the INIT block probably won't happen.
XML::Xerces::XMLPlatformUtils::Initialize();

sub version {
    &App::sub_entry if ($App::trace);
    my $version = XML::Xerces->VERSION;
    &App::sub_exit($version) if ($App::trace);
    return($version);
}

sub parse {
    &App::sub_entry if ($App::trace);
    my ($self, $xml, $options) = @_;

    $options = {} if (!$options);
    my $parser = $self->parser();
    my $results = $self->{results};
    delete $results->{error};
    delete $results->{error_line};
    delete $results->{error_column};

    # Use Memory buffer input source to read the XML string
    my $input = XML::Xerces::MemBufInputSource->new($xml,$self->{schema_location});
    $parser->parse($input);
    my $dom = $parser->getDocument();
    
    if ($results->{error}) {
        $options->{error}        = $results->{error};
        $options->{error_line}   = $results->{error_line};
        $options->{error_column} = $results->{error_column};
        $dom = undef;
    }
    else {
        $options->{dom} = $dom;
    }

    &App::sub_exit($dom) if ($App::trace);
    return($dom);
}

sub new_parser {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;

    my $results = {};
    $self->{results} = $results;
    my $parser = new XML::Xerces::XercesDOMParser;
    # set various validation arguments based on argument
    my $validation = $self->{validation};
    if ($validation) {
        #print "SETTING STRICT VALIDATION [results=$results]\n";
        $parser->setValidationScheme("$XML::Xerces::AbstractDOMParser::Val_Auto");
        $parser->setIncludeIgnorableWhitespace(0);
        $parser->setDoSchema(1);
        $parser->setDoNamespaces(1);
        $parser->setValidationSchemaFullChecking(1);
        $parser->setLoadExternalDTD(1);
        $parser->setExitOnFirstFatalError(1);
        $parser->setValidationConstraintFatal(1);
    }
    else {
        #print "SETTING MINIMUM VALIDATION [results=$results]\n";
        $parser->setValidationScheme("$XML::Xerces::AbstractDOMParser::Val_Never");
        $parser->setDoSchema(0);
        $parser->setDoNamespaces(0);
        $parser->setValidationSchemaFullChecking(0);
        $parser->setLoadExternalDTD(0);
    }
    # error handler
    my $ErrorHandler = XML::Toolset::Xerces::ErrorHandler->new($self, results => $results);
    $parser->setErrorHandler($ErrorHandler);

    &App::sub_exit($parser) if ($App::trace);
    return($parser);
}

sub new_dom {
    &App::sub_entry if ($App::trace);
    my ($self, $root_tag, $xmlns) = @_;

    $xmlns = $self->{xmlns} if (!$xmlns);
    $xmlns = "" if (!$xmlns);

    #print "impl=$impl createDocument($xmlns, $root_tag, undef)\n";
    my $impl = XML::Xerces::DOMImplementationRegistry::getDOMImplementation('LS');
    my $dom = eval{$impl->createDocument($xmlns, $root_tag, undef)};
    XML::Xerces::error($@) if $@;

    &App::sub_exit($dom) if ($App::trace);
    return($dom);
}

sub to_string {
    &App::sub_entry if ($App::trace);
    my ($self, $doc) = @_;

    my $dom = $doc->dom();
    my $impl = XML::Xerces::DOMImplementationRegistry::getDOMImplementation('LS');
    my $writer = $impl->createDOMWriter();
    if ($writer->canSetFeature('format-pretty-print',1)) {
        $writer->setFeature('format-pretty-print',1);
    }
    my $target = XML::Xerces::MemBufFormatTarget->new();
    $writer->writeNode($target,$dom);
    my $xml = $target->getRawBuffer();

    &App::sub_exit($xml) if ($App::trace);
    return($xml);
}

1;

# Override XML::Xerces errors into warnings we can catch
package XML::Toolset::Xerces::ErrorHandler;

use vars '@ISA';
@ISA = qw(XML::Xerces::PerlErrorHandler);

sub new {
    &App::sub_entry if ($App::trace);
    my ($class, $xml_toolset, @args) = @_;
    my $self = {
        xml_toolset => $xml_toolset, @args
    };
    die "results hash not provided" if (!$self->{results});
    bless $self, $class;
    &App::sub_exit($self) if ($App::trace);
    return($self);
}

sub warning {
    &App::sub_entry if ($App::trace);
    my ($self, $exception) = @_;
    $self->error_result($exception,"Warning");
    &App::sub_exit() if ($App::trace);
}

sub error {
    &App::sub_entry if ($App::trace);
    my ($self, $exception) = @_;
    $self->error_result($exception,"Invalid XML");
    &App::sub_exit() if ($App::trace);
}

sub fatal_error {
    &App::sub_entry if ($App::trace);
    my ($self, $exception) = @_;
    $self->error_result($exception,"XML error");
    &App::sub_exit() if ($App::trace);
}

sub error_result {
    &App::sub_entry if ($App::trace);
    my ($self, $exception, $message_prefix) = @_;
    my $results = $self->{results};
    $results->{error}        = "$message_prefix: " . $exception->getMessage;
    $results->{error_line}   = $exception->getLineNumber;
    $results->{error_column} = $exception->getColumnNumber;
    #print "ERROR: $results->{error} [Line: $results->{error_line}][Col: $results->{error_column}] [results=$results]\n";
    &App::sub_exit() if ($App::trace);
}

1;

__END__

=head1 NAME

XML::Toolset::Xerces - Interface to Xerces toolset

=head1 SYNOPSIS

    my $toolset = new XML::Toolset::Xerces(%options);
    if ($doc = $toolset->validate_document($xml)) {
        ... Do stuff with $doc ...
    } else {
        print "Document is invalid\n";
    }

=head1 DESCRIPTION

XML::Toolset::Xerces is an interface to the Xerces parser which can
be used with the XML::Toolset module.

=head1 METHODS

=over

=item new(%options)

Returns a new XML::Toolset::Xerces instance using the specified options. (See
OPTIONS below.)

=item validate_document($xml)

Returns a true value if $xml could be successfully parsed, undef otherwise.

=item last_error()

Returns the error from the last validate_document call. This is a hash ref with the
following fields:

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

Returns the version of the XML::Xerces module that is installed

=back

=head1 OPTIONS

XML::Toolset::Xerces takes the following options:

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

When a call to validate_document fails to parse the document, the error may be retrieved
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
XML::Toolset::Xerces inherits this bug. Modules that are known to cause
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
