#!/usr/bin/perl

use strict;
use warnings;

use XML::LibXML;

use Getopt::Long;
use Pod::Usage;

sub _esc
{
    my $s = shift;

    $s =~ s{&}{&amp;}g;
    $s =~ s{<}{&lt;}g;
    $s =~ s{>}{&gt;}g;

    $s =~ s{^[ \t]+}{}gms;
    $s =~ s{[ \t]+$}{}gms;

    return $s;
}

sub _esc_for_attr
{
    my $s = shift;

    my $ret = _esc($s);

    $ret =~ s{"}{&quot;};

    return $ret;
}


my $xml_uri = q{http://www.w3.org/XML/1998/namespace};
my $xpc = XML::LibXML::XPathContext->new();
# $xpc->registerNs('x', q{http://www.w3.org/1999/xhtml});
$xpc->registerNs('db', q{http://docbook.org/ns/docbook});
$xpc->registerNs('xlink', q{http://www.w3.org/1999/xlink});
$xpc->registerNs('xml', $xml_uri);

my $parser = XML::LibXML->new();

$parser->load_ext_dtd(0);

my $output_file;
my $help = 0;
my $man = 0;
my $ret = GetOptions(
    "o|output=s" => \$output_file,
    "help|h" => \$help,
    "man" => \$man,
);

if (!defined($output_file))
{
    die "Unspecified output file. Type --help for more information.\n";
}

if (!$ret)
{
    pod2usage(2);
}
if ($help)
{
    pod2usage(1);
}
if ($man)
{
    pod2usage(-exitstatus => 0, -verbose => 2)
}

my $input_file = shift(@ARGV);

if (!defined($input_file))
{
    die "Unspecified input file. Type --help for more information.\n";
}

my $doc = $parser->parse_file($input_file);

my ($main_title) = $xpc->findnodes(q{/db:article/db:info/db:title}, $doc);
my $main_title_text = $main_title->textContent();
my ($main_article) = $xpc->findnodes(q{/db:article}, $doc);
my $main_id_text = $main_article->getAttributeNS($xml_uri, "id");


my @sections = $xpc->findnodes(q{/db:article/db:section}, $doc);

sub _out_section
{
    my $sect_elem = shift;

    my $id = $sect_elem->getAttributeNS($xml_uri, "id");

    my ($title_elem) = $xpc->findnodes(q{./db:info/db:title}, $sect_elem);

    my $title_text = $title_elem->textContent();

    my @paras = $xpc->findnodes(q{./db:para}, $sect_elem);

    my @subs = $xpc->findnodes(q{./db:section}, $sect_elem);

    return
          qq{<s id="} . _esc_for_attr($id) . qq{">\n\n}
        . qq{<title>} . _esc($title_text) . qq{</title>\n\n}
        .  join("\n\n", map { _esc($_->textContent()) } @paras)
        . join("\n\n", map { _out_section($_) } @subs)
        . qq{</s>\n\n}
        ;
}

my $total =
      qq{<body id="} . _esc_for_attr($main_id_text) . qq{">\n\n}
    . qq{<title>} . _esc($main_title_text) . qq{</title>\n\n}
    . join("\n\n", map { _out_section($_) } @sections)
    . qq{</body>\n\n}
    ;

open my $out_fh, ">", $output_file
    or die "Could not open '$output_file' for output!";
binmode $out_fh, ":encoding(utf-8)";
print {$out_fh} $total;
close($out_fh);


__END__

=head1 NAME

docbook-to-fiction-xml-txt.pl - convert a subset of DocBook/XML to Fiction-Text.

=head1 SYNOPSIS

    # To render input.xml file into XHTML
    perl docbook-to-fiction-xml-txt.pl -o story.fiction.txt story.docbook.xml

=head1 DESCRIPTION

This is a script (partial, hacky and incomplete) to convert a
subset of DocBook/XML into Fiction-Text. (see L<XML::Grammar::Fiction> ).
In turn Fiction-Text can be converted to Fiction-XML , XHTML and DocBook/XML.

=head1 USAGE

The basic invocation of docmake is:

    docmake -o [output.fiction.txt] input.docbook.xml

B<--output> is a verbose alternative to B<-o>.

=head2 FLAGS

The available flags are:

=over 4

=item * -o OUTPUT_PATH ; --output OUTPUT_PATH

Put the result in B<OUTPUT_PATH> .

=back

=head2 EXAMPLES

There are some examples for sample invocation in the Synopsis.

=head1 SUPPORT

You can look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Fiction/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML::Grammar::Fiction>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML::Grammar::Fiction>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML::Grammar::Fiction>

=back

=head1 SEE ALSO

=over 4

=item * DocBook on the Wikipedia - L<http://en.wikipedia.org/wiki/DocBook>

=item * DocBook/XSL - The Complete Guide - L<http://www.sagehill.net/docbookxsl/>

=item * The DocBook Homepage - L<http://www.docbook.org/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Shlomi Fish.

This program is released under the following license: MIT/X11 License.
( L<http://www.opensource.org/licenses/mit-license.php> ).

=head2 LICENSE

Copyright (c) 2009 Shlomi Fish

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Shlomi Fish , L<http://www.shlomifish.org/> .

=cut
