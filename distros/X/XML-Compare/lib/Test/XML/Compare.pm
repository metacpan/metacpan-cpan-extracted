## ----------------------------------------------------------------------------
# Copyright (C) 2009 NZ Registry Services
## ----------------------------------------------------------------------------
package Test::XML::Compare;
$Test::XML::Compare::VERSION = '0.05';
use 5.006000;
use base 'Test::Builder::Module';
use strict;
use warnings;
use XML::LibXML;
use Test::Builder;
use XML::Compare;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    is_xml_same is_xml_different
);

my $TEST = Test::Builder->new();
my $PARSER = XML::LibXML->new();

my $has = {
    localname => {
        # not Comment, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Element' => 1,
    },
    namespaceURI => {
        # not Comment, Text, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Element' => 1,
    },
    attributes => {
        # not Attr, Comment, CDATASection
        'XML::LibXML::Element' => 1,
    },
    value => {
        # not Element, Comment, CDATASection
        'XML::LibXML::Attr' => 1,
        'XML::LibXML::Comment' => 1,
    },
    data => {
        # not Element, Attr
        'XML::LibXML::CDATASection' => 1,
        'XML::LibXML::Comment' => 1,
        'XML::LibXML::Text' => 1,
    },
};

sub import {
	my $class = shift @_;
	Test::XML::Compare->export_to_level(1, $class);
	$TEST->exported_to(caller);
	$TEST->plan(@_) if @_;
}

sub is_xml_same($$;$) {
	my ($xml1, $xml2, $msg) = @_;
    return $TEST->ok(XML::Compare::is_same($xml1, $xml2), $msg);
}

sub is_xml_different($$;$) {
	my ($xml1, $xml2, $msg) = @_;
    return $TEST->ok(XML::Compare::is_different($xml1, $xml2), $msg);
}

1;
__END__

=head1 NAME

Test::XML::Compare - Test if two XML documents semantically the same

=head1 SYNOPSIS

 use Test::XML::Compare tests => 2;

 my $xml1 = "<foo xmlns="urn:message"><bar baz="buzz">text</bar></foo>";
 my $xml2 = "<f:foo xmlns:f="urn:message"><f:bar baz="buzz">text</f:bar></f:foo>";
 my $xml3 = "<foo><bar baz="buzz">text</bar></foo>";

 # These will pass
 is_xml_same $xml1, $xml2;

 # These will fail
 is_xml_same $xml1, $xml3;
 is_xml_same $xml2, $xml3;

 # however, you can also check for failures, so these now succeed
 is_xml_different $xml1, $xml3;
 is_xml_different $xml2, $xml3;

 # ... and this fails
 is_xml_different $xml1, $xml2;

=head1 DESCRIPTION

This module allows you to test if two XML documents are semantically the
same. This also holds true if different prefixes are being used for the xmlns,
or if there is a default xmlns in place.

It uses XML::Compare to do all of it's checking.

=head1 SUBROUTINES

=over 4

=item is_xml_same $xml1, $xml2, $name;

Test passes if the XML string in C<$xml1> is semantically the same as the XML
string in C<$xml2>. Optionally name the test with C<$name>.

=item is_xml_different $xml1, $xml2, $name;

Test passes if the XML string in C<$xml1> is semantically different to the XML
string in C<$xml2>. Optionally name the test with C<$name>.

=back

=head1 EXPORTS

Everything in L<"SUBROUTINES"> by default, as expected.

=head1 SEE ALSO

L<Test::Builder>

L<XML::LibXML>

L<XML::Compare>

=head1 AUTHOR

Andrew Chilton, E<lt>andychilton@gmail.com<gt>, E<lt>andy@catalyst dot net dot nz<gt>

http://www.chilts.org/blog/

=head1 COPYRIGHT & LICENSE

This software development is sponsored and directed by New Zealand Registry
Services, http://www.nzrs.net.nz/

The work is being carried out by Catalyst IT, http://www.catalyst.net.nz/

Copyright (c) 2009, NZ Registry Services.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

=cut
