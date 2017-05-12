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
		$XML::Edifact::indent_join="\n";
		$XML::Edifact::indent_tab="\t";
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

XML::Edifact::read_edi_message($ARGV[0]);

my $out=new IO::File(">-");

XML::Edifact::make_xml_message($out);

$out->close();

XML::Edifact::close_dbm();

0;

=head1 NAME

edi2xml - translate UN/EDIFACT messages to XML

=head1 SYNOPSIS

edi2xml [B<-i>] [B<-x> extension] filename.edi > filename.xml

=head1 DESCRIPTION

edi2xml is able to translate into XML any UN/EDIFACT message
or message fragment that does not use code list extensions.

=over

=item B<-i>

Prior versions of edi2xml provided a form that was more human
readable. But the intends caused problems with stupid
non-validating XML parsers, so the default is now without
intends. If you want to view them, the B<-i> flag provides
the old style.


=item B<-x>

The 0.34 version provided an initial way to use namespace migration
for code list extensions. This way is still crude and not XML/RDF.
For patching an extension B<SDBM> into edi2xml, use the B<-x> switch
without the trailing B<.dir/.pag>.

=item filename.edi

Message fragments have to be preceded by an UNA Service advice String.
Messages may have an optional leading UNA, or may start with a UNB
Interchange Header, if the default Service advice String has been used.

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
0;
