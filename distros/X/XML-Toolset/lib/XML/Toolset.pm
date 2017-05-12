
package XML::Toolset;

use strict;
use App;
use App::Service;
use vars qw($VERSION @ISA);

$VERSION = sprintf"%d.%03d", q$Revision: 1.25 $ =~ /: (\d+)\.(\d+)/;
@ISA = ("App::Service");

use XML::Toolset::Document;

=head1 NAME

XML::Toolset - perform XML construction, parsing, validation, and XPath operations using whatever underlying XML library is available (ALPHA!)

=head1 SYNOPSIS

    use App;
    use XML::Toolset;

    my $context = App->context();
    my $toolset = $context->xml_toolset(class => "XML::Toolset::BestAvailable");

    ...

=head1 DESCRIPTION

The XML-Toolset distribution is a wrapper which provides a simplified XML
processing API which uses XPath to construct and dissect XML messages.

The architecture of the XML-Toolset distribution allows for the user of
the API to access XML capabilities independent of the underlying XML
toolset technology: i.e. Xerces, LibXML, XML::XMLDOM, MSXML.

=cut

###########################################################################
# abstract methods
###########################################################################

sub get_value {
    &App::sub_entry if ($App::trace);
	my ($self, $xpath) = @_;
	my ($value);
	die "get_value() must be implemented in a subclass";
    &App::sub_exit($value) if ($App::trace);
    return($value);
}

sub set_value {
    &App::sub_entry if ($App::trace);
	my ($self, $xpath, $value) = @_;
	die "set_value() must be implemented in a subclass";
    &App::sub_exit() if ($App::trace);
}

sub get_nodes {
    &App::sub_entry if ($App::trace);
	my ($self, $xpath) = @_;
	my (@nodes);
	die "set_nodes() must be implemented in a subclass";
    &App::sub_exit(@nodes) if ($App::trace);
    return(@nodes);
}

sub set_nodes {
    &App::sub_entry if ($App::trace);
	my ($self, @nodes) = @_;
	die "set_nodes() must be implemented in a subclass";
    &App::sub_exit() if ($App::trace);
}

sub to_string {
    &App::sub_entry if ($App::trace);
	my ($self) = @_;
	my ($xml);
	die "to_string() must be implemented in a subclass";
    &App::sub_exit($xml) if ($App::trace);
    return($xml);
}

sub transform {
    &App::sub_entry if ($App::trace);
	my ($self) = @_;
	die "transform() must be implemented in a subclass";
    &App::sub_exit() if ($App::trace);
}

sub version {
    &App::sub_entry if ($App::trace);
	my ($self) = @_;
    my ($version);
	die "version() must be implemented in a subclass";
    &App::sub_exit($version) if ($App::trace);
    return($version);
}

sub new_parser {
    &App::sub_entry if ($App::trace);
	my ($self, $options) = @_;
	my $parser = undef;
    die "new_parser() must be implemented in a subclass";
    &App::sub_exit($parser) if ($App::trace);
	return($parser);
}

sub new_dom {
    &App::sub_entry if ($App::trace);
    my ($self, $root_tag, $xmlns) = @_;
    my ($dom);
    die "new_dom() must be implemented in a subclass";
    &App::sub_exit($dom) if ($App::trace);
    return($dom);
}

sub parse {
    &App::sub_entry if ($App::trace);
	my ($self, $xml, $options) = @_;
	
    my $valid = 1;
    die "parse() must be implemented in a subclass";

    &App::sub_exit($valid) if ($App::trace);
	return($valid);
}

###########################################################################
# base class methods
###########################################################################

#<?xml version="1.0" encoding="UTF-8"?>
#<OTA_PingRS ... />

sub get_root_tag {
    &App::sub_entry if ($App::trace);
	my ($self, $doc) = @_;
    my ($tag);
    my $xml = $self->doc2xml($doc);
    if ($xml =~ /^(<\?xml[^<>]*\?>)?\s*<\s*(\S+)/s) {
        $tag = $2;
    }
    &App::sub_exit($tag) if ($App::trace);
    return($tag);
}

sub get_root_element_attribute {
    &App::sub_entry if ($App::trace);
	my ($self, $xml, $attrib) = @_;
    my ($root_tag, $value);
    if ($xml =~ /^(<\?xml[^<>]*\?>)?\s*<\s*(\S+)[^<>]*\s+$attrib\s*=\s*['"]([^<>'"]*)['"]/s) {
        $root_tag = $2;
        $value = $3;
    }
    &App::sub_exit($value) if ($App::trace);
    return($value);
}

sub set_root_element_attribute {
    &App::sub_entry if ($App::trace);
	my ($self, $xmlref, $attrib, $value) = @_;
    my ($root_tag);
    $$xmlref =~ s/^(<\?xml[^<>]*\?>)?(\s*<\s*\S+[^<>]*\s+$attrib\s*=\s*['"])([^<>'"]*)(['"])/$1$2$value$4/s;
    &App::sub_exit() if ($App::trace);
}

sub new_document {
    &App::sub_entry if ($App::trace);
    my ($self, @args) = @_;
    my $doc = XML::Toolset::Document->new(@args, xml_toolset => $self);
    &App::sub_exit($doc) if ($App::trace);
    return($doc);
}

sub type {
    &App::sub_entry if ($App::trace);
	my ($self) = @_;
	my $class = ref($self);
	$class =~ m/XML::Toolset::(.*)/;
    my $type = $1;
    &App::sub_exit($type) if ($App::trace);
	return($type);
}

sub validate_document {
    &App::sub_entry if ($App::trace);
	my ($self, $doc, $options) = @_;
    my $xml = $self->doc2xml($doc);

    if ($self->{xmlns} && $self->{schema_location}) {
        my $schema_location = $self->get_root_element_attribute($xml,"xsi:schemaLocation");
        #if ($schema_location && $schema_location =~ /^$self->{xmlns} /) { }
        if ($schema_location) {
            my $schema_file = $schema_location;
            $schema_file =~ s/.* //;
            if ($schema_file =~ m/^[a-z]:/i || $schema_file =~ m/^[\\\/]/) {
                $schema_file =~ s/.*[\\\/]//;
                my $good_schema_location = "$self->{xmlns} $self->{schema_location}/$schema_file";
                $self->set_root_element_attribute(\$xml,"xsi:schemaLocation",$good_schema_location);
            }
        }
    }

    $options = {} if (!$options);
    my $valid = 1;
    delete $options->{dom};
    delete $options->{error};
    delete $options->{error_line};
    delete $options->{error_column};

	die "validate called with no data to validate\n" unless defined $xml and length $xml > 0;

    my $dom = $self->parse($xml, $options);
    if ($dom && !$options->{error}) {
        $options->{dom} = $dom;
    }
    else {
        $valid = 0;
    }

    &App::sub_exit($valid) if ($App::trace);
	return($valid);
}

sub doc2dom {
    &App::sub_entry if ($App::trace);
    my ($self, $doc) = @_;
    my $ref = ref($doc);
    my ($dom);
    if (!$ref) {
        $dom = $self->parse($doc);
    }
    elsif ($ref eq "XML::Toolset::Document") {
        $dom = $doc->dom();
    }
    else {
        $dom = $doc;
    }
    &App::sub_exit($dom) if ($App::trace);
    return($dom);
}

sub doc2xml {
    &App::sub_entry if ($App::trace);
    my ($self, $doc) = @_;
    my $ref = ref($doc);
    my ($xml);
    if (!$ref) {
        $xml = $doc;
    }
    elsif ($ref eq "XML::Toolset::Document") {
        $xml = $doc->xml();
    }
    else {
        $xml = $doc->to_string();
    }
    &App::sub_exit($xml) if ($App::trace);
    return($xml);
}

sub set_validation {
    &App::sub_entry if ($App::trace);
    my ($self, $validation) = @_;
    $self->{validation} = $validation;
    delete $self->{parser};   # the next parser will have the new validation setting
    &App::sub_exit() if ($App::trace);
}

sub parser {
    &App::sub_entry if ($App::trace);
	my ($self, $options) = @_;
	my $parser = $self->{parser};
    if (!$parser) {
	    $parser = $self->new_parser($options);
	    $self->{parser} = $parser;
    }
    &App::sub_exit($parser) if ($App::trace);
	return($parser);
}

1;

__END__

=head1 SYNOPSIS

  NOTE: Everything after this is out of date and needs review.

  my $toolset = new XML::Toolset(type => 'LibXML');
  
  if ($toolset->validate($xml)) {
    print "Document is valid\n";
  } else {
    print "Document is invalid\n";
    my $message = $toolset->last_error()->{message};
    my $line = $toolset->last_error()->{line};
    my $column = $toolset->last_error()->{column};
    print "Error: $message at line $line, column $column\n";
  }

=head1 DESCRIPTION

XML::Toolset is a generic interface to different XML validation backends.
For a list of backend included with this distribution see the README.

If you want to write your own backends, the easiest way is probably to subclass
XML::Toolset::Base. Look at the existing backends for examples.

=head1 METHODS

=over

=item new(type => $type, options => \%options)

Returns a new XML::Toolset parser object of type $type. For available types see README or use 'BestAvailable' (see
L<BEST AVAILABLE>).

The optional argument "options" can be used to supply a set of key-value pairs to
the backend parser. See the documentation for individual backends for details
of these options.

=item validate_document($xml_string)

Attempts a validating parse of the XML document $xml_string and returns a true
value on success, or undef otherwise. If the parse fails, the error can be
inspected using C<last_error>.

Note that documents which don't specify a DTD or schema will be treated as
valid.

For DOM-based parsers, the DOM may be accessed by instantiating the backend module directly and calling the C<last_dom> method - consult the documentation of the specific backend modules.
Note that this isn't formally part of the XML::Toolset interface as non-DOM-based validators may added at some point.

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

=item type()

Returns the type of backend being used.

=item version()

Returns the version of the backend

=back

=head1 ERROR REPORTING

When a call to validate fails to parse the document, the error may be retrieved using last_error.

On errors not related to the XML parsing, methods will throw exceptions.
Wrap calls with eval to catch them.

=head1 BEST AVAILABLE

The BestAvailable backend type will check which backends are available and give
you the "best" of those. For the default order of preference see the README with this distribution, but this can be changed with the option
"prioritized_list".

If Xerces and LibXML are available the following code will give you a LibXML backend:

  my $toolset = new XML::Toolset(
      type => 'BestAvailable',
      options => { prioritized_list => [ qw( MSXML LibXML Xerces ) ] },
  );

=head1 KNOWN ISSUES

There is a bug in versions 1.57 and 1.58 of XML::LibXML that causes an issue
related to DTD loading. When a base parameter is used in conjunction with the
load_ext_dtd method the base parameter is ignored and the current directory
is used as the base parameter. In other words, when validating XML with LibXML
any base parameter option will be ignored, which may result in unexpected DTD
loading errors. This was reported as bug on November 30th 2005 and the bug
report can be viewed here http://rt.cpan.org/Public/Bug/Display.html?id=16213

=head1 AUTHORS

Stephen Adkins <spadkins@gmail.com>

Original Code (XML::Validate): Nathan Carr, Colin Robertson (see XML::Validate) E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) 2007 Stephen Adkins. XML-Toolset is derived from XML-Validate under the terms of the GNU GPL.
(c) 2005 BBC. XML-Toolset is derived from XML-Validate. XML-Validate is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
