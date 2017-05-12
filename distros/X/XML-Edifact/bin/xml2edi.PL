# -*- perl -*-

use strict;

my $script = <<'SCRIPT';
~startperl~

# 
# Copyright (c) 1998 Michael Koehne <kraehe@copyleft.de>
# 
# XML::Edifact is free software. You can redistribute and/or
# modify this copy under terms of GNU General Public License.

# -----------------------------------------------------------------------------

use XML::Edifact;
use IO::File;

XML::Edifact::open_dbm();

while ($ARGV[0] =~ /^-/) {
	if ($ARGV[0] eq "-i") {
		$XML::Edifact::advice_segment_terminator="\n";
		shift @ARGV;
	} elsif ($ARGV[0] eq "-x") {
		shift @ARGV;
		tie(%XML::Edifact::EXTEND, 'SDBM_File', "$ARGV[0]", O_RDONLY, 0777) || die "tie:".$!;
		$XML::Edifact::MESSAGE_NAMESPACE=$XML::Edifact::EXTEND{"edifact"};
		XML::Edifact::eval_xml_edifact_headers();
		shift @ARGV;
	} else {
		die "Usage: edi2xml [-i] [-x extensionfile ] edifactfile";
	}
}

XML::Edifact::read_xml_message($ARGV[0]);

my $xml=new IO::File(">-");
XML::Edifact::make_edi_message($xml);
$xml->close();

XML::Edifact::close_dbm();
0;

=head1 NAME

xml2edi - translate XML messages back to UN/EDIFACT

=head1 SYNOPSIS

xml2edi [B<-i>] [B<-x> extension] filename.xml > filename.edi

=head1 DESCRIPTION

xml2edi is able to translate those XML messages to XML, which
conforms to the semantic translation of UN/EDIFACT to XML. This
semantic translation is currently static-coded. And no external
entities are used. Version 0.5 will provide more freedom in XML
to UN/EDIFACT translation by using RDF for semantic mapping.

=over

=item B<-i>

When reading UN/EDIFACT on a screen, I prefer a newline as an
B<advice segment seperator>. Some UN/EDIFACT parsers may not
like this, so it's optional.

=item B<-x>

The 0.34 version provided an initial way to use namespace migration
for code list extensions. This way is still crude and not XML/RDF.
For patching an extension B<SDBM> into edi2xml, use the B<-x> switch
without the trailing B<.dir/.pag>.

=item filename.xml

XML files have to contain documents of B<namespace:message> type, where
namespace is either the default B<edifact> or matched by the extension
SDBM. Future versions from 0.7x up will focus on orders, invoices and
so on. Current translation is flat and ignores the B<TRED/EDMD> documents.

=back

=head1 BUGS

Most bugs might better be called B<not yet implemented>, e.g. missing
external RDF files, as can be seen in the Roadmap section of the
README file, but the existing code has certainly many others.
Drop me a note, if you find some misbehavior.
  
I call XML::Edifact an aproach towards XML/EDI as a prototype in
Perl. Nothing is carved in stone, but should be seen as painted
on wood with the coal from fire, intended to be thrown into the
fire to provide fuel for the release. So drop me a note, if you
think something should be changed.

=head1 SEE ALSO

L<XML::Edifact>
L<XML::Parser>.

For further study, browse at
F<http://www.unece.org/trade/>,
F<http://www.unece.org/trade/untdid/download/d99a.zip>,
F<http://www.w3.org/TR/REC-xml>,
F<http://www.xmledi.org/> and
F<http://www.xml-edifact.org/>.

=head1 AUTHOR

Kraehe@Copyleft.de - Michael Koehne - MK25-RIPE

SCRIPT

use Config;

my $file = $ARGV[0];

$script =~ s/\~(\w+)\~/$Config{$1}/eg;
if (!(open(FILE, ">$file"))  ||
    !(print FILE $script)  ||
    !(close(FILE))) {
    die "Error while writing $file: $!\n";
}
print "Extracted $file from ",__FILE__," with variable substitutions.\n";

# end
