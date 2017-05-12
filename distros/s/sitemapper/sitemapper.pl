#!/bin/env perl -w

require 5.004;
use strict;

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

sitemapper.pl - script for generating site maps

=head1 SYNOPSIS

    sitemapper.pl 
        [ -verbose <debug level> ] 
        [ -help ] 
        [ -doc ] 
        [ -depth <depth> ] 
        [ -proxy <proxy URL> ] 
        [ -[no]envproxy ] 
        [ -agent <agent> ]
        [ -authen ] 
        [ -format <html|text|js|xml> ] 
        [ -summary <no. chars> ] 
        [ -title <page title> ] 
        [ -email <e-mail address> ]
        [ -gui ]
        -url <root URL> 

=cut

=head1 DESCRIPTION

B<sitemapper.pl> generates site maps for a given site. It traverses a site from
the root URL given as the -site option and generates an HTML page
consisting of a bulleted list which reflects the structure of the site. 

The structure reflects the distance from the home page of the pages listed;
i.e.  the first level bullets are pages accessible directly from the home page,
the next level, pages accessible from those pages, etc. Obviously, pages that
are linked from "higher" up pages may appear in the "wrong place" in the tree,
than they "belong".

The -format option can be used to specify alternative options for
formating the site map. Currently the options are html (as described above -
the default), js, which uses Jef Pearlman's (jef@mit.edu) Javascript Tree
class to display the site map as a collapsable tree, and text (plain text).

=head1 OPTIONS

=head2 -depth <depth>

Option to specify the depth of the site map generated. If no specified, 
generates a sitemap of unlimited depth.

=head2 -email <e-mail address>

Option to specify the e-mail address which is reported by the robot to the site
it gets pages from.

=head2 -url <root URL>

Option to specify a root URL to generate a site map for.

=head2 -proxy <proxy URL>

Specify an HTTP proxy to use. 

=head2 -[no]envproxy

If -envproxy is set, the proxy specified by the $http_proxy environment
variable will be used (this is the default behaviour). Use -noenvproxy to
suppress this. -proxy takes precedence over -envproxy.

=head2 -agent <agent>

Allows the user to specify an agent for the robot to pretend to be (e.g.
'Mozilla/4.5'). This can be necessary for sites that do browser sniff for
serving particular content, etc.

=head2 -format <formatting option>

Option for specifying the for the site map. Possible values are:

=over 4

=item html

Plain old HTML bulleted list.

=item js

A collapsable DHTML tree, generated using Jef Pearlman's (jef@mit.edu)
Javascript Tree class.

=item text

Plain text.

=item xml

An XML graph of linkage between pages.

=back

=head2 -summary <no. chars>

Automatically extract a summary to display with the title. This will be
truncated at the specified number of characters.

=head2 -title <page title>

Option to specify a page title for the site map.

=head2 -authen

Option to use LWP::AuthenAgent to get HTML pages. This allows the user to type
username / password for pages that are access controlled.

=head2 -gui

Use a Tk GUI to run sitemapper.

=head2 -help

Display a short help message to standard output, with a brief
description of purpose, and supported command-line switches.

=head2 -doc

Display the full documentation for the script,
generated from the embedded pod format doc.

=head2 -version

Print out the current version number.

=head2 -verbose <debug level>

Turn on verbose error messages.

=head1 ENVIRONMENT

B<sitemapper.pl> makes use of the C<$http_proxy> environment variable, if it is
set.

=head1 PREREQUISITES

    Date::Format
    HTML::Entities
    Getopt::Long
    IO::File
    LWP::AuthenAgent
    LWP::UserAgent
    Pod::Usage
    URI::URL
    WWW::Sitemap

=head1 OSNAMES

    hpux 10 PA-RISC1.1 
    linux 2.2.1 ppc-linux 
    linux 2.2.2 i686-linux 
    MSWin32 4.0 MSWin32-x86 
    sunos 4.1.4 sun4-sunos 
    sunos 5.6 sun4-solaris

=head1 SEE ALSO

Jef Pearlman's Javascript Tree class 
(http://developer.netscape.com/docs/examples/dynhtml/tree.html)

=head1 BUGS

The Javascript sitemap has only been tested on Netscape 4.05.

=head1 AUTHOR

Ave Wrigley E<lt>Ave.Wrigley@itn.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Canon Research Centre Europe. All rights reserved.

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SCRIPT CATEGORIES

Web

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

use Date::Format;
use Getopt::Long;
use HTML::Entities;
use URI::URL;

require WWW::Sitemap;
require IO::File;

#------------------------------------------------------------------------------
#
# Public global variables
#
#------------------------------------------------------------------------------

use vars qw( 
    $NAME 
    $VERSION 
    $CONTACT 
    $WHEN 
    $HEADER 
    $FOOTER 
    %DOC2POD
    %FORMATS
);

# command line options - see pod

use vars qw (
    $opt_verbose
    $opt_version
    $opt_help
    $opt_doc
    $opt_authen
    $opt_depth
    $opt_title
    $opt_summary
    $opt_format
    $opt_url
    $opt_email
    $opt_proxy
    $opt_envproxy
    $opt_agent
    $opt_output
    $opt_gui
);

#------------------------------------------------------------------------------
#
# Initialize global variables
#
#------------------------------------------------------------------------------

( $NAME ) = $0 =~ m{([^/]+)$};

$CONTACT = 'Ave.Wrigley@itn.co.uk';
$VERSION = '1.019';
$WHEN = time2str( "on %A the %o of %B %Y at %r", time );
$HEADER = sub {
    my $title = shift;

    return <<HTML_HEADER;
<HTML>
    <HEAD>
        <TITLE>$title</TITLE>
    </HEAD>
    <BODY BGCOLOR = "#FFFFFF">
        <H1>$title</H1>
        <HR NOSHADE>
HTML_HEADER
};
$FOOTER = <<FOOTER;
        <HR NOSHADE>
        <TABLE WIDTH = "100%">
            <TR>
                <TD VALIGN = "TOP" ALIGN = "LEFT">
                    $NAME version $VERSION
                </TD>
                <TD VALIGN = "TOP" ALIGN = "RIGHT">
                    <A HREF = "mailto:$CONTACT">$CONTACT</A>
                </TD>
            </TR>
            <TR>
                <TD COLSPAN = 2 VALIGN = "TOP" ALIGN = "LEFT">
                    Generated $WHEN
                </TD>
            </TR>
        </TABLE>
FOOTER

%DOC2POD        = (
    doc         => [ 2, 0 ],
    help        => [ 1, 0 ],
    usage       => [ 0, 1 ],
);

%FORMATS = (
        html    => [ 'HTML Files', [ '.html', '.htm' ] ],
        text    => [ 'Text Files', [ '.txt', '.text' ] ],
        js      => [ 'HTML Files', [ '.html', '.htm' ] ],
        xml     => [ 'XML Files', [ '.xml' ] ],
);

#------------------------------------------------------------------------------
#
# Set command line option defaults
#
#------------------------------------------------------------------------------

$opt_verbose = 0;
$opt_authen = 0;
$opt_envproxy = 1;

#------------------------------------------------------------------------------
#
# Display hashes - these hashes are used to print out sitemap, using
# $opt_format as a key
#
#------------------------------------------------------------------------------

my %print_start_all_lists = (
    'js'        => sub { print '"[' },
    'html'        => sub { 
        print <<START_LIST;
        <UL>
START_LIST
    },
    'text'        => sub { },
);

my %print_end_all_lists = (
    'js'        => sub { print ']"' },
    'html'        => sub { 
        print <<END_LIST;
        </UL>
END_LIST
    },
    'text'        => sub { },
);

my %print_start_list = (
    'js'        => sub { print '[' },
    'html'        => sub { print '<UL>' },
    'text'        => sub { },
);

my %print_end_list = (
    'js'        => sub { print '],' },
    'html'        => sub { print '</UL>' },
    'text'        => sub { },
);

my %print_node = (
    'js'        => sub {
        my $url         = shift;
        my $depth       = shift;
        my $title       = shift || "[No Title]";
        my $summary     = shift || "[No Summary]";

        # ditch the funny stuff

        $title = encode_entities( $title, "^a-z0-9A-Z " );
        $summary = encode_entities( $summary, "^a-z0-9A-Z " );

        print "'<DD><DT><A HREF = \\\"$url\\\">$title</A></DT><DD>$summary</DD></DL>',";
    },
    'html'        => sub {
        my $url         = shift;
        my $depth       = shift;
        my $title       = shift || "[No Title]";
        my $summary     = shift || "[No Summary]";

        print <<HTML_NODE;
            <LI>
                <DL>
                    <DT>
                        <B><A HREF = "$url">$title</A></B>
                    </DT>
                    <DD>
                        $summary
                    </DD>
                </DL>
            </LI>
HTML_NODE
    },
    'text' => sub {
        my $url         = shift;
        my $depth       = shift;
        my $title       = shift;

	print "  " x $depth, $url, "::", $title, "\n";
	return;
    },
);

my %print_page_start = (
    'js'        => sub {
        my $title   = shift;

        print $HEADER->( $title );
        print join( '', <DATA> );
        print <<JS;
<SCRIPT LANGUAGE = "JavaScript">
    firstTree = new Tree ( 
        { 
            id:
                "sitemap", 
            items:
JS
        ;
    },
    'html'        => sub {
        print $HEADER->( shift );
    },
    'text'      => sub { 
        my $title = shift;

       print "$title\n", "-" x 80, "\n";
    },
);

my %print_page_end = (
    'js'        => sub {
        print <<JAVASCRIPT_FOOTER;
});
</SCRIPT>
<LAYER ID = "Footer">
    <TABLE BORDER=1>
        <TR><TD>+</TD>
        <TD>Click to expand sub-pages</TD>
        <TR><TD>-</TD>
        <TD>Click to contract sub-pages</TD>
        <TR><TD>o</TD>
        <TD>No sub-pages</TD>
    </TABLE>
    $FOOTER
</LAYER>
<SCRIPT LANGUAGE = "JavaScript">
    Reposition_footer();
</SCRIPT>
</BODY>
</HTML>
JAVASCRIPT_FOOTER
    },
    'html'        => sub {
        print $FOOTER, <<HTML_FOOTER;
    </BODY>
</HTML>
HTML_FOOTER
    },
    'text'      => sub { 
        my $title = shift;

       print "-" x 80, "\n";
       print "Generated ", $WHEN, "\n";
       print "$NAME version $VERSION $CONTACT\n";
    },
);

#==============================================================================
#
# Some utility functions
#
#==============================================================================

#------------------------------------------------------------------------------
#
# verbose - print a message to STDERR, if the -verbose flag is set
#
#------------------------------------------------------------------------------

sub verbose {
    print STDERR @_, "\n" if $opt_verbose;
};

#------------------------------------------------------------------------------
#
# autoloader for documentation stuff
#
#------------------------------------------------------------------------------

sub AUTOLOAD {
    use vars qw( $AUTOLOAD );
    require 'Pod/Usage.pm';
    import Pod::Usage;
    my ( $function ) = $AUTOLOAD =~ m/.*::(.*)/;
    return unless exists( $DOC2POD{ $function } );
    pod2usage( 
        'verbose' => $DOC2POD{ $function }[ 0 ],
        'exitval' => $DOC2POD{ $function }[ 1 ]
    );
}

#------------------------------------------------------------------------------
#
# check_options - check that a command line option conforms for a specified
# format
#
#------------------------------------------------------------------------------

sub check_options {
    my $option_name     = shift;
    my $options         = shift;
    my $default         = shift;

    eval "\$opt_$option_name ||= '$default'";
    my $regex = '(' . join( '|', @$options ) . ')' ;
    eval <<USAGE;
usage( '-$option_name option must be one of $regex' )
    unless \$opt_$option_name =~ /^$regex\$/i
;
USAGE
    eval "\$opt_$option_name = lc( \$opt_$option_name )";
};

#==============================================================================
#
# Start of main
#
#==============================================================================

usage() unless GetOptions qw(
    help 
    doc 
    verbose=i
    version 
    authen
    depth=i
    url=s
    output=s
    envproxy!
    proxy=s
    agent=s
    title=s
    email=s
    summary=i
    format=s
    gui
);

help() if $opt_help;
doc() if $opt_doc;
print "$VERSION\n" and exit( 0 ) if $opt_version;

check_options( 'format', [ 'xml', 'js', 'text', 'html' ], 'html' );

#------------------------------------------------------------------------------
#
# Turn on autoflushing
#
#------------------------------------------------------------------------------

$|++;

get_options_from_gui() and exit if $opt_gui;
create_sitemap();

#==============================================================================
#
# End of main
#
#==============================================================================

#==============================================================================
#
# Subroutines
#
#==============================================================================

#------------------------------------------------------------------------------
#
# create_sitemap
#
#------------------------------------------------------------------------------

sub create_sitemap
{
    my $callback = shift;

    # select output file handle if $opt_output is defined

    if ( defined( $opt_output ) )
    {
        die "$opt_output : $!\n" unless open( OUTPUT_FH, ">$opt_output" );
        select OUTPUT_FH;
    }

    usage( '-url argument is required' ) unless $opt_url;
    my $ua = create_useragent();
    my $sitemap = new WWW::Sitemap
        EMAIL               => $opt_email || 'your@email.address',
        USERAGENT           => $ua,
        ROOT                => $opt_url,
        SUMMARY_LENGTH      => $opt_summary || 200,
        DEPTH               => $opt_depth,
        VERBOSE             => $opt_verbose,
    or die "new WWW::Sitemap failed\n";
    if ( defined $callback )
    {
        $sitemap->url_callback(
            sub {
                my ( $url, $depth, $title, $summary ) = @_;
                $callback->( "$url ...\n" );
            }
        );
    }
    $sitemap->generate();
    print_sitemap( $sitemap );
}

#------------------------------------------------------------------------------
#
# create_useragent() - create the useragent, and set the http proxy, if
# necessary
#
#------------------------------------------------------------------------------

sub create_useragent
{
    my $ua;

    if ( $opt_authen )
    {
        require LWP::AuthenAgent;
        $ua = new LWP::AuthenAgent;
    }
    else
    {
        require LWP::UserAgent;
        $ua = new LWP::UserAgent;
    }

    # Set the proxy from the environment or the proxy option

    if ( defined( $opt_proxy ) )
    {
        verbose( "proxy = $opt_proxy ..." );
        $ua->proxy( [ 'http' ], $opt_proxy );
    }
    elsif ( $opt_envproxy and exists( $ENV{ http_proxy } ) )
    {
        verbose( "getting proxy from environment ..." );
        verbose( "proxy = $ENV{ http_proxy } ..." );
        $ua->env_proxy();
    }
    else
    {
        verbose( "no proxy ..." );
        $ua->no_proxy();
    }

    if ( $opt_agent )
    {
        verbose( "Setting agent to $opt_agent ..." );
        $ua->agent( $opt_agent );
    }

    return $ua;
}

#------------------------------------------------------------------------------
#
# print_sitemap() - print the sitemap, according to $opt_format
#
#------------------------------------------------------------------------------

sub print_sitemap()
{
    my $sitemap = shift;

    # Print out the link graph, if $opt_format is 'xml' ...

    if ( $opt_format eq 'xml' )
    {
        print_xml_link_graph( $sitemap );
        return;
    }

    $print_page_start{ $opt_format }->( 
        defined( $opt_title ) ? $opt_title : "Site map for $opt_url" 
    );
    $print_start_all_lists{ $opt_format }->( );
    $sitemap->traverse(
        sub {
            my ( $sitemap, $url, $depth, $flag ) = @_;
            if ( $flag == 0 )
            {
                $print_start_list{ $opt_format }->( );
            }
            elsif( $flag == 1 )
            {
                my $title = $sitemap->title( $url );
                my $summary = $sitemap->summary( $url );
                $print_node{ $opt_format }->( $url, $depth, $title, $summary );
            }
            elsif( $flag == 2 )
            {
                $print_end_list{ $opt_format }->( );
            }
        }
    );
    $print_end_all_lists{ $opt_format }->( );
    $print_page_end{ $opt_format }->( );
}

#------------------------------------------------------------------------------
#
# print_xml_link_graph - print an XML format graph of all the URLs and links
#
#------------------------------------------------------------------------------

sub print_xml_link_graph
{
    my $sitemap = shift;

    printf <<ROOT, $sitemap->root();
<ROOT ID = "%s"/>
ROOT
    for my $from_url ( $sitemap->urls() )
    {
        for my $to_url ( $sitemap->links( $from_url ) )
        {
            print <<LINK;
<LINK FROM = "$from_url" TO = "$to_url"/>
LINK
        }
    }
    for my $url ( $sitemap->urls() )
    {
        my $title = $sitemap->title( $url );
        my $summary = $sitemap->summary( $url );

        $title = encode_entities( $title );
        $summary = encode_entities( $summary );

        print <<URL;
<URL
    ID          = "$url"
    TITLE       = "$title"
    SUMMARY     = "$summary"
/>
URL
    }
}

#------------------------------------------------------------------------------
#
# report_error - pop up a Tk error dialog box 
#
#------------------------------------------------------------------------------

sub report_error
{
    my $mw = shift;
    my $msg = shift;

    my $errorBox = $mw->Dialog(
        -title	        => 'Error: ',
    );
    $errorBox->configure(
        -wraplength     => '4i',
        -text	        => $msg,
    );
    $errorBox->Show;
}

#------------------------------------------------------------------------------
#
# get_options_from_gui()
#
#------------------------------------------------------------------------------

sub get_options_from_gui
{

    require Tk;
    import Tk;

    require Tk::ROText;
    require Tk::Dialog;

    # the main window

    my $mw = MainWindow->new;

    # the about diolog

    my $diAbout = $mw->Dialog(
            -title	=> 'About: ',
    );
    $diAbout ->configure(
            -wraplength => '4i',
            -text	=> <<ABOUT_TEXT,

sitemapper $VERSION by Ave Wrigley 
    <Ave.Wrigley\@itn.co.uk>
Tk GUI version by Nicholas Marshall 
    <nmarshall\@pbs.org>
            
This script is free software; you can 
redistribute it and/or modify it under
the same terms as Perl itself.

ABOUT_TEXT
    );


    # the menu bar 

    my $menu = $mw->Frame(
        -relief         => 'raised',
        -borderwidth    => 2
    );
    $menu->pack( -fill => 'x' );

    my $menuFile = $menu->Menubutton(
        -text           => 'File' , 
        -underline      => 0
    );
    $menuFile->command(
        -label          =>'Exit', 
        -command        => [ sub{ exit }, 'Exit' ]
    );
    $menuFile->pack( -side => 'left' );

    my $menuHelp = $menu->Menubutton(
        -text           => 'Help', 
        -underline      => 0
    );
    $menuHelp->command(
        -label          =>'About',
        -command        => [ sub{ $diAbout->Show } ] 
    );
    $menuHelp->pack( -side => 'right' );

    # the url widget ...

    my $urlFrame = $mw->Frame;
    $urlFrame->pack( -fill => 'x' );

    my $urlLabel = $urlFrame->Label( 
        -text           => 'Enter target URL:'
    );
    $urlLabel->pack( -side => 'left');

    my $urlEntry = $urlFrame->Entry(
        -width          => 40,
        -textvariable   => \$opt_url,
    );
    $urlEntry->pack( -side => 'right');

    # the email widget ...

    my $emailFrame = $mw->Frame;
    $emailFrame->pack( -fill => 'x');

    my $emailLabel = $emailFrame->Label(
        -text           => 'Enter your email:'
    );
    $emailLabel->pack( -side => 'left');

    my $emailEntry = $emailFrame->Entry(
        -textvariable   => \$opt_email,
    );
    $emailEntry->pack( -side => 'right');

    # the depth widget ...

    my $depthFrame = $mw->Frame;
    $depthFrame->pack( -fill => 'x');

    my $depthLabel = $depthFrame->Label(
        -text           => 'Enter how deep to go:'
    );
    $depthLabel->pack( -side => 'left');

    my $depthEntry = $depthFrame->Entry(
        -textvariable   => \$opt_depth,
    );
    $depthEntry->pack( -side => 'right');

    # the format widget ...

    my $formatRB = $mw->Frame;
    $formatRB->pack( -fill => 'x' );

    my $formatLabel = $formatRB->Label(
        -text           => 'Output Format?'
    );
    foreach my $format ( keys %FORMATS )
    {
        $formatRB->Radiobutton(
            -text       => $format,
            -variable   => \$opt_format,
            -relief     => 'flat',
            -value      => lc( $format ),
        )->pack(-side => 'right' );
    }
    $formatLabel->pack( -side => 'left');

    # the output widget ...

    my $outputFrame = $mw->Frame(
        -relief         => 'flat',
        -borderwidth    => 0
    );
    $outputFrame->pack( -fill => 'x');

    my $outputLabel = $outputFrame->Label(
        -text           => 'Select the output file:'
    );
    $outputLabel->pack( -side => 'left');

    my $outputEntry = $outputFrame->Entry( 
        -width          => 20,
        -textvariable   => \$opt_output,
    );
    $outputEntry->pack( -side => 'left');

    my $outputButton = $outputFrame->Button( 
        -text           => 'Browse..',
        -command        => sub{
            my $file = $mw->getSaveFile(
                -filetypes => [ 
                    $FORMATS{ $opt_format }, 
                    [ 'All files',  '*' ] 
                ],
                -initialfile => 'Untitled',
                -defaultextension => $FORMATS{ $opt_format }->[ 1 ][ 0 ]
            );
            if ( defined $file and $file ne '' ) 
            {
                $outputEntry->delete( 0, 'end' );
                $outputEntry->insert( 0, $file );
                $outputEntry->xview( 'end' );
            }
        },

    );
    $outputButton->pack( -side => 'left');

    my $status_text;

    my $pid;

    my $statusBox = $mw->Scrolled( 'ROText' );

    my $attackButton = $mw->Button( 
        -text           => 'Generate Sitemap',
        -command        => sub {
            report_error( $mw, "No URL Specified" ) and return 
                unless $opt_url
            ;
            report_error( $mw, "No format specified" ) and return 
                unless $opt_format
            ;
            # report_error( $mw, "No depth specified" ) and return 
                # unless $opt_depth
            # ;
            report_error( $mw, "No output specified" ) and return 
                unless $opt_output
            ;

            $statusBox->insert( 'end', "Generating sitemap of $opt_url\n" );
            $statusBox->yview( 'end' );

            create_sitemap(
                sub {
                    my $text = shift;
                    $statusBox->insert( 'end', $text );
                    $statusBox->yview( 'end' );
                    $mw->update();
                }
            );

            $statusBox->insert( 'end', "Sitemap of $opt_url written to $opt_output\n" );
            $statusBox->yview( 'end' );

            $mw->Dialog(
                -text           => 'Sitemap generation complete',
                -buttons        => [ 'Exit' ],
            )->Show();
            exit;
        }
    );
    $attackButton->pack;
    $statusBox->pack;
    MainLoop();
}

#==============================================================================
#
# End of subroutines
#
#==============================================================================

#==============================================================================
#
# JavaScript Code - Jef Pearlman's (jef@mit.edu) Tree class
# http://developer.netscape.com/docs/examples/dynhtml/tree.html
#
#==============================================================================

__END__

<SCRIPT LANGUAGE = "JavaScript">

// Tree.js
//
// Javascript expandable/collapsable tree class.
// Written by Jef Pearlman (jef@mit.edu)
// 
///////////////////////////////////////////////////////////////////////////////

// class Tree 
// {
//   public: 
//       // These functions can be used to interface with a tree. 
//     void TreeView(params);
//       // Constructs a TreeView. Params must be an object containing the
//       // following properties:
//       // id: UNIQUE id for the tree
//       // items: Nested array of strings and arrays determining the tree 
//       //        structure and content.
//       // x: Optional x position for tree.
//       // y: Optional y position for tree.
//     int getHeight();
//       // Returns the height of the tree, fully expanded.
//     int getWidth();
//       // Returns the width of the widest section of the tree, 
//       // fully expanded.
//     int getVisibleHeight();
//       // Returns the height of the visible tree.
//     int getVisibleWidth();
//       // Returns the width of the widest visible section of the tree. 
//     int getX();
//       // Returns the x position of the tree. 
//     int getY();
//       // Returns the y position of the tree.
//     Object getLayer();
//       // Returns the layer object enclosing the entire tree.
// }

function TreeNode(content, enclosing, id, depth, y)
     // Constructor for a TreeNode object, creates the appropriate layers
     // and sets the required properties.
{
  this.id = id;
  this.enclosing = enclosing;
  this.children = new Array;
  this.maxChild = 0;
  this.expanded = false;
  this.getWidth = TreeNode_getWidth;
  this.getVisibleWidth = TreeNode_getVisibleWidth;
  this.getHeight = TreeNode_getHeight;
  this.getVisibleHeight = TreeNode_getVisibleHeight;
  this.layout = TreeNode_layout;
  this.relayout = TreeNode_relayout;
  this.childLayer = null;
  this.parent = this.enclosing.node;
  this.tree = this.parent.tree;
  this.depth = depth;

  // Write out the content for this item.
  // Ave - replaced gifs with + / - / o
  document.write("<LAYER TOP="+y+" LEFT="+(this.depth*10)+" ID=Item"+this.id+">");
  document.write("<LAYER ID=Buttons WIDTH=9 HEIGHT=9>");
  document.write("<LAYER ID=Minus VISIBILITY=HIDE WIDTH=9 HEIGHT=9>-</LAYER>");
  document.write("<LAYER ID=Plus WIDTH=9 VISIBILITY=HIDE HEIGHT=9>+</LAYER>");
  document.write("<LAYER ID=Disabled VISIBILITY=INHERIT WIDTH=9 HEIGHT=9>o</LAYER>");
  document.write("</LAYER>"); // Buttons
  this.layer = this.enclosing.layers['Item'+this.id];
  this.layers = this.layer.layers;
  document.write("<LAYER ID=Content LEFT="+(this.layers['Buttons'].x+10)+">"+content+"</LAYER>");
  document.write("</LAYER>"); // Item

  // Move the buttons to the right position (centered vertically) and
  // capture the appropriate events.
  // Ave - now aligned top
  //this.layers['Buttons'].moveTo(this.layers['Buttons'].x, this.layers['Content'].y+((this.layers['Content'].document.height-9)/2));
  this.layers['Buttons'].moveTo(this.layers['Buttons'].x, this.layers['Content'].y);
  this.layers['Buttons'].layers['Plus'].captureEvents(Event.MOUSEDOWN);
  this.layers['Buttons'].layers['Plus'].onmousedown=TreeNode_onmousedown_Plus;
  this.layers['Buttons'].layers['Plus'].node=this;
  this.layers['Buttons'].layers['Minus'].captureEvents(Event.MOUSEDOWN);
  this.layers['Buttons'].layers['Minus'].onmousedown=TreeNode_onmousedown_Minus;
  this.layers['Buttons'].layers['Minus'].node=this;

  // Note the height and width;
  this.height=this.layers['Content'].document.height;
  this.width=this.layers['Content'].document.width + 10 + (depth*10);
}

function Tree_build(node, items, depth, nexty)
     // Recursive function builds a tree, starting at the current node
     // using the items in items, starting at depth depth, where nexty
     // is where to locate the new layer to be placed correctly.
{
  var i;
  var nextyChild=0;

  if (node.tree.version >= 4)
    {
      // Create the layer for all the children.
      document.write("<LAYER TOP="+nexty+" VISIBILITY=HIDE ID=Children>");
      node.childLayer = node.enclosing.layers['Children'];
      node.childLayer.node = node;
    }
  else
    {
      // For Navigator 3.0, create a nested unordered list.
      document.write("<UL>");
    }

  for (i=0; i<items.length; i++)
    {
      if(typeof(items[i]) == "string")
	{
	  if (node.tree.version >= 4)
	    {
	      // Create a new node as the next child.
	      node.children[node.maxChild] = new TreeNode(items[i], node.childLayer, node.maxChild, depth, nextyChild);
	      nextyChild+=node.children[node.maxChild].height;
	    }
	  else
	    {
	      // Create a new item.
	      document.write("<LI>"+items[i]);
	    }
	  node.maxChild++;
	}
      else
	if (node.maxChild > 0)
	  {
	    // Build a new tree using the nested items array, placing it
	    // under the last child created.
	    if (node.tree.version >= 4)
	      {
		Tree_build(node.children[node.maxChild-1], items[i], depth+1, nextyChild);    
		nextyChild+=node.children[node.maxChild-1].getHeight()-node.children[node.maxChild-1].height;
		node.children[node.maxChild-1].layer.layers['Buttons'].layers['Disabled'].visibility="hide";
		node.children[node.maxChild-1].layer.layers['Buttons'].layers['Plus'].visibility="inherit";
	      }
	    else
	      Tree_build(node, items[i], depth+1, nextyChild);    
	  }
    }
  
  // End the layer or nested unordered list.
  if (node.tree.version >= 4)
    document.write("</LAYER>"); // childLayer
  else
    {
      document.write("</UL>");
    }

}

function Reposition_footer( )
{
    var footer = document.layers[ "Footer" ];
    if ( footer != null )
    {
        footer.moveTo( 5, firstTree.getY() + firstTree.getVisibleHeight() );
    }
}

function TreeNode_onmousedown_Plus(e)
     // Handle a mouse down on a plus (expand).
{
  var node=this.node;
  var oldHeight=node.getVisibleHeight();
  // Switch the buttons, set the current node expanded, and
  // relayout everything below it before before displaying the node.
  node.layers['Buttons'].layers['Minus'].visibility="inherit";
  node.layers['Buttons'].layers['Plus'].visibility="hide";
  node.expanded=true;
  node.parent.relayout(node.id,node.getVisibleHeight()-oldHeight);
  node.childLayer.visibility='inherit';
  Reposition_footer();
  return false;
}

function TreeNode_onmousedown_Minus(e)
     // Handle a mouse down on a minus (collapse).
{
  var node=this.node;
  var oldHeight=node.getVisibleHeight();
  // Switch the buttons, set the current node collapsed, and
  // hide the node before relaying out everything below it.
  node.layers['Buttons'].layers['Plus'].visibility="inherit";
  node.layers['Buttons'].layers['Minus'].visibility="hide";
  node.expanded=false;
  node.childLayer.visibility='hide';
  node.parent.relayout(node.id,node.getVisibleHeight()-oldHeight);  
  Reposition_footer();
  return false;
}

function TreeNode_getHeight()
     // Get the Height of the current node and it's children.
{
  // Recursively add heights.
  var h=0, i;
  for (i = 0; i < this.maxChild; i++)
    h += this.children[i].getHeight();
  h += this.height;
  return h;
}

function TreeNode_getVisibleHeight()
     // Get the Height of the current node and it's visible children.
{
  // Recursively add heights. Only recurse if expanded.
  var h=0, i;
  if (this.expanded)
    for (i = 0; i < this.maxChild; i++)
      h += this.children[i].getVisibleHeight();
  h += this.height;
  return h;
}

function TreeNode_getWidth()
     // Get the max Width of the current node and it's children.
{
  // Find the max width by recursively comparing.
  var w=0, i;
  for (i=0; i<this.maxChild; i++)
    if (this.children[i].getWidth() > w)
      w = this.children[i].getWidth();
  if (this.width > w)
    return this.width;
  return w;
}

function TreeNode_getVisibleWidth()
     // Get the max Width of the current node and it's visible children.
{
  // Find the max width by recursively comparing. Only recurse if expanded.
  var w=0, i;
  if (this.expanded)
    for (i=0; i<this.maxChild; i++)
      if (this.children[i].getVisibleWidth() > w)
	w = this.children[i].getVisibleWidth();
  if (this.width > w)
    return this.width;
  return w;
}

function TreeView_getX()
     // Get the x location of the main tree layer.
{
  // Return the x property of the main layer.
  return document.layers[this.id+"Tree"].x;
}

function TreeView_getY()
     // Get the y location of the main tree layer.
{
  // Return the y property of the main layer.
  return document.layers[this.id+"Tree"].y;
}

function getLayer()
     // Get the main layer object.
{
  // Returnt he main layer.
  return document.layers[this.id+"Tree"];
}

function TreeNode_layout()
     // Layout the entire tree from scratch, recursively.
{
  var nexty=0, i;
  // Set the layer visible if expanded, hidden if not.
  if (this.expanded)
    this.childLayer.visibility="inherit";
  else
    if (this.childLayer != null)
      this.childLayer.visibility="hide";
  // If there is a child layer, move it to the appropriate position, and
  // move the children, laying them each out in turn.
  if (this.childLayer != null)
    {
      this.childLayer.moveTo(0, this.layer.y+this.height);
      for (i=0; i<this.maxChild; i++)
	{
	  this.children[i].layer.moveTo((this.depth+1)*10, nexty);
	  this.children[i].layout();
	  nexty+=this.children[i].height;
	}
    }
}

function TreeNode_relayout(id, movey)
{
  // Move all children physically below the current child number id of
  // the current node. Much faster than doing a layout() each time.

  // Move all children _after_ this child.
  for (id++;id<this.maxChild; id++)
    {
      this.children[id].layer.moveBy(0, movey);
      if (this.children[id].childLayer != null)
	this.children[id].childLayer.moveBy(0, movey);
    }
  // If there is a parent, move all of its children below this node,
  // recursively.
  if (this.parent != null)
    this.parent.relayout(this.id, movey);
}

function Tree(param)
     // Instantiates a tree and displays it, using the items, id, and optional
     // x and y in param.
{
  // Set up member variables and functions. Also duplicate important TreeNode
  // member variables so this can serve as a TreeNode (vaguely like 
  // subclassing)
  this.version=eval(navigator.appVersion.charAt(0));
  this.id = param.id;
  this.children = new Array;
  this.maxChild = 0;
  this.expanded = true;
  this.layout = TreeNode_layout;
  this.relayout = TreeNode_relayout;
  this.getX = TreeView_getX;
  this.getY = TreeView_getY;
  this.getWidth = TreeNode_getWidth;
  this.getVisibleWidth = TreeNode_getVisibleWidth;
  this.getHeight = TreeNode_getHeight;
  this.getVisibleHeight = TreeNode_getVisibleHeight;
  this.depth = -1;
  this.height = 0;
  this.width = 0;
  this.tree = this;
  var items = eval(param.items);

  var left = "";
  var top = "";
  if (param.x != null && param.x != "")
    left += " LEFT="+param.x;
  if (param.y != null && param.y != "")
    top += " TOP="+param.y;


  if (this.version >= 4)
    {
      // Create a surrounding layer to guage size and control the entire tree.
      // Also create a secondary internal layer so that the code can treat
      // the tree itself correctly as a node (must have an enclosing layer
      // and a children layer).
      document.write("<LAYER VISIBILITY=HIDE ID="+this.id+"Tree"+left+top+">");
      document.write("<LAYER ID=mainLayer>");
      this.enclosing = document.layers[this.id+"Tree"].layers['mainLayer'];
      this.layers = this.enclosing.layers;
      this.layer = this.enclosing;
      this.enclosing.node = this;
    } 

  Tree_build(this, items, 0, 0); // Build the tree.
  
  if (this.version >= 4)
    {
      // Finish output, record size;
      document.write("</LAYER></LAYER>");
      this.layout();
      document.layers[this.id+"Tree"].visibility="inherit";
    }
}
</SCRIPT>
