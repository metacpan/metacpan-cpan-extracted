#!/usr/bin/perl -w

use strict;

use Getopt::Std;
use Pod::Usage;
use IO::File;
use XML::SAX::Expat;
use XML::SAX::Writer;
use XML::Handler::Dtd2DocBook;

my %opts;
getopts('CDdHhMvl:p:t:o:x:Z', \%opts)
		or pod2usage(-verbose => 0);

if ($opts{h}) {
	pod2usage(-verbose => 0);
}

if ($opts{v}) {
	print "$0\n";
	print "XML::Handler::Dtd2DocBook Version $XML::Handler::Dtd2DocBook::VERSION\n";
	exit(0);
}

my $file = $ARGV[0];
die "No input file\n"
		unless (defined $file);
warn "Don't use directly a DTD file (see the embedded pod or the README).\n"
		if ($file =~ /\.dtd$/i);
my $io = new IO::File($file,"r");
die "Can't open $file ($!)\n"
		unless (defined $io);

if (exists $opts{d}) {
	if (exists $opts{o}) {
		my $outfile = $opts{o};
		open STDOUT, "> $outfile"
				or die "can't open $outfile ($!).\n";
	}
	my $handler = new XML::SAX::Writer(Writer => 'DtdWriter', Output => \*STDOUT);
	my $parser = new XML::SAX::Expat(Handler => $handler);
	$parser->set_feature("http://xml.org/sax/features/external-general-entities", 1);
	$parser->parse(Source => {ByteStream => $io});
} else {
	my $handler = new XML::Handler::Dtd2DocBook();
	my $parser = new XML::SAX::Expat(Handler => $handler);
	$parser->set_feature("http://xml.org/sax/features/external-general-entities", 1);
	my $doc = $parser->parse(Source => {ByteStream => $io});

	my $outfile;
	if (exists $opts{o}) {
		$outfile = $opts{o};
	} else {
		my $root = $doc->{root_name};
		$root =~ s/[:\.\-]/_/g;
		$outfile = "dtd_" . $root;
	}

	my @examples = ();
	@examples = split /\s+/, $opts{x} if (exists $opts{x});

	$doc->GenerateDocBook(
			outfile			=> $outfile,
			title			=> $opts{t},
			examples		=> \@examples,
			flag_comment	=> !exists($opts{C}),
			flag_date		=> !exists($opts{D}),
			flag_href		=> exists($opts{H}),
			flag_multi		=> exists($opts{M}),
			flag_zombi		=> exists($opts{Z}),
			language		=> $opts{l},
			path_tmpl		=> $opts{p}
	);
}

package DtdWriter;

use base qw(XML::SAX::Writer::XML);

sub start_element {}
sub end_element {}
sub characters {}
sub processing_instruction {}
sub ignorable_whitespace {}
sub comment {}
sub start_cdata {}
sub end_cdata {}
sub start_entity {}
sub end_entity {}
sub xml_decl {}

sub start_dtd {
    my $self = shift;

    $self->{BufferDTD} = '';
}

sub end_dtd {
    my $self = shift;

    my $dtd = $self->{BufferDTD};
    $dtd = $self->{Encoder}->convert($dtd);
    $self->{Consumer}->output($dtd);
    $self->{BufferDTD} = '';
}

__END__

=head1 NAME

dtd2db - Generate a DocBook documentation from a DTD

=head1 SYNOPSIS

dtd2db [B<-d>] [B<-C> | B<-M>] [B<-HZ>] [B<-o> I<filename>] [B<-t> I<title>] [B<-x> 'I<example1.xml> I<example2.xml> ...'] [B<-l> I<language> | B<-p> I<path>] I<file.xml>

=head1 OPTIONS

=over 8

=item -C

Suppress all comments.

=item -D

Suppress date generation.

=item -d

Generate a clean DTD (without comment).

=item -H

Disable generation of links in comments.

=item -h

Display help.

=item -l

Specify the language of templates ('en' is the default).

=item -M

Suppress multi comments, preserve the last.

=item -o

Specify the output.

=item -p

Specify the path of templates.

=item -t

Specify the title of the DocBook files.

=item -v

Display Version.

=item -x

Include a list of XML files as examples.

=item -Z

Delete zombi element (e.g. without parent).

=back

=head1 DESCRIPTION

B<dtd2db> is a front-end for XML::Handler::Dtd2DocBook and its subclasses. It uses them
to generate XML DocBook documentation from DTD source.

Because it uses XML::Parser and an external DTD is not a valid XML document, the input
source must be an XML document with an internal DTD or an XML document that refers to
an external DTD.

The goal of this tool is to increase the level of documentation in DTD and to supply
a more readable format for DTD.

I<It is a tool for DTD users, not for writer.>

All comments before a declaration are captured.

All entity references inside attribute values are expanded.

This tool needs XML::SAX::Base, XML::SAX::Exception, XML::SAX::Expat,
XML::Parser, HTML::Template modules and XML::Handler::Dtd2Html.

=head2 Comments

XML files (and DTD) can include comments. The XML syntax is :

 <!-- comments -->

All comments before a declaration are captured (except with -M option).
Each comment generates its own paragraph E<lt>paraE<gt>.

=head2 dtd2db Tags

B<dtd2db> parses tags that are recognized when they are embedded
within an XML comment. These doc tags enable you to autogenerate a
complete, well-formatted document from your XML source. The tags start with
an @. A tag with two @ forces a link generation if the option -H is set.

Tags must start at the beginning of a line.

The special tag @BRIEF puts its value in 'Name' section.

The special tag @INCLUDE allows inclusion of the content of an external file.

 <!--
   comments
   @Version : 1.0
   @INCLUDE : description.txt
   @@See Also : REC-xml
 -->

The special tag @HIDDEN don't put the data in the documentation.

The special tag @TITLE before <!DOCTYPE> has the same effect as the option -t.

The special tag @SAMPLE allows inclusion of a XML fragment from an external file.

 <!--
   comments
   @SAMPLE ex2 : ex2.xml
 -->

The special tags are case insensitive.

=head2 generated files

B<dtd2db> generates a collection of files. Two files need attention.

=over 8

=item filename.xml

This is the DocBook entry point. It could be use as example for your own need :

=item filename.custom.ent

This file concentrates all textual descriptions as entities.
These entities are initialized by DTD comments if exists.

But this file could be manually modified after generation.

So unlike with B<dtd2html>, adding comments directly in the DTD is not mandatory.

=back

=head2 DocBook transformations

These transformation needs :

=over 8

=item DocBook XML DTD 4.2

E<lt>http://www.oasis-open.org/docbook/xml/E<gt>

=item DocBook XSL Stylesheets

E<lt>http://docbook.sourceforge.net/projects/xsl/E<gt>

=item xsltproc

E<lt>http://xmlsoft.org/XSLT/E<gt>

=item FOP

E<lt> http://xml.apache.org/fop/E<gt>

=back

For example :

 dtd2db.pl -o ppd -x sample.ppd entry.ppd
 xsltproc -o ppd.html --novalid \some-where\docbook-xsl\xhtml\docbook.xsl ppd.xml

 xsltproc --novalid \some-where\docbook-xsl\xhtml\chunk.xsl ppd.xml

 xsltproc --novalid \some-where\docbook-xsl\htmlhelp\htmlhelp.xsl ppd.xml
 hhc htmlhelp.hhp

 xsltproc -o ppd.fo --novalid \some-where\docbook-xsl\fo\docbook.xsl ppd.xml
 fop -fo ppd.fo -pdf ppd.pdf

=head2 HTML Templates

XML design and Perl programming are decoupling.
And a language switch option is available.

So, translation of the templates are welcome.

=head1 SEE ALSO

XML::Handler::Dtd2Html , dtd2html

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=head1 COPYRIGHT

(c) 2003 Francois PERRAD, France. All rights reserved.

This program is distributed under the Artistic License.

=cut
