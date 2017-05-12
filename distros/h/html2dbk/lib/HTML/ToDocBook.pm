package HTML::ToDocBook;
use strict;
use warnings;

=head1 NAME

HTML::ToDocBook - Converts an XHTML file into DocBook.

=head1 VERSION

This describes version B<0.03> of HTML::ToDocBook.

=cut

our $VERSION = '0.0301';

=head1 SYNOPSIS

    use HTML::ToDocBook;

    my $obj = HTML::ToDocBook->new(%args);

    $obj->convert(infile=>$filename);

    # convert HTML file
    $obj->convert(infile=>$filename, html=>1);

=head1 DESCRIPTION

This module converts an XHTML file into DocBook format using both
heuristics and XSLT processing.  By default, this expects the input file to
be correct XHTML -- there are other programs such as html tidy
(http://tidy.sourceforge.net/) which can correct files for you; this does
not do that.

Note also this is very simple; it doesn't deal with things like
<div> or <span> which it has no way of guessing the meaning of.
(For some, however, if they have class names which match DocBook tags,
they will be turned into those tags)
This does not merge multiple XHTML files into a single document,
so this converts each XHTML file into a <chapter>, with each
header being a section (sect1 to sect5).  The <title> tag is used for
the chapter title.

There will likely to be validity errors, depending on how good the original
HTML was.  There may be broken links, <xref> elements that should be <link>s,
and overuse of <emphasis> and <emphasis role="bold">.

=cut

use Cwd 'abs_path';
use File::Basename;
use File::Spec;
use XML::LibXSLT;
use XML::LibXML;
use HTML::SimpleParse;

=head1 METHODS

=head2 new
    
    my $conv = HTML::ToDocBook->new();

    my $conv = HTML::ToDocBook->new(stylesheet=>$stylesheet);

Arguments:

=over

=item stylesheet

A replacement XSLT stylesheet to use for conversions instead of the
built-in one.  This can either be a file name or a string containing
the entire stylesheet.

=back

=cut

sub new {
    my $class = shift;
    my %parameters = @_;
    my $self = bless ({%parameters}, ref ($class) || $class);

    my $parser = XML::LibXML->new();
    my $xslt = XML::LibXSLT->new();

    $self->{_parser} = $parser;
    $self->{_xslt} = $xslt;

    if ($self->{stylesheet}
	and -f $self->{stylesheet})
    {
	my $fn = abs_path($self->{stylesheet});
	my $style_doc = $parser->parse_file($fn) 
	    or die "Could not parse $fn XSLT file";
	my $stylesheet = $xslt->parse_stylesheet($style_doc)
	    or die "Could not parse $fn stylesheet";
	$self->{_xslt_sheet} = $stylesheet;
    }
    elsif ($self->{stylesheet})
    {
	my $style_doc = $parser->parse_string($self->{stylesheet})
	    or die "Could not parse string XSLT";
	my $stylesheet = $xslt->parse_stylesheet($style_doc)
	    or die "Could not parse stylesheet";
	$self->{_xslt_sheet} = $stylesheet;
    }
    else
    {

	# build the parsed stylesheet from the DATA

	# This is stored in the DATA handle, after the __DATA__ at
	# the end of this file; but because the scripts may not just
	# create one instance of this object,
	# we have to remember the position of the DATA handle
	# and reset it after we've read from it, just in case
	# we have to read from it again.
	# This also means that we don't close it, either.  Hope that doesn't
	# cause a problem...

	my $curpos = tell(DATA);    # remember the __DATA__ position
	my $style_doc = $parser->parse_fh(\*DATA);
	# reset the data handle to the start, just in case
	seek(DATA, $curpos, 0);

	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	$self->{_xslt_sheet} = $stylesheet;
    }

    return ($self);
} # new

=head2 convert

    $obj->convert(infile=>$filename,
		html=>1);

Arguments:

=over

=item infile

The name of the file to convert.

=item html

Parse the input as HTML rather than XML.

=back

=cut

sub convert {
    my $self = shift;
    my %args = (
	html=>0,
	@_
    );
    my $filename = $args{infile};

    my ($basename,$path,$suffix) = fileparse($filename,qr{\.html?}i);
    my $outfile = File::Spec->catfile($path, "${basename}.xml");
    $outfile = '-' if ($filename eq '');

    # We need to read in the file first because we need to
    # pre-process it
    my $file_str;
    if ($filename eq '-') # read from STDIN
    {
	local $/;
	$file_str = <STDIN>;
    }
    else
    {
	local $/;
	my $fh;
	open ($fh, "<", $filename) or die "could not open $filename";
	$file_str = <$fh>;
	close $fh;
    }
    $file_str = $self->insert_sections($file_str);

    my $first_ss = $self->{_xslt_sheet};

    my $source = undef;
    my $result_str = '';
    if ($args{html})
    {
	$source = $self->{_parser}->parse_html_string($file_str);
    }
    else
    {
	$source = $self->{_parser}->parse_string($file_str);
    }
    undef $file_str;

    my %all_params = ();
    my $results = $first_ss->transform($source, %all_params);
    $result_str = $first_ss->output_string($results);

    # print the result
    my $outfh = undef;
    if ($outfile eq '-' or $outfile eq '')
    {
	$outfh = \*STDOUT;
    }
    else
    {
	open(OUT, ">", $outfile)
	    || die "Can't open $outfile for writing!";
	$outfh = \*OUT;
    }
    print $outfh $result_str;
    if ($outfile ne '-' and $outfile ne '')
    {
	close($outfh);
    }
    return $result_str;
} # convert

=head1 Private Methods

These are not guaranteed to be stable.

=head2 insert_sections

    $my str = $obj->insert_sections($string);

This inserts <div class="sectN"> tags to enclose all levels
of header.  These will then be picked up by the XSLT stylesheet
and converted into section tags.

=cut

sub insert_sections {
    my $self = shift;
    my $string = shift;
    my %args = (
	parse_type=>'xml',
	@_
    );

    my $hp = new HTML::SimpleParse();
    $hp->text($string);
    $hp->parse();

    my @newhtml = ();
    my @levels = ();
    my $tok;
    my @tree = $hp->tree();
    while (@tree)
    {
	$tok = shift @tree;
	if ($tok->{type} eq 'starttag'
	    and $tok->{content} =~ /^h(\d)/i)
	{
	    # we have a header
	    my $header_level = $1;
	    # if we had a previous header, then close its div
	    # if it is the same or higher
	    if (@levels)
	    {
		my $prev_level = $levels[$#levels];
		while ($prev_level > $header_level)
		{
		    pop @levels;
		    push @newhtml, "</div>\n";
		    $prev_level = $levels[$#levels];
		}
		if ($prev_level == $header_level)
		{
		    pop @levels;
		    push @newhtml, "</div>\n";
		}
	    }
	    # start a new div for the new header
	    push @newhtml, sprintf("\n<div class='sect%d'>\n", $header_level);
	    push @levels, $header_level;
	}
	elsif ($tok->{type} eq 'endtag'
	    and $tok->{content} =~ /^\/body/i)
	{
	    # we need to close any remaining open section divs
	    while (@levels)
	    {
		my $prev_level = pop @levels;
		push @newhtml, "</div>\n";
	    }
	}
	push @newhtml, $hp->execute($tok);
    } # go through all the tags

    return join('', @newhtml);
} # insert_sections

=head1 REQUIRES

    Cwd
    File::Basename
    File::Spec
    XML::LibXML
    XML::LibXSLT
    HTML::SimpleParse
    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}


=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.org/tools

=head1 COPYRIGHT AND LICENCE

XSLT stylesheet based on the one at http://wiki.docbook.org/topic/Html2DocBook
by Jeff Beal

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HTML::ToDocBook
#------------------------------------------------------------------------
#  The XSLT stylesheet!
#  The original stylesheet came from
#  http://wiki.docbook.org/topic/Html2DocBook
#
__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="xsl html">

<xsl:output method="xml" indent="yes"/>
<xsl:param name="filename"></xsl:param>
<xsl:param name="prefix">wb</xsl:param>
<xsl:param name="graphics_location">images/</xsl:param>

<!-- This needs to match elements with both the html: namespace
and without, because files parsed as HTML rather than XHTML
don't have the html: namespace in them, for whatever reason.
-->

<!-- Main block-level conversions -->
<xsl:template match="html:html|html">
 <xsl:apply-templates select="html:body|body"/>
</xsl:template>

<!-- This template converts each HTML file encountered into a DocBook
     chapter.  For a title, it selects the title, else the first h1 element -->
<xsl:template match="html:body|body">
 <chapter>
  <xsl:if test="$filename != ''">
   <xsl:attribute name="id">
    <xsl:value-of select="$prefix"/>
    <xsl:text>_</xsl:text>
    <xsl:value-of select="translate($filename,' ()','__')"/>
   </xsl:attribute>
  </xsl:if>
  <title>
   <xsl:value-of select="/html:html/html:head/html:title
			 |/html/head/title
                         |.//html:h1[1]
                         |.//html:h2[1]
                         |.//html:h3[1]"/>
  </title>
  <xsl:apply-templates select="*"/>
 </chapter>
</xsl:template>

<!-- Sections
These expect div class="sectN" tags
-->
<xsl:template match="html:div[@class='sect1']|div[@class='sect1']">
  <sect1>
    <xsl:apply-templates/>
  </sect1>
</xsl:template>
<xsl:template match="html:div[@class='sect2']|div[@class='sect2']">
  <sect2>
    <xsl:apply-templates/>
  </sect2>
</xsl:template>
<xsl:template match="html:div[@class='sect3']|div[@class='sect3']">
  <sect3>
    <xsl:apply-templates/>
  </sect3>
</xsl:template>
<xsl:template match="html:div[@class='sect4']|div[@class='sect4']">
  <sect4>
    <xsl:apply-templates/>
  </sect4>
</xsl:template>
<xsl:template match="html:div[@class='sect5']|div[@class='sect5']">
  <sect5>
    <xsl:apply-templates/>
  </sect5>
</xsl:template>
<xsl:template match="html:div[@class='section']|div[@class='section']">
  <section>
    <xsl:apply-templates/>
  </section>
</xsl:template>

<!-- This template matchs on HTML header items and makes them into
section title tags (the actual section stuff is dealt with
above)
It attempts to assign an ID to each sect by looking
for a named anchor as a child of the header or as the immediate preceding
or following sibling -->
<xsl:template match="html:h1|html:h2|html:h3|html:h4|html:h5|h1|h2|h3|h4|h5">
 <title>
  <xsl:choose>
   <xsl:when test="count(html:a/@name)">
    <xsl:attribute name="id">
     <xsl:value-of select="html:a/@name"/>
    </xsl:attribute>
   </xsl:when>
   <xsl:when test="count(a/@name)">
    <xsl:attribute name="id">
     <xsl:value-of select="a/@name"/>
    </xsl:attribute>
   </xsl:when>
   <xsl:when test="preceding-sibling::* = preceding-sibling::html:a[@name != '']">
    <xsl:attribute name="id">
    <xsl:value-of select="concat($prefix,preceding-sibling::html:a[1]/@name)"/>
    </xsl:attribute>
   </xsl:when>
   <xsl:when test="preceding-sibling::* = preceding-sibling::a[@name != '']">
    <xsl:attribute name="id">
    <xsl:value-of select="concat($prefix,preceding-sibling::a[1]/@name)"/>
    </xsl:attribute>
   </xsl:when>
   <xsl:when test="following-sibling::* = following-sibling::html:a[@name != '']">
    <xsl:attribute name="id">
    <xsl:value-of select="concat($prefix,following-sibling::html:a[1]/@name)"/>
    </xsl:attribute>
   </xsl:when>
   <xsl:when test="following-sibling::* = following-sibling::a[@name != '']">
    <xsl:attribute name="id">
    <xsl:value-of select="concat($prefix,following-sibling::a[1]/@name)"/>
    </xsl:attribute>
   </xsl:when>
  </xsl:choose>
  <xsl:apply-templates/>
 </title>
</xsl:template>

<!-- These templates check class names to see if they are DocBook
tag names.  This only does it for a few tags, though.
-->
<xsl:template match="html:span[@class='guilabel']|span[@class='guilabel']">
<guilabel>
  <xsl:apply-templates/>
</guilabel>
</xsl:template>
<xsl:template match="html:span[@class='guibutton']|span[@class='guibutton']">
<guibutton>
  <xsl:apply-templates/>
</guibutton>
</xsl:template>
<xsl:template match="html:span[@class='guimenu']|span[@class='guimenu']">
<guimenuitem>
  <xsl:apply-templates/>
</guimenuitem>
</xsl:template>
<xsl:template match="html:span[@class='guimenuitem']|span[@class='guimenuitem']">
<guimenuitem>
  <xsl:apply-templates/>
</guimenuitem>
</xsl:template>

<!-- These templates perform one-to-one conversions of HTML elements into
     DocBook elements -->
<xsl:template match="html:p|p">
<!-- if the paragraph has no text (perhaps only a child <img>), don't
     make it a para -->
 <xsl:choose>
  <xsl:when test="normalize-space(.) = ''">
   <xsl:apply-templates/>
  </xsl:when>
  <xsl:otherwise>
 <simpara>
  <xsl:apply-templates/>
 </simpara>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<xsl:template match="html:pre|pre">
 <programlisting>
  <xsl:apply-templates/>
 </programlisting>
</xsl:template>

<!-- Hyperlinks -->
<xsl:template match="html:a[contains(@href,'http://')]|a[contains(@href, 'http://')]" priority="1.5">
 <ulink>
  <xsl:attribute name="url">
   <xsl:value-of select="normalize-space(@href)"/>
  </xsl:attribute>
  <xsl:apply-templates/>
 </ulink>
</xsl:template>

<xsl:template match="html:a[contains(@href,'#')]|a[contains(@href, '#')]" priority="0.6">
 <xref>
  <xsl:attribute name="linkend">
   <xsl:call-template name="make_id">
    <xsl:with-param name="string" select="substring-after(@href,'#')"/>
   </xsl:call-template>
  </xsl:attribute>
 </xref>
</xsl:template>

<xsl:template match="html:a[@href != '']|a[@href != '']">
 <xref>
  <xsl:attribute name="linkend">
   <xsl:value-of select="$prefix"/>
   <xsl:text>_</xsl:text>
   <xsl:call-template name="make_id">
    <xsl:with-param name="string" select="@href"/>
   </xsl:call-template>
  </xsl:attribute>
 </xref>
</xsl:template>

<!-- Need to come up with good template for converting filenames into ID's -->
<xsl:template name="make_id">
 <xsl:param name="string" select="''"/>
 <xsl:variable name="fixedname">
  <xsl:call-template name="get_filename">
   <xsl:with-param name="path" select="translate($string,' \()','_/_')"/>
  </xsl:call-template>
 </xsl:variable>
 <xsl:choose>
  <xsl:when test="contains($fixedname,'.htm')">
   <xsl:value-of select="substring-before($fixedname,'.htm')"/>
  </xsl:when>
  <xsl:otherwise>
   <xsl:value-of select="$fixedname"/>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<xsl:template name="string.subst">
 <xsl:param name="string" select="''"/>
 <xsl:param name="substitute" select="''"/>
 <xsl:param name="with" select="''"/>
 <xsl:choose>
  <xsl:when test="contains($string,$substitute)">
   <xsl:variable name="pre" select="substring-before($string,$substitute)"/>
   <xsl:variable name="post" select="substring-after($string,$substitute)"/>
   <xsl:call-template name="string.subst">
    <xsl:with-param name="string" select="concat($pre,$with,$post)"/>
    <xsl:with-param name="substitute" select="$substitute"/>
    <xsl:with-param name="with" select="$with"/>
   </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
   <xsl:value-of select="$string"/>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<!-- Images -->
<!-- Images and image maps -->
<xsl:template match="html:img|img">
 <xsl:variable name="tag_name">
  <xsl:choose>
   <xsl:when test="boolean(parent::html:p) and
        boolean(normalize-space(parent::html:p/text()))">
    <xsl:text>inlinemediaobject</xsl:text>
   </xsl:when>
   <xsl:when test="boolean(parent::p) and
        boolean(normalize-space(parent::p/text()))">
    <xsl:text>inlinemediaobject</xsl:text>
   </xsl:when>
   <xsl:otherwise>mediaobject</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>
 <xsl:element name="{$tag_name}">
  <imageobject>
   <xsl:call-template name="process.image"/>
  </imageobject>
 </xsl:element>
</xsl:template>

<xsl:template name="process.image">
 <imagedata>
<xsl:attribute name="fileref">
 <xsl:call-template name="make_absolute">
  <xsl:with-param name="filename" select="@src"/>
 </xsl:call-template>
</xsl:attribute>
<xsl:if test="@height != ''">
 <xsl:attribute name="depth">
  <xsl:value-of select="@height"/>
 </xsl:attribute>
</xsl:if>
<xsl:if test="@width != ''">
 <xsl:attribute name="width">
  <xsl:value-of select="@width"/>
 </xsl:attribute>
</xsl:if>
 </imagedata>
</xsl:template>

<xsl:template name="make_absolute">
 <xsl:param name="filename"/>
 <xsl:variable name="name_only">
  <xsl:call-template name="get_filename">
   <xsl:with-param name="path" select="$filename"/>
  </xsl:call-template>
 </xsl:variable>
 <xsl:value-of select="$graphics_location"/><xsl:value-of select="$name_only"/>
</xsl:template>

<xsl:template match="html:ul[count(*) = 0]|ul[count(*) = 0]">
 <xsl:message>Matched</xsl:message>
 <blockquote>
  <xsl:apply-templates/>
 </blockquote>
</xsl:template>

<xsl:template name="get_filename">
 <xsl:param name="path"/>
 <xsl:choose>
  <xsl:when test="contains($path,'/')">
   <xsl:call-template name="get_filename">
    <xsl:with-param name="path" select="substring-after($path,'/')"/>
   </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
   <xsl:value-of select="$path"/>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<!-- LIST ELEMENTS -->
<xsl:template match="html:ul|ul">
 <itemizedlist>
  <xsl:apply-templates/>
 </itemizedlist>
</xsl:template>

<xsl:template match="html:ol|ol">
 <orderedlist>
  <xsl:apply-templates/>
 </orderedlist>
</xsl:template>

<!-- This template makes a DocBook variablelist out of an HTML definition list -->
<xsl:template match="html:dl|dl">
 <variablelist>
  <xsl:for-each select="html:dt|dt">
   <varlistentry>
    <term>
     <xsl:apply-templates/>
    </term>
    <listitem>
     <xsl:apply-templates select="following-sibling::html:dd[1]|following-sibling::dd[1]"/>
    </listitem>
   </varlistentry>
  </xsl:for-each>
 </variablelist>
</xsl:template>

<xsl:template match="html:dd|dd">
 <xsl:choose>
  <xsl:when test="boolean(html:p)">
   <xsl:apply-templates/>
  </xsl:when>
  <xsl:when test="boolean(p)">
   <xsl:apply-templates/>
  </xsl:when>
  <xsl:otherwise>
   <para>
    <xsl:apply-templates/>
   </para>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<xsl:template match="html:li|li">
 <listitem>
  <xsl:choose>
   <xsl:when test="count(html:p) = 0">
    <para>
     <xsl:apply-templates/>
    </para>
   </xsl:when>
   <xsl:when test="count(p) = 0">
    <para>
     <xsl:apply-templates/>
    </para>
   </xsl:when>
   <xsl:otherwise>
    <xsl:apply-templates/>
   </xsl:otherwise>
  </xsl:choose>
 </listitem>
</xsl:template>

<xsl:template match="*">
 <xsl:message>No template for <xsl:value-of select="name()"/><xsl:text> </xsl:text><xsl:value-of select="@class"/>
 </xsl:message>
 <xsl:apply-templates/>
</xsl:template>

<xsl:template match="@*">
 <xsl:message>No template for <xsl:value-of select="name()"/>
 </xsl:message>
 <xsl:apply-templates/>
</xsl:template>

<!-- inline formatting -->
<xsl:template match="html:b|html:strong|b|strong">
 <emphasis role="bold">
  <xsl:apply-templates/>
 </emphasis>
</xsl:template>
<xsl:template match="html:i|html:em|i|em">
 <emphasis>
  <xsl:apply-templates/>
 </emphasis>
</xsl:template>
<xsl:template match="html:u|u">
 <citetitle>
  <xsl:apply-templates/>
 </citetitle>
</xsl:template>

<!-- Ignored elements -->
<xsl:template match="html:hr|hr"/>
<xsl:template match="html:br|br"/>
<xsl:template match="html:p[normalize-space(.) = '' and count(*) = 0]"/>
<xsl:template match="p[normalize-space(.) = '' and count(*) = 0]"/>

<xsl:template match="text()">
 <xsl:choose>
  <xsl:when test="normalize-space(.) = ''"></xsl:when>
  <xsl:otherwise><xsl:copy/></xsl:otherwise>
 </xsl:choose>
</xsl:template>

<!-- Workbench Hacks -->
<xsl:template match="html:div[contains(@style,'margin-left: 2em')]|div[contains(@style,'margin-left: 2em')]">
 <blockquote><para>
  <xsl:apply-templates/></para>
 </blockquote>
</xsl:template>

<xsl:template match="html:a[@href != ''
                      and not(boolean(ancestor::html:p|ancestor::html:li))]
|a[@href != '' and not(boolean(ancestor::p|ancestor::li))]"
              priority="1">
 <para>
 <xref>
  <xsl:attribute name="linkend">
   <xsl:value-of select="$prefix"/>
   <xsl:text>_</xsl:text>
   <xsl:call-template name="make_id">
    <xsl:with-param name="string" select="@href"/>
   </xsl:call-template>
  </xsl:attribute>
 </xref>
 </para>
</xsl:template>

<xsl:template match="html:a[contains(@href,'#')
                    and not(boolean(ancestor::html:p|ancestor::html:li))]
|a[contains(@href,'#')
                    and not(boolean(ancestor::p|ancestor::li))]"
              priority="1.1">
 <para>
 <xref>
  <xsl:attribute name="linkend">
   <xsl:value-of select="$prefix"/>
   <xsl:text>_</xsl:text>
   <xsl:call-template name="make_id">
    <xsl:with-param name="string" select="substring-after(@href,'#')"/>
   </xsl:call-template>
  </xsl:attribute>
 </xref>
 </para>
</xsl:template>

<!-- ================================================================= -->
<!-- Table conversion -->
<xsl:template match="html:table|table">
 <xsl:variable name="column_count">
  <xsl:call-template name="count_columns">
   <xsl:with-param name="table" select="."/>
  </xsl:call-template>
 </xsl:variable>
 <informaltable>
  <tgroup>
   <xsl:attribute name="cols">
    <xsl:value-of select="$column_count"/>
   </xsl:attribute>
   <xsl:call-template name="generate-colspecs">
    <xsl:with-param name="count" select="$column_count"/>
   </xsl:call-template>
   <thead>
    <xsl:apply-templates select="html:tr[1]|*/tr[1]|tr[1]|*/tr[1]"/>
   </thead>
   <tbody>
    <xsl:apply-templates select="html:tr[position() != 1]|*/tr[position() != 1]|tr[position() != 1]|*/tr[position() != 1]"/>
   </tbody>
  </tgroup>
 </informaltable>
</xsl:template>

<xsl:template name="generate-colspecs">
 <xsl:param name="count" select="0"/>
 <xsl:param name="number" select="1"/>
 <xsl:choose>
  <xsl:when test="$count &lt; $number"/>
  <xsl:otherwise>
   <colspec>
    <xsl:attribute name="colnum">
     <xsl:value-of select="$number"/>
    </xsl:attribute>
    <xsl:attribute name="colname">
     <xsl:value-of select="concat('col',$number)"/>
    </xsl:attribute>
   </colspec>
   <xsl:call-template name="generate-colspecs">
    <xsl:with-param name="count" select="$count"/>
    <xsl:with-param name="number" select="$number + 1"/>
   </xsl:call-template>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<xsl:template match="html:tr|tr">
 <row>
  <xsl:apply-templates/>
 </row>
</xsl:template>

<xsl:template match="html:th|html:td|th|td">
 <xsl:variable name="position" select="count(preceding-sibling::*) + 1"/>
 <entry>
  <xsl:if test="@colspan &gt; 1">
   <xsl:attribute name="namest">
    <xsl:value-of select="concat('col',$position)"/>
   </xsl:attribute>
   <xsl:attribute name="nameend">
    <xsl:value-of select="concat('col',$position + number(@colspan) - 1)"/>
   </xsl:attribute>
  </xsl:if>
  <xsl:if test="@rowspan &gt; 1">
   <xsl:attribute name="morerows">
    <xsl:value-of select="number(@rowspan) - 1"/>
   </xsl:attribute>
  </xsl:if>
  <xsl:apply-templates/>
 </entry>
</xsl:template>

<xsl:template match="html:td_null|td_null">
 <xsl:apply-templates/>
</xsl:template>

<xsl:template name="count_columns">
 <xsl:param name="table" select="."/>
 <xsl:param name="row" select="$table/html:tr[1]|$table/*/html:tr[1]|$table/tr[1]|$table/*/tr[1]"/>
 <xsl:param name="max" select="0"/>
 <xsl:choose>
  <xsl:when test="local-name($table) != 'table'">
   <xsl:message>Attempting to count columns on a non-table element</xsl:message>
  </xsl:when>
  <xsl:when test="local-name($row) != 'tr'">
   <xsl:message>Row parameter is not a valid row</xsl:message>
  </xsl:when>
  <xsl:otherwise>
   <!-- Count cells in the current row -->
   <xsl:variable name="current_count">
    <xsl:call-template name="count_cells">
     <xsl:with-param name="cell" select="$row/html:td[1]|$row/html:th[1]|$row/td[1]|$row/th[1]"/>
    </xsl:call-template>
   </xsl:variable>
   <!-- Check for the maximum value of $current_count and $max -->
   <xsl:variable name="new_max">
    <xsl:choose>
     <xsl:when test="$current_count &gt; $max">
      <xsl:value-of select="number($current_count)"/>
     </xsl:when>
     <xsl:otherwise>
      <xsl:value-of select="number($max)"/>
     </xsl:otherwise>
    </xsl:choose>
   </xsl:variable>
   <!-- If this is the last row, return $max, otherwise continue -->
   <xsl:choose>
    <xsl:when test="count($row/following-sibling::html:tr) = 0">
     <xsl:value-of select="$new_max"/>
    </xsl:when>
    <xsl:when test="count($row/following-sibling::tr) = 0">
     <xsl:value-of select="$new_max"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:call-template name="count_columns">
      <xsl:with-param name="table" select="$table"/>
      <xsl:with-param name="row" select="$row/following-sibling::html:tr|$row/following-sibling::tr"/>
      <xsl:with-param name="max" select="$new_max"/>
     </xsl:call-template>
    </xsl:otherwise>
   </xsl:choose>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

<xsl:template name="count_cells">
 <xsl:param name="cell"/>
 <xsl:param name="count" select="0"/>
 <xsl:variable name="new_count">
  <xsl:choose>
   <xsl:when test="$cell/@colspan &gt; 1">
    <xsl:value-of select="number($cell/@colspan) + number($count)"/>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="number('1') + number($count)"/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:variable>
 <xsl:choose>
  <xsl:when test="count($cell/following-sibling::*) &gt; 0">
   <xsl:call-template name="count_cells">
    <xsl:with-param name="cell"
                    select="$cell/following-sibling::*[1]"/>
    <xsl:with-param name="count" select="$new_count"/>
   </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
   <xsl:value-of select="$new_count"/>
  </xsl:otherwise>
 </xsl:choose>
</xsl:template>

</xsl:stylesheet>

