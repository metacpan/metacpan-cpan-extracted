
package XML::Toolset::XMLDOM;

use strict;
use XML::Toolset::DOM;
use XML::DOM;
use XML::XPath;
use XML::DOM::XPath;

use vars qw($VERSION $CATCH_ERROR @ISA);
$VERSION = sprintf"%d.%03d", q$Revision: 1.21 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw(XML::Toolset::DOM);

my $VALID_OPTIONS = {
	validation => 1,
	schema_location => '',
};

sub new {
    &App::sub_entry if ($App::trace);
	my $class = shift;
	my %options = @_;
	my $self = {};
	bless ($self, $class);
	
	$self->set_options(\%options,$VALID_OPTIONS);
	
    &App::sub_exit($self) if ($App::trace);
	return $self;
}

sub version {
    &App::sub_entry if ($App::trace);
    &App::sub_exit($VERSION) if ($App::trace);
	return $VERSION;
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
	
	$self->{parser} = undef;

	die "validate_document called with no data to validate\n" unless defined $xml and length $xml > 0;

    my $parser = new XML::DOM::Parser;
    my ($dom);
    eval {
        $dom = $parser->parse($xml);
    };
    if ($@) {
        $self->add_error({message => $@});
    }
	if ($self->last_error) {
		die $self->last_error;
	}
	$self->{parser} = $parser;
    &App::sub_exit(1) if ($App::trace);
	return 1;
}

1;

__END__

=head1 NAME

XML::Toolset::XMLDOM - Interface to XML::DOM toolset

=head1 SYNOPSIS

	my $toolset = new XML::Toolset::XMLDOM(%options);
	if ($doc = $toolset->validate_document($xml)) {
		... Do stuff with $doc ...
	} else {
		print "Document is invalid\n";
	}

=head1 DESCRIPTION

XML::Toolset::XMLDOM is an interface to the XMLDOM parser which can
be used with the XML::Toolset module.

=head1 METHODS

=over

=item new(%options)

Returns a new XML::Toolset::XMLDOM instance using the specified options. (See
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

Returns the version of the XML::DOM module that is installed

=back

=head1 OPTIONS

XML::Toolset::XMLDOM takes the following options:

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

XML::DOM
XML::XPATH

=head1 VERSION

$Revision: 1.21 $ on $Date: 2005/09/06 11:05:09 $ by $Author: johna $

=head1 AUTHOR

Nathan Carr, Colin Robertson

E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
