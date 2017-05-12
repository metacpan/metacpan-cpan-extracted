###############################################################################
#
# This file copyright (c) 2008 by Randy J. Ray, all rights reserved.
#
# See LICENSE in the documentation for redistribution terms.
#
###############################################################################
#
#   $Id: XML.pm 9 2008-10-22 09:28:28Z rjray $
#
#   Description:
#
#   Functions:      is_valid_against
#                   is_valid_against_relaxng
#                   is_valid_against_rng
#                   relaxng_ok
#                   is_valid_against_xmlschema
#                   is_valid_against_xsd
#                   xmlschema_ok
#                   is_valid_against_sgmldtd
#                   is_valid_against_dtd
#                   sgmldtd_ok
#                   is_well_formed_xml
#                   xml_parses_ok
#
#   Libraries:      Test::Builder::Module
#                   XML::LibXML
#
#   Global Consts:  $VERSION
#
###############################################################################

package Test::Formats::XML;

use 5.008;
use strict;
use warnings;
use subs qw(is_valid_against
            is_valid_against_relaxng    is_valid_against_rng    relaxng_ok
            is_valid_against_xmlschema  is_valid_against_xsd    xmlschema_ok
            is_valid_against_sgmldtd    is_valid_against_dtd    sgmldtd_ok
            is_well_formed_xml          xml_parses_ok);
use base 'Test::Builder::Module';

use XML::LibXML;

our @EXPORT = qw(is_valid_against_relaxng   is_valid_against_rng    relaxng_ok
                 is_valid_against_xmlschema is_valid_against_xsd    xmlschema_ok
                 is_valid_against_sgmldtd   is_valid_against_dtd    sgmldtd_ok
                 is_well_formed_xml         xml_parses_ok);

our $VERSION = '0.12';

###############################################################################
#
#   Sub Name:       is_valid_against
#
#   Description:    This is the back-end that all of the other test routines
#                   actually use. It assumes that the first argument has
#                   already been converted to a XML::LibXML::{Dtd,Schema,etc.}
#                   object at this point, but the derivation of whether the
#                   target argument is a string, file, etc. is centralized
#                   here.
#
#   Arguments:      NAME        IN/OUT  TYPE    DESCRIPTION
#                   $document   in      varies  The XML content to validate--
#                                                 may be a string, filehandle,
#                                                 etc.
#                   $schema     in      ref     An object from one of the
#                                                 ::Dtd, ::Schema or ::RelaxNG
#                                                 validator classes
#                   $name       in      scalar  If passed, this is the "name"
#                                                 for the test, the text that
#                                                 is printed in the TAP stream
#
#   Returns:        The return value of $TESTBUILDER->ok()
#
###############################################################################
sub is_valid_against
{
    my ($document, $schema, $name) = @_;
    my $TESTBUILDER = __PACKAGE__->builder;
    my $is_valid = 0;
    my $dom;

    # If there was some sort of parse-level error creating the validator
    # object, we'll have gotten undef for $schema. We could put this test
    # in each of the three type-specific functions, but the test itself is
    # identical so it might as well just be here:
    if (! defined($schema))
    {
        return $TESTBUILDER->ok(0, $name) || $TESTBUILDER->diag($@);
    }

    # Try to get a DOM object out of $document, by hook or by crook:
    my $parser = XML::LibXML->new();
    if ($TESTBUILDER->is_fh($document))
    {
        # Anything that looks like a file-handle gets treated as such
        eval { $dom = $parser->parse_fh($document); };
    }
    elsif (ref($document) eq 'XML::LibXML::Document')
    {
        # This one is a gimme... if they were kind-enough to pre-parse it
        $dom = $document;
    }
    elsif (ref($document) eq 'SCALAR')
    {
        # A scalar-ref is presumed to be the XML text passed by reference
        eval { $dom = $parser->parse_string($$document); };
    }
    elsif ($document =~ /<\?xml|<!DOCTYPE/)
    {
        # If the text looks like XML (has either a declarative PI or a DOCTYPE
        # declaration), assume that it is directly-passed-in XML content
        eval { $dom = $parser->parse_string($document); };
    }
    else
    {
        # Failing any of the previous tests, assume that it is a filename
        eval { $dom = $parser->parse_file($document); };
    }

    # Skip the actual testing if whichever parser-call above ended up being
    # called set an exception in $@:
    unless ($@)
    {
        # The XML::LibXML::Schema and XML::LibXML::RelaxNG classes are both
        # validators, and have the same interface for the part I care about--
        # a method validate() that takes a DOM object (the result of a parse)
        # and dies if the document doesn't validate. Alas, the XML::LibXML::Dtd
        # class *doesn't* follow this convention, so I have to special case
        # it.
        if ($schema->isa('XML::LibXML::Dtd'))
        {
            # If we have a DTD-derived object, we use the validate() method
            # on the $dom value itself and pass the compiled DTD as an
            # argument. The other two do this the other way around...
            eval { $dom->validate($schema); };
        }
        elsif ($schema->isa('XML::LibXML::RelaxNG') or
               $schema->isa('XML::LibXML::Schema'))
        {
            eval { $schema->validate($dom); };
        }
        else
        {
            # Might be over-loading the use of this function, so I can't be
            # certain that it won't get called with something in $schema that
            # doesn't match either of the above tests.
            $TESTBUILDER->ok(0, $name);
            $TESTBUILDER->
                diag("Argument '$schema' not valid for is_valid_against()");
            return 0;
        }

        # If validation failed, $@ was set with some explanation. We'll use it
        # below in a chain-call that includes diag(), but what matters here is
        # setting $is_valid to a true value if $@ is *not* set.
        $is_valid = ($@) ? 0 : 1;
    }

    # Whatever we ended up with as "$is_valid" is what ok() gets to use
    $TESTBUILDER->ok($is_valid, $name) || $TESTBUILDER->diag($@);
}

###############################################################################
#
#   Sub Name:       is_valid_against_relaxng
#
#   Description:    Test the input against a RelaxNG schema. The first argument
#                   is either a compiled XML::LibXML::RelaxNG object, the text
#                   of a schema or a filename. Convert the argument to a
#                   compiled schema object (if necessary) and filter through
#                   to is_valid_against() with the other arguments. We leave
#                   the evaluation/normalization of the $document argument for
#                   that routine, since that part is common to all of these
#                   type-specific tester-routines.
#
#   Arguments:      NAME        IN/OUT  TYPE    DESCRIPTION
#                   $document   in      varies  The document/text to test
#                   $schema     in      varies  The schema (RelaxNG) to test
#                                                 $document against
#                   $name       in      scalar  If passed, the "name" or label
#                                                 for the test in the TAP
#                                                 output stream
#
#   Returns:        return value from is_valid_against()
#
###############################################################################
sub is_valid_against_relaxng
{
    my ($document, $schema, $name) = @_;
    my $TESTBUILDER = __PACKAGE__->builder;
    my $dom_schema;

    if (ref($schema) eq 'XML::LibXML::RelaxNG')
    {
        # They passed in an already-compiled object
        $dom_schema = $schema;
    }
    elsif ($TESTBUILDER->is_fh($schema))
    {
        # The XML::LibXML::RelaxNG class cannot currently parse directly from a
        # filehandle, so try calling new(string => ...) on the join'd contents
        # of the handle
        eval {
            $dom_schema =
                XML::LibXML::RelaxNG->new(string => join('', <$schema>));
        };
    }
    elsif ($schema =~ /<(?:[\w\.]+:)?grammar/ or
           $schema =~ m|http://relaxng\.org/ns/structure/1\.0| or
           $schema =~ m|http://relaxng\.org/ns/annotation/1\.0|)
    {
        # It appears to be a schema contained in the string/scalar... attempt
        # to parse it
        eval { $dom_schema = XML::LibXML::RelaxNG->new(string => $schema); };
    }
    elsif (ref($schema) eq 'SCALAR')
    {
        # Assume that a scalar reference is the text of a schema passed in by
        # reference to save stack-space
        eval { $dom_schema = XML::LibXML::RelaxNG->new(string => $$schema); };
    }
    elsif (! ref($schema))
    {
        # If it isn't a reference but didn't match the pattern above, try using
        # it as a file-name
        eval { $dom_schema = XML::LibXML::RelaxNG->new(location => $schema); };
    }
    else
    {
        # Can't figure out what it's supposed to be, so just fail the test
        # with a hopefully-helpful diagnostic
        return $TESTBUILDER->ok(0, $name) ||
            $TESTBUILDER->diag("Cannot deduce how to turn '$schema' into a " .
                               'XML::LibXML::RelaxNG instance');
    }

    is_valid_against($document, $dom_schema, $name);
}

# Semantic-sugar alias for the above:
*relaxng_ok = *is_valid_against_rng = \&is_valid_against_relaxng;

###############################################################################
#
#   Sub Name:       is_valid_against_xmlschema
#
#   Description:    Test the input against an XML Schema. The first argument
#                   is either a compiled XML::LibXML::Schema object, the text
#                   of a schema or a filename. Convert the argument to a
#                   compiled schema object (if necessary) and filter through
#                   to is_valid_against() with the other arguments. We leave
#                   the evaluation/normalization of the $document argument for
#                   that routine, since that part is common to all of these
#                   type-specific tester-routines.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $document   in      varies  The document/text to test
#                   $schema     in      varies  The schema (XML Schema) to test
#                                                 $document against
#                   $name       in      scalar  If passed, the "name" or label
#                                                 for the test in the TAP
#                                                 output stream
#
#   Returns:        return value from is_valid_against()
#
###############################################################################
sub is_valid_against_xmlschema
{
    my ($document, $schema, $name) = @_;
    my $TESTBUILDER = __PACKAGE__->builder;
    my $dom_schema;

    if (ref($schema) eq 'XML::LibXML::Schema')
    {
        # They passed in an already-compiled object
        $dom_schema = $schema;
    }
    elsif ($TESTBUILDER->is_fh($schema))
    {
        # The XML::LibXML::Schema class cannot currently parse directly from a
        # filehandle, so try calling new(string => ...) on the join'd contents
        # of the handle
        eval {
            $dom_schema =
                XML::LibXML::Schema->new(string => join('', <$schema>));
        };
    }
    elsif ($schema =~ /<(?:[\w\.]+:)?schema/ or
           $schema =~ m|http://www\.w3\.org/2001/XMLSchema|)
    {
        # It appears to be a schema contained in the string/scalar... attempt
        # to parse it
        eval { $dom_schema = XML::LibXML::Schema->new(string => $schema); };
    }
    elsif (ref($schema) eq 'SCALAR')
    {
        # Assume that a scalar reference is the text of a schema passed in by
        # reference to save stack-space
        eval { $dom_schema = XML::LibXML::Schema->new(string => $$schema); };
    }
    elsif (! ref($schema))
    {
        # If it isn't a reference but didn't match the pattern above, try using
        # it as a file-name
        eval { $dom_schema = XML::LibXML::Schema->new(location => $schema); };
    }
    else
    {
        # Can't figure out what it's supposed to be, so just fail the test
        # with a hopefully-helpful diagnostic
        return $TESTBUILDER->ok(0, $name) ||
            $TESTBUILDER->diag("Cannot deduce how to turn '$schema' into a " .
                               'XML::LibXML::Schema instance');
    }

    is_valid_against($document, $dom_schema, $name);
}

# Semantic-sugar alias for the above:
*xmlschema_ok = *is_valid_against_xsd = \&is_valid_against_xmlschema;

###############################################################################
#
#   Sub Name:       is_valid_against_sgmldtd
#
#   Description:    Test the input against a SGML DTD. The first argument
#                   is either a compiled XML::LibXML::Dtd object, the text
#                   of a DTD or a filename. Convert the argument to a
#                   compiled object (if necessary) and filter through to
#                   is_valid_against() with the other arguments. We leave
#                   the evaluation/normalization of the $document argument for
#                   that routine, since that part is common to all of these
#                   type-specific tester-routines.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $document   in      varies  The document/text to test
#                   $schema     in      varies  The schema (SGML DTD) to test
#                                                 $document against
#                   $name       in      scalar  If passed, the "name" or label
#                                                 for the test in the TAP
#                                                 output stream
#
#   Returns:        return value from is_valid_against()
#
###############################################################################
sub is_valid_against_sgmldtd
{
    my ($document, $schema, $name) = @_;
    my $TESTBUILDER = __PACKAGE__->builder;
    my $dom_schema;

    if (ref($schema) eq 'XML::LibXML::Dtd')
    {
        # They passed in an already-compiled object
        $dom_schema = $schema;
    }
    elsif ($TESTBUILDER->is_fh($schema))
    {
        # The XML::LibXML::Dtd class cannot currently parse directly from a
        # filehandle, so try calling parse_string() on the join'd contents of
        # the handle
        eval {
            $dom_schema = XML::LibXML::Dtd->parse_string(join('', <$schema>));
        };
    }
    elsif ($schema =~ /!ENTITY|!ELEMENT|!ATTLIST/)
    {
        # It appears to be a DTD contained in the string/scalar... attempt to
        # parse it
        eval { $dom_schema = XML::LibXML::Dtd->parse_string($schema); };
    }
    elsif (ref($schema) eq 'SCALAR')
    {
        # Assume that a scalar reference is the text of a DTD passed in by
        # reference to save stack-space
        eval { $dom_schema = XML::LibXML::Dtd->parse_string($$schema); };
    }
    elsif (! ref($schema))
    {
        # If it isn't a reference but didn't match the pattern above, try using
        # it as a file-name
        eval { $dom_schema = XML::LibXML::Dtd->new('', $schema); };
    }
    else
    {
        # Can't figure out what it's supposed to be, so just fail the test
        # with a hopefully-helpful diagnostic
        return $TESTBUILDER->ok(0, $name) ||
            $TESTBUILDER->diag("Cannot deduce how to turn '$schema' into a " .
                               'XML::LibXML::Dtd instance');
    }

    is_valid_against($document, $dom_schema, $name);
}
# Semantic-sugar alias for the above:
*sgmldtd_ok = *is_valid_against_dtd = \&is_valid_against_sgmldtd;

###############################################################################
#
#   Sub Name:       is_well_formed_xml
#
#   Description:    Test whether the content passed in parses as XML without
#                   errors. Makes no effort to validate, only parse.
#
#   Arguments:      NAME        IN/OUT  TYPE    DESCRIPTION
#                   $document   in      varies  The document/text to test
#                   $name       in      scalar  If passed, the "name" or label
#                                                 for the test in the TAP
#                                                 output stream
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub is_well_formed_xml
{
    my ($document, $name) = @_;
    my $TESTBUILDER = __PACKAGE__->builder;
    my $is_valid = 0;
    my $dom;

    # Try to parse $document, by hook or by crook:
    my $parser = XML::LibXML->new();
    if ($TESTBUILDER->is_fh($document))
    {
        # Anything that looks like a file-handle gets treated as such
        eval { $dom = $parser->parse_fh($document); };
    }
    elsif (ref($document) eq 'SCALAR')
    {
        # A scalar-ref is presumed to be the XML text passed by reference
        eval { $dom = $parser->parse_string($$document); };
    }
    elsif ($document =~ /<\?xml|<!DOCTYPE/)
    {
        # If the text looks like XML (has either a declarative PI or a DOCTYPE
        # declaration), assume that it is directly-passed-in XML content
        eval { $dom = $parser->parse_string($document); };
    }
    else
    {
        # Failing any of the previous tests, assume that it is a filename
        eval { $dom = $parser->parse_file($document); };
    }

    $TESTBUILDER->ok(($@) ? 0 : 1, $name) || $TESTBUILDER->diag($@);
}
# Semantic-sugar alias for the above:
*xml_parses_ok = \&is_well_formed_xml;

1;

__END__

=head1 NAME

Test::Formats::XML - Test::Formats specialization that tests XML content

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

    use Test::Formats::XML;

    our $schema  = (<schema/*.xsd>)[0];
    our $relaxng = (<relaxng/*.rng>)[0];
    our $sgmldtd = (<dtd/*.dtd>)[0];

    our @schema_tests  = <schema/*.xml>;
    our @relaxng_tests = <relaxng/*.xml>;
    our @sgmldtd_tests = <dtd/*.xml>;

    plan tests => (1 + @schema + @relaxng + @sgmldtd);

    is_well_formed_xml($schema, "Test that the XML Schema parses");

    is_valid_against_xmlschema($schema, $_) for (@schema_tests);

    is_valid_against_relaxng($relaxng, $_)  for (@relaxng_tests);

    is_valid_against_sgmldtd($sgmldtd, $_)  for (@sgmldtd_tests);

=head1 DESCRIPTION

Test::Formats::XML is a C<specialization> module for Test::Formats that
provides test-functions for evaluating XML content against XML Schema, RelaxNG
Schema and Document Type Declarations (DTDs).

This module is built on the framework provided by Test::Builder (see
L<Test::Builder> and L<Test::More>), and works under the TAP-based
Test::Harness system. It can be used directly as the only testing module
a given suite uses, or it can be used in conjunction with other harness-friendly
modules.

The module uses the XML::LibXML module from CPAN, and provides the user
with simple-to-use wrappers around the various forms of validation provided
by XML::LibXML::Schema, XML::LibXML::RelaxNG and XML::LibXML::Dtd.

=head1 FUNCTIONS

This only covers the functions specific to this module. However, all
functionality provided by Test::Builder/Test::More is accessible
here, as well. See those modules for more information.

=head2 Parameters

All of the functions described in the next section take the same sequence of
parameters, with the same relevance. These are:

=over 4

=item $document

This argument represents the document being tested against the schema provided
in the first argument. There are several ways in which to pass this:

=over 8

=item pre-parsed XML document

If the user has pre-parsed the document, the resulting XML::LibXML::Document
object can be passed in as the parameter. This can be useful if the test suite
wishes to distinguish document well-formedness (the document is parseable
without errors) versus document validity (whether the parsed document conforms
to a given schema).

=item open filehandle

If the parameter passed in appears to be an open filehandle, it is passed to
the B<parse_fh()> method  of XML::LibXML in order to obtain a document object.

=item scalar reference

If the parameter is a scalar reference, it is assumed to be a reference to the
document in memory. The de-referenced scalar is passed to the C<parse_string>
method of a XML::LibXML object, to result in a document object.

=item string (scalar)

Lastly, if the value is a (non-reference) scalar, it is first examined to see
if it looks like an XML document. Regular expressions are used to see if the
content looks like XML. It will look for a C<DOCTYPE> declaration or an XML
document declaration (the initial C<< <?xml ...?> >> line that most XML
documents have), first. If neither of these are found, at least one XML tag
must be found. If not even this is found, the string is presumed to be a
filename and is passed to the C<parse_file> method of XML::LibXML. If the
string looks like XML content after all, it is passed to the C<parse_string>
method of that class.

=back

Any of the forms that have to directly handle the reading of a file and/or
parsing a document itself, are wrapped in C<eval> blocks to catch any fatal
errors. If such occur, the test reports a failure and the error is given as
diagnostic information for the test.

=item $schema

For all of the test routines, the first argument represents the schema being
used to validate the document (the second argument). What type of schema is
important to the function being called-- if you pass a DTD to the RelaxNG
test, it will not automatically re-route you to the DTD test. The value of
this argument may be any of the following:

=over 8

=item pre-parsed XML::LibXML::* object

The easiest form to deal with, of course, is when the user is generous-enough
to compile the schema themselves with the appropriate XML::LibXML::* class
and pass the resulting object. The object is then used directly. This also
saves slightly on processing and overhead time when you intend to use the
same schema for a large number of tests.

=item open filehandle

If the argument is a filehandle, the contents are read and the resulting
document parsed. None of the schema-related classes can (currently) take a
filehandle directly, so this is offered to the user as a matter of convenience.
If you are re-using the same file across multiple tests, you can use the
C<seek> command to move the filehandle back to the start of the file and
re-use the existing filehandle as well.

=item scalar reference

If the argument is a scalar reference, it is presumed to contain the text of
the schema and is passed to the parser as such.

=item string (scalar)

If the argument is a (non-reference) scalar, it is treated as a string. It is
first tested with some regular expressions to see if the content looks like a
schema of the given type. If it does not look like the text of a schema, it is
passed to the constructor method of the relevant schema-class as a location of
the schema. The particular XML::LibXML::* class will try to read it and
parse it into an object.

=back

Any of the forms that have to read and/or parse the schema text are wrapped in
C<eval> blocks. If they fail for any reason, the test reports a failure and
the text of the error is output as diagnostic information.

The tests done to match plain text data to one of the specific schema-types are
somewhat limited, and may not always be guaranteed to work. Generally, it is
best to only use the straight string parameter for filenames. If you have the
schema in string-form, consider passing it as a scalar reference.

=item $name

This argument is the only optional parameter of the three. If passed, it
should be a string identifying the test. It is displayed in the TAP output
stream, just as the C<name> parameter to more-familiar test functions (B<ok()>,
B<like()>, etc.) is used.

If C<$name> is not given, Test::Formats::XML will attempt to create a
reasonable test-name based on the type of the C<$document> and
C<$schema> parameters.

=back

=head2 Tests

The following test functions are provided. Each has one or more aliases to
allow the user to choose syntaxtic sugar that best fit their preferred
linguistic view of test-names:

=over 4

=item is_valid_against_relaxng($document, $schema, $name)

=item is_valid_against_rng($document, $schema, $name)

=item relaxng_ok($document, $schema, $name)

The first set test a document against a RelaxNG schema. For more on the
RelaxNG syntax, see L<http://relaxng.org/>.

=item is_valid_against_sgmldtd($document, $schema, $name)

=item is_valid_against_dtd($document, $schema, $name)

=item sgmldtd_ok($document, $schema, $name)

This set test a document against a DTD. The names are slightly misleading, as
both SGML and XML DTDs are supported by XML::LibXML::Dtd. There are some
minor syntactical differences between SGML DTDs and XML DTDs, but you can use
whichever is best for your needs.

=item is_valid_against_xmlschema($document, $schema, $name)

=item is_valid_against_xsd($document, $schema, $name)

=item xmlschema_ok($document, $schema, $name)

This set validate documents against XML Schemas. See
L<http://www.w3.org/TR/xmlschema-0/> and L<http://www.w3.org/TR/xmlschema-1/>
for more about using XML Schema to define document structure.

=item is_well_formed_xml($document, $name)

=item xml_parses_ok($document, $name)

This pair test that an XML document is C<well-formed>, which is to say that it
parses without errors. This is not the same as validation. A passing test here
says nothing about the validity of the XML content itself, only that all tags
are properly closed, etc. Note that these functions do not take a schema
argument, only the XML document and (optionally) the test name.

These tests are convenience, as the same basic functionality can be found in
other test-related modules on CPAN. However, as long as XML::LibXML is already
being used, there is no harm in making things easier for the user by providing
them here and cutting down on the list of dependencies.

=back

All of the tests capture any fatal errors thrown by the underlying
XML::LibXML classes used, and report them as diagnostic data to accompany
a failed test report. See the C<diag> method of Test::Builder for more
information.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-formats at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Formats>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Formats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Formats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Formats>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Formats>

=back

=head1 ACKNOWLEDGMENTS

The original idea for this stemmed from a blog post on L<http://use.perl.org>
by Curtis "Ovid" Poe. He proferred some sample code based on recent work he'd
done, that validated against a RelaxNG schema. I generalized it for all the
validation types that XML::LibXML offers, and expanded the idea to cover
more general cases of structured, formatted text.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Randy J. Ray, all rights reserved.

This module and the code within are released under the terms of the Artistic
License 2.0
(L<http://www.opensource.org/licenses/artistic-license-2.0.php>). This code
may be redistributed under either the Artistic License or the GNU Lesser
General Public License (LGPL) version 2.1
(L<http://www.opensource.org/licenses/lgpl-license.php>).

=head1 SEE ALSO

L<Test::Formats>, L<Test::More>, L<Test::Builder>, L<XML::LibXML::Schema>,
L<XML::LibXML::RelaxNG>, L<XML::LibXML::Dtd>

=head1 AUTHOR

Randy J. Ray, C<< <rjray at blackperl.com> >>
