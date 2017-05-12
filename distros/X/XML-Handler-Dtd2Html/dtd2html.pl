#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Std;
use Pod::Usage;
use IO::File;
use XML::SAX::Expat;
use XML::SAX::Writer;
use XML::Handler::Dtd2Html;

my %opts;
getopts('bCDdfHhMvl:p:s:t:o:x:Z', \%opts)
		or pod2usage(-verbose => 0);

if ($opts{h}) {
	pod2usage(-verbose => 0);
}

if ($opts{v}) {
	print "$0\n";
	print "XML::Handler::Dtd2Html Version $XML::Handler::Dtd2Html::VERSION\n";
	exit(0);
}

my $file = $ARGV[0];
die "No input file\n"
		unless (defined $file);
warn "Don't use directly a DTD file (see the embedded pod or the README).\n"
		if ($file =~ /\.dtd$/i);
my $io = IO::File->new($file,'r');
die "Can't open $file ($!)\n"
		unless (defined $io);

if (exists $opts{d}) {
	if (exists $opts{o}) {
		my $outfile = $opts{o};
		open STDOUT, '>', $outfile
				or die "can't open $outfile ($!).\n";
	}
	my $handler = XML::SAX::Writer->new(Writer => 'DtdWriter', Output => \*STDOUT);
	my $parser = XML::SAX::Expat->new(Handler => $handler);
	$parser->set_feature('http://xml.org/sax/features/external-general-entities', 1);
	$parser->parse(Source => {ByteStream => $io});
} else {
	my $handler = XML::Handler::Dtd2Html->new();
	my $parser = XML::SAX::Expat->new(Handler => $handler);
	$parser->set_feature('http://xml.org/sax/features/external-general-entities', 1);
	my $doc = $parser->parse(Source => {ByteStream => $io});

	my $outfile;
	if (exists $opts{o}) {
		$outfile = $opts{o};
	} else {
		my $root = $doc->{root_name};
		$root =~ s/[:\.\-]/_/g;
		$outfile = 'dtd_' . $root;
	}

	my @examples = ();
	@examples = split /\s+/, $opts{x} if (exists $opts{x});

	if      ($opts{b}) {
		bless($doc, 'XML::Handler::Dtd2Html::DocumentBook');
	} elsif ($opts{f}) {
		bless($doc, 'XML::Handler::Dtd2Html::DocumentFrame');
	}

	$doc->GenerateHTML(
			outfile			=> $outfile,
			title			=> $opts{t},
			css				=> $opts{s},
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
    return;
}

sub end_dtd {
    my $self = shift;

    my $dtd = $self->{BufferDTD};
    $dtd = $self->{Encoder}->convert($dtd);
    $self->{Consumer}->output($dtd);
    $self->{BufferDTD} = '';
    return;
}

__END__

=head1 NAME

dtd2html - Generate a HTML documentation from a DTD

=head1 SYNOPSIS

dtd2html [B<-b> | B<-f> | B<-d>] [B<-C> | B<-M>] [B<-HZ>] [B<-o> I<filename>] [B<-s> I<style>] [B<-t> I<title>] [B<-x> 'I<example1.xml> I<example2.xml> ...'] [B<-l> I<language> | B<-p> I<path>] I<file.xml>

=head1 OPTIONS

=over 8

=item -b

Enable the book mode generation.

=item -C

Suppress all comments.

=item -D

Suppress date generation.

=item -d

Generate a clean DTD (without comment).

=item -f

Enable the frame mode generation.

=item -H

Disable generation of href's in comments.

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

=item -s

Generate an external I<style>.css file.

=item -t

Specify the title of the HTML files.

=item -v

Display Version.

=item -x

Include a list of XML files as examples.

=item -Z

Delete zombi element (e.g. without parent).

=back

=head1 DESCRIPTION

B<dtd2html> is a front-end for XML::Handler::Dtd2Html and its subclasses. It uses them
to generate HTML documentation from DTD source.

Because it uses XML::Parser and an external DTD is not a valid XML document, the input
source must be an XML document with an internal DTD or an XML document that refers to
an external DTD.

The goal of this tool is to increase the level of documentation in DTD and to supply
a more readable format for DTD.

I<It is a tool for DTD users, not for writer.>

All comments before a declaration are captured.

All entity references inside attribute values are expanded.

This tool needs XML::SAX::Base, XML::SAX::Exception, XML::SAX::Expat, XML::Parser and HTML::Template modules.

=head2 Comments

XML files (and DTD) can include comments. The XML syntax is :

 <!-- comments -->

All comments before a declaration are captured (except with -M option).
Each comment generates its own paragraph E<lt>pE<gt>.

=head2 Standard HTML

You can embed standard HTML tags within a comment. However, don't use tags
heading tags like E<lt>h1E<gt> or E<lt>hrE<gt>. B<dtd2html> creates an entire
structured document and these structural tags interfere with formatting of
the generated document.

So, you must use entities &lt; &gt; &amp; within a comment.

=head2 dtd2html Tags

B<dtd2html> parses tags that are recognized when they are embedded
within an XML comment. These doc tags enable you to autogenerate a
complete, well-formatted document from your XML source. The tags start with
an @. A tag with two @ forces a link generation if the option -H is set.

Tags must start at the beginning of a line.

The special tag @BRIEF puts its value in 'Name' section (in book mode).

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

=head2 HTML Templates

Since version 0.30, HTML design and Perl programming are decoupling.
And a language switch option is available.

So, translation of the templates are welcome.

=head1 SEE ALSO

XML::Handler::Dtd2DocBook, dtd2db

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=head1 COPYRIGHT

(c) 2002-2003 Francois PERRAD, France. All rights reserved.

This program is distributed under the Artistic License.

=cut
