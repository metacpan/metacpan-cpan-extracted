#!/usr/bin/perl -w
#   HTML::Latex
#   Copyright (C) 2000 Peter Thatcher

#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

package HTML::Latex;
$VERSION = '1.1';

use strict;
# use warnings;
# use diagnostics;
use FileHandle;
use File::Path;
use File::Basename;
use Data::Dumper;
use Carp;
use vars qw($packages $heads $tags $options $pres $banned $LOG $VERSION %present);

#extra
use HTML::TreeBuilder;
use XML::Simple;

################### BEGIN DOCUMENTATIEN #####################

=head1 NAME

HTML::Latex - Creates a Latex file from an HTML file.

=head1 SYNOPSIS

 use HTML::Latex

 my $parser = new HTML::Latex($conffile);
 $parser->set_option(\%options);
 $parser->add_package(@packages);
 $parser->ban_tag(@banned);
 $parser->set_log($logfile);

 # Option 1:
 foreach my $uri (@ARGV) {
    my ($htmlfile,$latexfile) = $parser->html2latex($uri);
 }

 # Option 2:
 foreach my $uri (@ARGV) {
    my $in = IO::File->new("< $uri");
    my $out = IO::File->new("> $uri.tex");
    $parser->html2latex($in,$out);
 }

 # Option 3:
 my $html_string = join("\n",<>);
 my $tex_string = $parser->parse_string($html_string,1);

 # Option 4:
 my $html_string = join("",@ARGV);
 my $tex_string = $parser->parse_string($html_string);

print $tex_string;

=head1 DESCRIPTION

This class is used to create a text file in Latex format from a file
in HTML format.  Use the class as follows:

1. Create a new HTML::Latex object.

2. Override any options using set_option(), add_package(), ban_tag(), or set_log().

3. Run html2latex() on a file or URL.

4. Do whatever you want with the filename that was returned.

=head1 METHODS

=over

=item B<$p = HTML::Latex-E<gt>new($conffile)>

Creates a new HTML::Latex object.  It parses the configuation file
$conffile to set attributes.  The format of that file can be found in
the CONFIGURATION FILE section.

Example:

    my $parser = HTML::Latex->new();

=item B<($htmlfile,$latexfile) = $p-E<gt>html2latex($in,$out)>

$in is any URL or filename or FileHandle.  If it is a URL, it is
mirrored locally.  The local location is returned as $htmlfile.  The
method produces a Latex file $latexfile.

Locally mirrored files are all stored in the "store" directory which
can be set with either set_option() or in the configuration file.  See
B<store> under the OPTIONS section for more details.

A mirrored file will automatically be re-downloaded when the URL is
updated.  If it has not been updated, html2latex() will use the local
file only.

Also, html2latex() defaults to index.html when a file is not given.
For instance, if you used C<html2latex(http://slashdot.org)>, then the
url http://slashdot.org/index.html would be used.

Example:

    my($htmlfile,$latexfile) =
       $parser->html2latex('report01.html');


=item B<$tex_string = $p-E<gt>parse_string($html_string [,$full])>

$html_string is an HTML string.  $tex_string is a LaTeX string.  If
$full is 0, then any <HTML> and <BODY> tags are ignored, and the
string is just plain tex.  If $full is 1, then <HTML> and <BODY> tags
are implicitly added.  Basically, it's a choice as to whether or not
$tex_string has a LaTeX preamble in it.

=item B<my @old_values = $p-E<gt>set_option(\%options)>

Sets on option.  For a description of options, see the OPTION section
below.  Returns an list of all the old values based on the keys of
%options.

Example:

    $parser->set_option({border => 0, debug => 1});

=item B<$p-E<gt>add_package(@packages)>

Adds packages to the list used by \usepackage{} in Latex.  The
defaults are fullpage, graphicx, and url.

Example:

    $parser->add_package('doublespace');

=item B<$p-E<gt>add_head(@heads)>

Adds options to the list used by \documentclass[OPTIONS]{article} in
Latex.  Font is automatically put there, so don't put it there
yourself.

Example:

    $parser->add_head('twocolumn');

=item B<$p-E<gt>ban_tag(@banned)>

Add @banned to the list of tags that html2latex() will ignore.  This
overrides tag definitions in the configuration file. By default, the
<CODE> tag is banned.  That is because some people were using
<PRE><CODE></CODE></PRE>, which can be really bad if both are parsed.

Example:

    $parser->ban_tag('code');

=item B<my $filehandle = $p-E<gt>set_log($logfile)>

Have errors and messages printed to the filename or FileHandle or
IO::File $logfile.  By default, things are printed to STDERR.
set_log() returns the FileHandle of the log file.

Example:

    my $filehandle = $parser->set_log('report01.log');

=back

=head1 CONFIGURATION FILE

The configuration file is a very simple XML file.  The root element is
<conf>.  Nested inside are four tags: <tag> <package> <ban> <options>.

=head2 tag

<tag> has 2 attributes: I<name> and I<type>.  Inside of <tag> is
nested zero to many <tex> tags. Each of these is described below.

=over

=item name

The I<name> attributes assigns the other values (I<type> and I<tex>)
to an HTML tag of a certain name.

=item type

The type of a tag basically tells html2latex() how to handle it.
Internally, this assigns the tag to a certain handler.

=item tex

When handling a tag, html2latex must know what TeX string to replace
the HTML tags with.  This is done with the use of <tex>tex
string</tex>.  Different types require 0,1,or 2 such tags nested
inside of <tag>.  You can think of <tex> tags as arguments to pass to
a I<type> handler.  Internally, that is what it is.

Extraneous White space is ignored; do not rely upon it.  \N is replaced
with newlines.  Everything else is just as you type it.

=head2 tag examples

For a lot of examples, just look at the default configuration file,
html2latex.xml.  We will go over 1 example in detail.  This example is
for the HTML <B> tag.

    <tag name="b" type="command">
        <tex>textbf</tex>
    </tag>

This text tells html2latex() to treat the <B> tag as a TeX command.
It gives it the additional argument of 'textbf'.  html2latex() will
call the command_handler('textbf') and the output will be \textbf{NESTED DATA}.

=back

=head2 package

For each <package>package_name</package> given, package_name is added
to the list printed in the Latex file.  For instance, the lines

    <package>fullpage</package>
    <package>graphicx</package>
    <package>url</package>

adds the packages fullpage, graphicx, and url.  The package 'fullpage'
is often recommended.

=head2 head

For each <head>head</head> given, head is added to the list of options
printed in the \documentclass command.  For instance, the line

    <head>twocolumn</head>

creates the command \documentclass[10pt,twocolumn]{article}.

=head2 ban

<ban> will make html2latex ignore a tag.  For instance, the line

   <ban>code</ban>

makes html2latex() ignore <code> even though it has a definition in
the configuration file.  This can be useful to turn on/turn off tags
when trying different configurations.

=head2 options

Inside of <options> are a number of other tags.  Each is described
below in OPTIONS.  The value inside of a given <OPTION> </OPTION>
provides a default value that can be overridden with command-line
options.  For instance, <font>10</font> will set the default font size
to 10.

=head1 TYPES

There are a number of different types of HTML tags support by
HTML::Latex.  The list is: command, environment, single, other, table,
image, and ignore.  Each are described below.  TEX1 and TEX2 mean the
first and second value given by <tex>.  NAME is given by the name
attribute.  VALUE is the value nested within an HTML tag.  

=head2 command

 HTML Key:       <NAME>VALUE</NAME>
 HTML Example:   <B>Foo</B>
 TeX  Key:       \TEX1{VALUE}
 TeX  Example:   \textbf{Foo}

=head2 environment

 HTML Key:       <NAME>VALUE</NAME>
 HTML Example:   <OL>Foo</OL>
 TeX  Key:       \begin{TEX1} VALUE \end{TEX1}
 TeX  Example:   \begin{enumerate} Foo \end{enumerate}

=head2 single

 HTML Key:       <NAME>VALUE
 HTML Example:   <LI>Foo
 TeX  Key:       \TEX1 VALUE
 TeX  Example:   \item Foo

=head2 other

 HTML Key:       <NAME>VALUE</NAME>
 HTML Example:   <DT>Foo
 TeX  Key:       TEX1 VALUE TEX2
 TeX  Example:   \item[Foo]

=head2 kill

 HTML Key:       <NAME>VALUE</NAME>
 HTML Example:   <SCRIPT>javascript.garbage()</SCRIPT>
 TeX  Key:       ""
 TeX  Example:   ""

This is of particular fun because any nested HTML tags are also ignored.  Good for removing unwanted javascript.

=head2 table

This should be applied if and only if a tag is of type TABLE,TR, or TD.

=head2 image

This should be applied if and only if a tag is of type IMG.

=head2 ignore

Do nothing.  Has the same affect as banning a tag.

=head1 OPTIONS

=over

=item B<store>

"store" is the directory that mirrored files are stored in.  It is
~/.html2latex by default.  In side of this directory are
subdirectories representing the HOST in a URL and the path from that
HOST.  For instance, if you used
C<html2latex(http://slashdot.org/path/to/file.html>, it would store
the file as ~/.html2latex/slashdot.org/path/to/file.html.

=item B<cache>

This will force html2latex to use cached files if possible.  It always
caches anyway, and uses the cached file if the network file has not
changed.  This just forces the use of the local file if available.

=item B<document_class>

Set the documentclass to use.  Any valid latex document class is
valid.  Examples are B<report>, B<book>, and B<article>.  B<article>
is the default.  If an invalid document class is used, the output
latex file will not compile.

=item B<paragraph>

True uses HTML-style paragraphs.  They leave a newline between
paragraphs.  False uses TeX-style paragraphs.  They have no newline,
but indent the first line of every paragraph.  Default is true.

=item B<font>

Set the font size.  Can be 10,11, or 12.  Do not try anything else.
html2latex will not check it, but the latex file will not compile (at
least I think not).  Default is 12.

=item B<image>

Set the scale for images in the latex file.  This is useful because
some images in HTML or much to big to fit on a page.  Default is 1.0.
Scale can be any non-zero positive floating point number; large
numbers are not recommended.

=item B<border>

True means table borders are on.  False mean they are off.  This is
always overridden by HTML attributes.

=item B<mbox>

html2latex() will put a tex \mbox around all of the tables it creates.
I do not know why, but with a lot of tables (especially nested ones),
the tex and pdf output will work better.  So, if you do not like your
output with tables, try this.  True means on, false means off.
Default is false.

=item B<debug>

The bigger the number set, the more the debugging info printed.  0
means things relevant to the user.  1 means things that trace some
code.  2 or greater means dumping data structures.

=head1 Extending

Extending HTML::Latex basically means making a new tag work.  Usually,
this would call for writing a new handler.  If a present handler will
suffice, then you can stip to the 3rd step. It's very simple to do so.
There are 3 easy steps:

=head2 Write the function.

Write a function (preferably ending in '_handler').  It's input is 1
HTML::Element and several tex strings.  The type of HTML::Element and
the value of the strings is set in the XML config file.  Your furtions
responsibilty is to return a TeX string representing the HTML::Element
and all of it's children elements.

The children are very easy to take care of.  The string representing
the children elements is obtained by calling C<texify($html_element)>.
So, the function really only has to worry about the current
HTML::Element.

In particular, it must return that comes before and goes after the
string represting the current HTML::Element.  So, if you wanted a
handler that print \TAG as the TeX for any <TAG> in HTML and a special
TEX value given in the config file for </TAG>, then the handler would
look like this:

 sub my_handler{
     my ($html_element,$tex) = @_;
     return '\' . $html_element->tag() . texify($html_element) . $tex;
 }

In this example, one TEX parameter was passed in by the XML config
file.  The handler return what comes before the children concatenated
with the texify-ed children texified with what comes after the
children.  See the documentation for HTML::Element for all of the
things you can do with them.

=head2 Assign a tag type to a handler.

Just add an entry to %types below.  It should have a type name as a
key and a reference to your handler as a value.  Following our
example, we could add the line:

    "my_type"     =>    \&my_handler,

To %types.

=head2 Add support in the configuration file.

The format of the configuration file is in XML and can be found above
under CONFIGURATION FILE.  The default XML file is at the bottom of
Latex.pm under __DATA__. Basically, for every tag you want to use your
new handler, use <tag> as follows:

 <tag name="TAG_NAME" type="my_type">
     <tex>TEX_PARAMATER</tex>
 </tap>

TAG_NAME is, of course, the tag name.  "my_type" is the name of the
type you assigned your handler to.  TEX_PARAMATER is the value that
gets placed under $tex in the example handler.


That's it.  Now HTML::Latex should obey the new handler and behave
correctly.

=head1 NOTES

In you call html2latex() on several URLs any filename given after a
URL will continue to use the latest HOST given.  Also, files default
to index.html, regardless of what the server thinks.  So, if you use:

 html2latex(http://slashdot.org)
 html2latex(foo.html)
 html2latex(http://linuxtoday.net)
 html2latex(bar.html)

html2latex() will try to grab http://slashdot.org/index.html,
http://slashdot.org/foo.html, http://linuxtoday.net/index.html, and
http://linuxtoday.net/bar.html

=head1 BUGS

* Anything between <TABLE> and <TR> and <TD> is ignored.  I do not


* Anything between <OL> or <UL> and <LI> will not be ignored, but will
  really mess Latex up.

=cut

################### END DOCUMENTATION #######################

################### BEGIN DEFENITIONS #######################

# Test what modules we can use
eval {require URI};
$present{'URI'} = 1 unless $@;

eval {require LWP::Simple};
$present{'LWP::Simple'} = 1 unless $@;

eval {require Image::Magick};
$present{'Image::Magick'} = 1 unless $@;

# The configuration file gives a "type" to each tag.  This hash tells
# what functions to use on each type
my %types = (
	     "command"     => \&command_handler,
	     "environment" => \&environment_handler,
	     "single"      => \&single_handler,
	     "ignore"      => \&texify,
	     "other"       => \&other_handler,
	     "kill"        => sub {return ""},

	     "image"       => \&image_handler,
	     "table"       => \&table_handler,
	     "pre"         => \&pre_handler,      # Experimental; don't use
	    );

# Some characters typed in HTML need to be altered to be correct in
# Latex.  These must be done this specific order All the foreign
# characters or special ascii characters that need to be altered.  *
# next the comment means it doesn't really work or is faked. If it's
# commented out, that means it doesn't work at all.
my @specials = (
		['<!--.*-->' , ''          ], #comments
		['\$'    ,  '\$'           ], 
	        ['\\\\(?!\$)', "\$\\backslash\$"], #\
		['<'     , '$<$'           ],
 		['>'     , '$>$'           ],
		['&'     , '\&'            ],
		['%'     , '\%'            ],
		['#'     , '\#'            ],
		['{'     , '\{'            ],
		['}'     , '\}'            ],
		['_'     , '\_'            ],
		['\^'    , '\^{}'          ],
		[chr(161), '!`'            ], #¡
	       #[chr(162), ''              ], #¢*
		[chr(163), '{\\pounds}'    ], #£
	       #[chr(164), ''              ], #¤*
 		[chr(165), '{Y\hspace*{-1.4ex}--}'], #¥*
		[chr(166), '$|$'           ], #¦*
 		[chr(167), '{\\S}'         ], #§
		[chr(168), '\\"{}'         ], #¨
		[chr(169), '{\\copyright}' ], #©
		[chr(170), '$^{\underline{a}}$'], #ª*
		[chr(171), '<<'            ], #«
		[chr(172), '$\\neg$'       ], #¬
		[chr(173), '$-$'           ], #­
	       #[chr(174), ''              ], #®*
		[chr(175), '$^-$'          ], #¯
		[chr(176), '$^{\\circ}$'   ], #°
		[chr(177), '$\\pm$'        ], #±
	        [chr(178), '$^2$'          ], #²
		[chr(179), '$^3$'          ], #³
		[chr(180), '$^\\prime$'    ], #´
		[chr(181), '$\\mu$'        ], #µ
		[chr(182), '{\P}'          ], #¶
		[chr(183), '$\cdot$'       ], #·
		[chr(184), ','             ], #¸*
                [chr(185), '$^1$'          ], #¹
                [chr(186), '$^{\\underline{\\circ}}$'],	#º*
                [chr(187), '>>'            ], #»
                [chr(188), '$\frac{1}{4}$' ], #¼
		[chr(189), '$\frac{1}{2}$' ], #½
		[chr(190), '$\frac{3}{4}$' ], #¾
		[chr(191), '?`'            ], #¿
		[chr(192), '\\`A'          ], #À
		[chr(193), '\\\'A'         ], #Á
		[chr(194), '\\^A'          ], #A
		[chr(195), '\\~A'          ], #Ã
		[chr(196), '\\"A'          ], #Ä
		[chr(197), '{\\AA}'        ], #Å
		[chr(198), '{\\AE}'        ], #Æ
		[chr(199), '\\c{C}'        ], #Ç
		[chr(200), '\\`E'          ], #È
		[chr(201), '\\\'E'         ], #É
		[chr(202), '\\^E'          ], #Ê
		[chr(203), '\\"E'          ], #Ë
		[chr(204), '\\`I'          ], #Ì
		[chr(205), '\\\'I'         ], #Í
		[chr(206), '\\^I'          ], #I
		[chr(207), '\\"I'          ], #Ï
		[chr(208), '{D\\hspace*{-1.7ex}-\\hspace{.9ex}}'], #Ð*
		[chr(209), '\\~N'          ], #Ñ
		[chr(210), '\\`O'          ], #Ò
		[chr(211), '\\\'O'         ], #Ó
		[chr(212), '\\^O'          ], #Ô
		[chr(213), '\\~O'          ], #Õ
		[chr(214), '\\"O'          ], #Ö
		[chr(215), '$\chi$'        ], #×
		[chr(216), '{\\O}'         ], #Ø
		[chr(217), '\\`U'          ], #Ù
		[chr(218), '\\\'U'         ], #Ú
		[chr(219), '\\^U'          ], #Û
		[chr(220), '\\"U'          ], #Ü
		[chr(221), '\\\'Y'         ], #Ý*
		[chr(222), 'P'             ], #Þ*
		[chr(223), '"s'            ], #ß
		[chr(224), '\\`a'          ], #á
		[chr(225), '\\\'a'         ], #à
		[chr(226), '\\^a'          ], #â
		[chr(227), '\\~a'          ], #ã
		[chr(228), '\\"a'          ], #ä
		[chr(229), '\\r{a}'        ], #å
		[chr(230), '{\ae}'         ], #æ
		[chr(231), '\\c{c}'        ], #ç
		[chr(232), '\\`e'          ], #é
		[chr(233), '\\\'e'         ], #è
		[chr(234), '\\^e'          ], #ê
		[chr(235), '\\"e'          ], #ë
		[chr(236), '\\`{\i}'       ], #ì
		[chr(237), '\\\'{\\i}'     ], #í
		[chr(238), '\\^{\\i}'      ], #î
		[chr(239), '\\"{\\i}'      ], #ï
		[chr(240), '\\v{o}'        ], #ð
		[chr(241), '\\~n'          ], #ñ
		[chr(242), '\\`o'          ], #ò
		[chr(243), '\\\'o'         ], #ó
		[chr(244), '\\^o'          ], #ô
		[chr(245), '\\~o'          ], #õ
		[chr(246), '\\"o'          ], #ö
		[chr(247), '$\\div$'       ], #÷
		[chr(248), '{\\o}'         ], #ø
		[chr(249), '\\`u'          ], #ù
		[chr(250), '\\\'u'         ], #ú
		[chr(251), '\\^u'          ], #û
		[chr(252), '\\"u'          ], #ü
		[chr(253), '\\\'y'         ], #ý
		[chr(254), 'p'             ], #þ*
		[chr(255), '\\"y'          ], #ÿ
	       );

# complie matchings
foreach my $set (@specials) {
    $set->[0] = qr|$set->[0]|;
}

################### END DEFENITIONS #######################

# Paramaters for HANDLERs and SUBs are shown as <N> and [N].  N is the
# number of the parameter, starting with 1.  So, the first paramater
# would be <1>, the second <2>, and so on.  <N> means the paramater is
# mandatory.  [N] means it is optional.

##################### BEGIN METHODS  ######################

# initializes options with optional configuration file
sub new {
    my ($class,$conffilename) = @_;

    my $conffile;
    if(defined($conffilename)){
	$conffile = IO::File->new("< $conffilename");
    } else {
	$conffile =  \*DATA;
    }

    my $conf = XMLin($conffile,forcearray => ['tex','pre','ban']);

    # moved @banned from an array to a hash for fast lookup later
    my $banned_ref = $conf->{ban};
    $conf->{ban} = {};
    foreach my $banned (@$banned_ref){
	$conf->{ban}{$banned}++;
    }

    # make any refrences in @tex (see handlers below) to empty strings and new lines
    # Ugly, I know.  Perhaps XML::Simple is too simple.
    foreach my $tag (keys %{$conf->{tag}}){ 
	foreach my $tex (@{$conf->{tag}{$tag}{tex}}){ #some derefrence, eh?
	    $tex = (ref($tex) ? '' : $tex);   # {} => ''
	    $tex =~ s/\\N/\n/g;               # \N => newline
	    # if it's a verbatim and not banned
	    push @{$conf->{pre}}, $tag if ($tex eq 'verbatim' && !$conf->{ban}{$tag});
	}
    }

    #open logging files
    $conf->{log} = $conf->{conf}{options} ? 
	FileHandle->new($conf->{options}{log},'w') :
	    \*STDERR;

    return bless $conf,$class;
}

# converts html2latex using &texify.
# <1> The html filename or filehandle
# <2> optional second filehandle
sub html2latex {
    my ($conf,$in,$out) = @_;

    #global to functions called below, which is what we want
    local $packages = $conf->{package} || [];
    local $heads    = $conf->{head}    || [];
    local $tags     = $conf->{tag}     || {};
    local $options  = $conf->{options} || {};
    local $banned   = $conf->{ban}     || {};
    local $pres     = $conf->{pre}     || {};
    local $LOG      = $conf->{log};
    $options->{store} =~ s/^\s*~/$ENV{HOME}/ if exists $ENV{HOME};

    print $LOG Dumper $conf if $options->{debug} > 1;

    #open files.
    my($filenamein,$filenameout);
    unless(ref $in and ref $out){ #filenhadles -- leave them alone.
	($in,$out,$filenamein,$filenameout) = open_files($in,1) if defined($in);
    }

    #if you have a uri and it exists
    #build the HTML tree
    if($in && $out){
	my $tree = HTML::TreeBuilder->new;
	$tree->warn(1);
	my $result = $tree->parse_file($in);

	#here's where all the big magic happens
	print $out &preamble_handler($tree->root);

	#destroy the HTML tree
	$tree->delete;

	return ($filenamein,$filenameout) if ($filenamein && $filenameout);
	return $result;  #If you recieved filehandles, just return the return of $tree->parse
    } else {
	# print $LOG "You better give html2latex() a valid filename if you want it to do anything.\n";
	return;
    }
}

sub parse_string {
    my ($conf,$input,$full) = @_;
    return unless defined($input);

    local $packages = $conf->{package} || [];
    local $heads    = $conf->{head}    || [];
    local $tags     = $conf->{tag}     || {};
    local $options  = $conf->{options} || {};
    local $banned   = $conf->{ban}     || {};
    local $pres     = $conf->{pre}     || {};
    local $LOG      = $conf->{log};
    $options->{store} =~ s/^\s*~/$ENV{HOME}/ if exists $ENV{HOME};

    print $LOG Dumper $conf if $options->{debug} > 1;

    my $tree = HTML::TreeBuilder->new;
    $tree->warn(1);
    $tree->parse($input);

    my $result;
    if($full){
	$result = preamble_handler($tree->root);  # Print whole file
    } else {
	$result = texify($tree->find_by_tag_name('body'));
    }
    $tree->delete;

    return $result;
}

# set options for running html2latex
# <1> is a hash refrence of options
sub set_option {
    my ($conf,$options) = @_;
    my @old_values = ();
    while(my ($key,$value) = each %$options){
	if(defined($value)){
	    push @old_values, $conf->{options}{$key};
	    $conf->{options}{$key} = $value;
	}
    }
}

sub add_package {
    my $conf = shift;
    push @{$conf->{package}}, @_;
}

sub add_head {
    my $conf = shift;
    push @{$conf->{head}}, @_;
}

sub ban_tag {
    my $conf = shift;
    foreach my $banned (@_){
	$conf->{ban}{$banned}++;
    }
}

#set log file to $logfile
#return FileHandle to log file.
sub set_log {
    my ($conf,$logfile) = @_;
    if(ref $logfile){
	$conf->{log} = $logfile;
    } else {
	$conf->{log} = FileHandle->new($logfile,'w') or 
	  die "FILE: Bad logfile: $logfile";
    }
    return $conf->{log};
}
##################### END HANDLERS #########################

##################### BEGIN HANDLERS #######################

# All HANDLERs are called like so:
# &HANDLER($html_element,@tex); 

# @tex is a list of latex strings $html_elmemnt is a node in the HTML
# tree.  HTML::ELement man page for more on that.

# Anyway, the comments for each HANDLER represent the starting HTML
# string and the output tex string.  Anything inbetween HTML tags is
# recursivly texified by the big sub &texify, which then calls other
# HANDLERs.

# HTML input form: <FOO> Bar </FOO>
# Latex output form: \command{bar}
sub command_handler{
    my($html_element,$command) = @_;
    return "\\$command\{" . texify($html_element) . "\}\n";
}

# HTML input form: <FOO> Bar </FOO>
# Latex output form: tex1 bar tex2
sub other_handler{
    my($html_element,@tex) = @_;
    return $tex[0] . texify($html_element) . $tex[1];
}

# HTML input form: <FOO> Bar </FOO>
# Latex output form: \begin{tex} Bar \end{tex}
sub environment_handler{
    my($html_element,$environment) = @_;
    return '\begin{' . $environment . '}' . "\n" . 
	texify($html_element) . "\n" . '\end{' .  $environment . '}' . "\n";
}

# HTML input form: <FOO> Bar (implicit end)
# Latex output form: \tex Bar
sub single_handler{
    my($html_element,$single) = @_;
    return $single . " " . texify($html_element) . "\n";
}

# HTML input form: <PRE> Bar </PRE>
# Latex output has all of the spaces made into hard spaces and
# newlines into hard newlines. It's the best I can do since latex
# doesn't want to respect whitespace.  It's very experimental. One
# should really just use the verbatim environment, but what the heck,
# give people the option.
sub pre_handler{
    my($html_elemnt) = shift;
    my $text = $html_elemnt->as_text;

    $text =~ s/[ ]/\\ /og;
    $text =~ s/\n/\\\\\n/og;

    return $text;
}

# Does a lot of work to create a table in latex format.
# It takes <TABLE>, <TR>, and <TD>.  It works by finding those tags nested inside
# and then calling texify on them while keepind track of when to print
# latex syntax.  It's messy, I know.  Nested tables are completely
# ignored, and anything inside a table but not inside of a <TD> tag is
# also ignored.  If anyone would like to improve this, that would be
# very cool.
# <3> The HTML::Element representing the table.  It doesn't use
# $content_ref, so you don't really need it.

sub table_handler{
    my($html_element,$tex) = @_;
    my $output = "";
    if($tex eq "table"){
	# It's a table tag
	$output = ($options->{mbox}? '\mbox{' : '') .
	  create_latex_table($html_element) . ($options->{mbox}? '}' : '');
    } else { 
	# It's a td or tr, let create_latex_table() take care of "\\" and "&"
	# add the texified text inside
	$output = texify($html_element); 
    }
    return $output;
}

# HTML input form: <IMG src="bar.(jpg|jpeg|gif|png)">
# Latex output form: \includegraphic{bar.png} 
# In also converts the image to a .png using "convert".
# <3> The HTML::Element representing the tag.  It doesn't use
# $content_ref, so you don't really need it.
sub image_handler{
    my($html_element,$tex) = @_;
    my $source = $html_element->attr('src') || "";
    my $scale = $html_element->attr('scale') || $options->{image};
    my $alt = $html_element->attr('alt') || "";

    if($scale and my $image = convert_image($source,$scale)){
	# convert worked
	return "\\$tex\[scale=$scale\]\{$image\} ";
    } else { 
	#convert didn't work or images weren't selected.
	print $LOG "IMG: Couldn't convert $source; using alt\n";
	print $LOG "\tRecieved <$image>\n" if $options->{debug};
	return $alt;
    }
}

# Prints the preamble.  Not to extensize right now, but will become
# very extensive if I decide to parse stuff in the HEAD tag.
sub preamble_handler{
    my($html_element,$tex) = @_;
    my $document_class = $html_element->attr('class') || $options->{document_class} || 'article';
    my $font_size = $html_element->attr('fontsize') || $options->{font_size} || 10;
    my $output;

    $output .= join ('',
		     '\documentclass[',
		     join (",","${font_size}pt",@$heads),
		     ']{',
		     $document_class,
		     '}',
		     "\n",
		     '\usepackage{',
		     join(", ",@$packages),
		     '}', 
		     "\n"
		     );
    $output .= join ('',
		     '\setlength{\parskip}{1ex}',
		     "\n",
		     '\setlength{\parindent}{0ex}',
		     "\n",
		     ) if $options->{paragraph};

    $output .= texify($html_element);

    return $output;
}

###################### END HANDLERS #######################


# Takes in an array of HTML::Element-es which calls a handler on all of its
# children, which calls texify recursively, and eventually makes a
# string.

sub texify {
    my $parent_element = shift;
    my $output = "";

    foreach my $html_element ($parent_element->content_list){
	if(ref $html_element){
	    # If this element is another HTML::Element
	    my $tag = $html_element->tag();
	    print $LOG "\t" x ($html_element->depth - 1) . "<$tag> " if $options->{debug};

	    if(my $tag_hash_ref = $tags->{$tag} and !$banned->{$tag}){
		# If the tag is used with a handler and it isn't banned, use it.
		my $handler_ref = $types{$tag_hash_ref->{type}} or 
		    die "<$tag> needs a proper type (not $tag_hash_ref->{type})\n";
		my @tex = @{$tag_hash_ref->{tex} || []}; 
		print $LOG "is of type $tag_hash_ref->{type}: calling handler with \"" . 
		    join(",",@tex) . "\"\n" if $options->{debug};
		$output .= $handler_ref->($html_element,@tex);
	    } else {
		# Otherwise, just texify the contents;
		print $LOG "has no type \n" if $options->{debug};
		$output .= texify($html_element);
	    }
	} else {
	    # Otherwise, it's just a string 
	    print $LOG "\t" x ($parent_element->depth + 1), $html_element if $options->{debug} > 1;
	    unless($parent_element->is_inside(@$pres)){
		#don't change any characters if inside a tag such as PRE.
		#Quote expansion needs more finese.
		$html_element =~ s/([^\s\[\{\(~])"/$1''/og; #" preceded by character not \s,[,{,or [
		$html_element =~ s/"/``/og;
		foreach my $special (@specials){
		    $html_element =~ s/$special->[0]/$special->[1]/g;
		}
	    }
	    $output .= urlify($html_element);
	}
    }
    return $output;
}


# opens necessary files
# <1> The base of the filename
sub open_files {
    return unless (my $htmlfile = get_uri(@_));

    #if filename has anything .*html, then remove the extension
    my ($filename,$path,$suffix) = fileparse($htmlfile,'\.\w*html?');
    my $texfile = "$path$filename.tex";

    check_for_previous_files($texfile);

    my $fh_in = FileHandle->new("< $htmlfile") or die "Can't open $htmlfile: $!";
    my $fh_out = FileHandle->new("> $texfile") or die "Can't open $texfile: $!";
    print $LOG "FILE: Processing $htmlfile and writing to $texfile\n";
    return ($fh_in,$fh_out,$htmlfile,$texfile);
}

# checks for existance of file and moves it to name .old .
# <1> The filename
# [2] whether files should be renamed and overridden or just left alone.
# default is rename override 
# returns whether the file exists or not
sub check_for_previous_files {
    my $filename = shift;
    my $override = shift || 1; 

    if(-f $filename && $override){
	rename $filename, "$filename.old";
	print $LOG "FILE: renamed $filename $filename.old\n"; 
    }
    return $filename;
}

# checks for existance of file and prints that it successfully created it.
# <1> filename
# [2] error to print if didn't create;
sub check_for_current_files {
    my $filename = shift;
    if( -f $filename){
	print $LOG "FILE: Successfully created $filename\n";
	return $filename;
    }
    else{
	print $LOG "FILE: Failed to create $filename\n";
	return;
    }
}
# Creates a latex table from an html table using the other table sub procedures.
# <1> The $html_element that is a table tag.
# Returns the table in latex string form
sub create_latex_table {
    my $table = shift;
    my $output;
    my($latex_table_ref,$row_number,$column_number) = create_latex_table_def($table);
    my $border = $table->attr('border') || $options->{border};

    $output .= "\n\n" . '\begin{tabular}{' . $latex_table_ref . '}' . "\n";
    $output .= "\\hline \n" if $border;

    #pay attention to only the TR tags inside the TABLE tag.
    my @rows = grep 'tr', $table->content_list;
    foreach my $row (@rows){
	#pay attention to only the TD tags inside the TR tags.
	my @columns = grep 'td', $row->content_list;   

	for my $i (0 .. $column_number - 1){ 
	    # Make Sure to fill in blank ones if necessary
	    my $column = $columns[$i];
	    # Add the td data
	    $output .= texify($column) if $column; 
	    # Add the puncation at the end if not the last one
	    $output .= (($i < $column_number -1)?  " &" : ""); 
	}

	# Add the puncation at the end if not the last one
	$output .= (($row->pindex() < $row_number -1 or $border)?  " \\\\" : "") . "\n"; 
	$output .= " \\hline \n" if $border;
    }

    $output .= "\n" . '\end{tabular}' . "\n\n";

    return $output;
}

# Based on the alignments of the rows, create a latex table defenition (i.e. "cccc")
# <1> The the number of columns the table has;
# <2> A refrence to an array with alignment defenitions
# <3> Whether it has a border or not;
# Returns the table definition, the number of columns and the number of rows
sub create_latex_table_def {
    # get variables
    my $table = shift;
    my $border = $table->attr('border') || $options->{border};
    my ($row_number,$column_number) = find_table_lengths($table);
    my @column_alignments = create_column_alignments($table);

    # define table_def
    my $latex_table_def = ($border? "|" : "");
    for my $i (0 .. $column_number - 1){
	my $align = $column_alignments[$i];
	$latex_table_def .= ($align? ($border? $align . "|" : $align) : ($border? "c|" : "c")); 
    }

    return ($latex_table_def,$row_number,$column_number);
}

# Finds the maximum number of columns that any row in a table has
# and also the number of rows it has.
# <1> the refrence to the HTML::Element table.
sub find_table_lengths {
    my $table = shift;
    #only care about TR children
    my @rows = grep 'tr', $table->content_list;  
    my $max_row_length = 0;
    foreach my $row (@rows){
	#only care about the TD children
	my @columns = grep 'td', $row->content_list;  
	if(@columns > $max_row_length){
	    $max_row_length = @columns;
	}
    }

    #        row_number    column_number
    return (scalar(@rows),$max_row_length);
}

# returns an array of column alignments
# <1> the refrence to the HTML::Element table.
sub create_column_alignments {
    my $table = shift;
    my @column_alignments;
    #only care about TR children
    my @rows = grep 'tr', $table->content_list;  
    if($rows[0]){
	#only care about the TD children
	my @columns = grep 'td', $rows[0]->content_list;  
	foreach my $column (@columns){
	    my $align = $column->attr('align');
	    if($align and $align eq 'left'){
		$align = 'l';
	    } elsif($align and $align eq 'right'){
		$align = 'r';
	    } else {
		$align = 'c';
	    }

	    push @column_alignments, $align;
	}
    }

    return @column_alignments;
}


# converts an image from jpeg or gif into png
# returns the name of the new filename is successfull
# <1> filename

sub convert_image {
    my $source = shift;

    my($absolute,$relative) = get_uri($source);
    if ($absolute and $relative){  #If we can find the file
	#if it successfully stores the file
	my ($aname,$apath,$asuffix) = fileparse($absolute,'\.(gif|png|jpe?g)'); 
	my ($rname,$rpath,$rsuffix) = fileparse($relative,'\.(gif|png|jpe?g)'); 

	if($asuffix eq '.gif' || $asuffix eq '.jpg' || $asuffix eq '.jpeg'){ # 
	    # Picture is of a convertable type
	    if($present{'Image::Magick'}){
		# convert it with Image::Magick
		require Image::Magick;

		my $aoutput = "$apath$aname.png"; #write to and return with png
		my $routput = "$rpath$rname.png";
		my $image = Image::Magick->new();
		$image->Read("$absolute");
		$image->Write("$aoutput");
		undef $image;

		print $LOG "IMG: Converted $source to $routput\n";
		return $routput;
	    } else {
		# No Image::Magick.  Warn user and return nothing.
		print $LOG "IMG: Can't convert $source without Image::Magick; using alt\n";
		return;
	    }
	} elsif ($asuffix eq '.png'){
	    # It's a PNG for sure.
	    my $routput = "$rpath$rname.png";
	    return $routput;
	} else {
	    # so, it's not a png,gif, or jpg.  That means it's an invalid.
	    print $LOG "IMG: Invalid picture type: $source; using alt\n";
	    return;
	}
    } else {
	# We can't even get at the file.
	return;
    }
}

# If the filename is really a URL, then go grab it, translate
# the name to the local file directory, and return that file name.
# Otherwise, just return the thing you got in.
# <1> is the URI
# [2] can specify to change the default host for subsiquent calls
# return ($absolute_path_to_file,$relative_path_to_file);
# The relative can be absolute itself (same as $absolute).
{
    #variables to stay the same across calls of get_uri.  It's used in
    #case we get image URLs with no host or scheme or path.
    my $HOST = undef;     #global value of current HOST
    my $PATH = undef;     #path inside host where we start
    my $SCHEME = undef;   #scheme originally used

    sub get_uri {
	my ($uri,$absolute_local,$relative_local);
	$uri = $absolute_local = $relative_local = shift;
	print $LOG "looking for $uri\n" if $options->{debug};
	my $override = shift || 0;            #absolute means that you replace $HOST and $PATH

	if(-f $uri){ 
	    # it's an absolute local file.  
	    $PATH = dirname($uri) if $override; 
	    print $LOG "returning $uri\n" if $options->{debug};
	    return ($uri,$uri);
	} elsif(defined($PATH) && -f "$PATH/$uri") {    
	    #it must be a local relative image
	    print $LOG "returning $PATH/$uri\n" if $options->{debug};
	    return ("$PATH/$uri",$uri);
	} elsif($uri =~ m|://|){ 
	    #It's a full URL

	    # Load necessary modules if you can.
	    unless($present{'URI'}) {
		print $LOG "NEED: Can't handle request of $uri without module URI\n";
		return;
	    }

	    require URI;
	    URI->import();

	    unless($present{'LWP::Simple'}) {
	    	print $LOG "NEED: Can't handle request of $uri without module LWP::Simple\n";
		return;
	    }

	    require LWP::Simple;
	    LWP::Simple->import();

	    $uri = new URI($uri);
	    my ($path,$filename) = ($uri->path =~ m|(.*/)(.*)|);
	    #replace the host,host_path, and scheme if it doesn't have a value and we're allowed to

	    print $LOG "It's a full URL\n" if $options->{debug};
	    if($override){
		$HOST = $uri->host;
		$PATH = $path || '/';
		$SCHEME = $uri->scheme;
		print $LOG "Setting HOST to $HOST, PATH to $PATH, and SCHEME to $SCHEME\n" if $options->{debug};
	    }

	    my $absolute = ($options->{store} || '.') . '/' . ($uri->host || "") . ($path || "/") . ($filename || "index.html");

	    if(store_uri($uri,$absolute)){    #Now, download the file.  If it fails, return 0.
		print $LOG "returning $absolute\n" if $options->{debug};
		return ($absolute,$absolute);
	    } else {
		return;
	    }
	} elsif(defined($HOST) && defined($SCHEME)){                    
	    #It's a partial URL.
	    if($uri =~ m|^/|){
		#it's an absolute partial URL
		my $absolute_uri = $SCHEME . '://' . $HOST . $uri;
		$absolute_local = ($options->{store} || '.') . '/' . $HOST . $uri;
		if(store_uri($absolute_uri,$absolute_local)){    #Now, download the file.  If it fails, return nothing.
		    return($absolute_local,$absolute_local);
		} else {
		    return;
		}
	    } else {
		#it's a relative partial URL
		my $absolute_uri = $SCHEME . '://' . $HOST . $PATH . $uri;
		$absolute_local = ($options->{store} || '.') . '/' . $HOST . $PATH . $uri;
		if(store_uri($absolute_uri,$absolute_local)){    #Now, download the file.  If it fails, return nothing.
		    return($absolute_local,$uri);
		} else {
		    return;
		}
	    }
	} else {
	    print $LOG "FILE: Unable to access $uri\n";
	    return;
	}
    }
}

# store a URI as a local file, and create a path if necessary
# <1> The URI
# <2> The file to store it in
# returns the base of a filename
sub store_uri {
    my ($uri,$localfile) = @_;
    my ($name,$path) = fileparse($localfile); 

    if(-f $localfile && $options->{cache}){    
	#Use localfile if it's cached and caching is allowed
	print $LOG "URI: Using $localfile for $uri.  See -h to stop cacheing\n";
	return $localfile;
    } else {
	#Override localfile if new.
	mkpath($path,1) if (head($uri));
	if (is_error(mirror($uri,$localfile))){
	    print $LOG "URI: Unable to access $uri\n";
	    return;
	} else {
	    print $LOG "URI: Mirrored $uri in $localfile\n";
	    return $localfile;
	}
    }
}

# replaces URL with \url{URL}.  This code is taken right from the Perl
# Cookbook, which I reccomend.  Honestly, I'm not quite sure how it
# works; but, it does.
# <1> string to urlify.
{

    # I think putting them here will prevent them from needing to be
    # loaded into memory after each function call.  
    my $urls = '(http|telnet|gopher|file|wais|ftp)';
    my $ltrs = '\w';
    my $gunk = '/#~:.?+=&%@!\-';
    my $punc = '.:?\-';
    my $any  = "${ltrs}${gunk}${punc}";
    sub urlify {
	$_[0] =~ s!\b($urls:[$any]+?)(?=[$punc]*[^$any]|$)!\\url{$1}!igox;
        return $_[0];
    }
}
1;  #package must return true.
########################## END SUBS #############################

__DATA__

<!--

Written by Peter Thatcher, 08/2000.

html2latex.xml - the configuration file for HTML::Latex and
html2latex.

Documentation on the file format can be found in the manpage for
HTML::Latex under the section "CONFIGURATION FILE".

-->
<!-- Head Tag needed: DO NOT DELETE!!-->
<conf>
    <!-- Tag description -->
    <tag name="b" type="command">
        <tex>textbf</tex>
    </tag>
    <tag name="body" type="environment">
        <tex>document</tex>
    </tag>
    <tag name="br" type="single">
        <tex>\\</tex>
    </tag>
    <tag name="blockquote" type="environment">
        <tex>quote</tex>
    </tag>
    <tag name="center" type="environment">
        <tex>center</tex>
    </tag>
    <tag name="code" type="environment">
        <tex>verbatim</tex>
    </tag>
    <tag name="dd" type="other">
        <tex></tex>
        <tex>\N</tex>
    </tag>
    <tag name="dl" type="environment">
        <tex>description</tex>
    </tag>
    <tag name="dt" type="other">
        <tex>\item[</tex>
        <tex>]</tex>
    </tag>
    <tag name="em" type="command">
        <tex>emph</tex>
    </tag>
    <tag name="h1" type="command">
        <tex>section*</tex>
    </tag>
    <tag name="h2" type="command">
        <tex>subsection*</tex>7
    </tag>
    <tag name="h3" type="command">
        <tex>subsubsection*</tex>
    </tag>
    <tag name="h4" type="command">
        <tex>textbf</tex>
    </tag>
    <tag name="h5" type="command">
        <tex>textbf</tex>
    </tag>
    <tag name="h6" type="command">
        <tex>textbf</tex>
    </tag>
    <tag name="hr" type="single">
        <tex>\hline</tex>
    </tag>
    <tag name="i" type="command">
        <tex>emph</tex>
    </tag>
    <tag name="img" type="image">
        <tex>includegraphics</tex>
    </tag>
    <tag name="li" type="single">
        <tex>\item</tex>
    </tag>
    <tag name="ol" type="environment">
        <tex>enumerate</tex>
    </tag>
    <tag name="p" type="single">
        <tex>\N\N</tex>
    </tag>
    <tag name="pre" type="environment">
        <tex>verbatim</tex>
    </tag>
    <tag name="script" type="kill"></tag>
    <tag name="strong" type="command">
        <tex>textbf</tex>
    </tag>
    <tag name="table" type="table">
        <tex>table</tex>
    </tag>
    <tag name="td" type="table">
        <tex>tr</tex>
    </tag>
    <tag name="title" type="command">
        <tex>title</tex>
    </tag>
    <tag name="tr" type="table">
        <tex>td</tex>
    </tag>
    <tag name="ul" type="environment">
        <tex>itemize</tex>
    </tag>

    <!-- Options -->
    <options>
        <store>~/.html2latex</store>
        <cache>0</cache>
        <document_class>article</document_class>
	<paragraph>1</paragraph>
        <font>10</font>
        <image>1</image>
        <border>0</border>
        <mbox>0</mbox>
        <debug>0</debug>
    </options>

    <!-- LaTeX Packages-->
    <package>fullpage</package>
    <package>graphicx</package>
    <package>url</package>

    <!-- Tags to Ignore-->
    <ban>code</ban>
</conf>
