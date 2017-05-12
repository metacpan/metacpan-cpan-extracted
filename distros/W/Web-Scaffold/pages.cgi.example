#!/usr/bin/perl
#
# pages.cgi.example
# version 1.04, 11-14-11, michael@bizsystems.com
#
use Web::Scaffold;

%specs = (

# directory path for 'html pages' relative to the html root
# i.e. public_html/        defaults to:
#
	pagedir		=> '../pages',

# directory path for 'javascript libraries' relative to html root
# defaults to:

	javascript	=> 'lib',

# no search conditions for building the site map. Each
# element is evaluated as a perl match condition in the
# context of m/element/. Include page names, extensions, etc...
#
# [OPTIONAL]
#

	nosearch	=>[ 'pdf' ],

# Directory path for 'sitemap' page generation relative to the 
# html root. This directory must be WRITABLE by the web server.
#
# NOTE: link the file 'sitemapdir'/sitemaplxml to the 
# appropriate location in your web directory.
# 
# The sitemap.xml file will be generated and updated ONLY if 
# the 'sitemapdir' key is present in this configuration file.
#
# The sitemap page will auto update if you modify pages in
# 'pagedir' or in the 'autocheck' list below. If you modify 
# static pages elsewhere in the web directory tree that are
# not listed in 'autocheck', you must DELETE the sitemap.xml 
# file to force an update.
#
# [OPTIONAL]
#
	sitemapdir	=> '../ws_sitemap',

# Directories to autocheck for sitemap update.
# you can list BOTH directories and individual files
# here relative to the web root. The 'sitemapdir' and
# 'pagedir' are always checked and do not need to be
# listed here.
#
	autocheck	=> ['docs'],

# site map <changefreq> hint
#
# defaults to:
#
	changefreq	=> 'monthly',

# font family used throughout the document
#
	face		=> 'VERANDA,ARIAL,HELVETICA,SAN-SERIF',

# background color of the web page
# this can be a web color like 'white' or number '#ffffff'
#
	backcolor	=> 'white',

# Menu specifications
#
	barcolor	=> 'red',
	menudrop	=> '55',	# drop down position
	menuwidth	=> '100px',	# width of menu item
	pagewidth	=> '620px',	# recommended
# menu font specifications
	menucolor	=> 'black',
	menuhot		=> 'yellow',	# mouse over
	menucold	=> 'white',	# page selected
	menustyle	=> 'normal',	# bold, italic
	menusize	=> '13px',	# font points or pixels
	sepcolor	=> 'black',	# separator color

# Page link font specifications
#
	linkcolor	=> 'blue',
	linkhot		=> 'green',
	linkstyle	=> 'normal',	# bold, italic
	linksize	=> '13px',	# font points or pixels

# Page Text font specifications
#
 	fontcolor	=> 'black',
	fontstyle	=> 'normal',
	fontsize	=> '13px',

# Heading font specifications
#
	headcolor	=> 'black',
	headstyle	=> 'bold',	# normal, italic
	headsize	=> '16px',
);

=pod

The specifications for menus and pages. Menus can be single link or a series
of drop down menu depending on how you specifiy the page. The page names are
the keys to the hash and are used as the menu-bar link text. All page files
are placed in the 'pages' directory. 

FILE NAME SYNTAX:

Files are named with the 'key' name of the page as the lefthand side and 
a suffix designating the file's purpose as the right hand side. For the 
required page 'Home', they are as follows:

 # [optional] page used if there are not individual pages
 # NOTE: neither a Default page or individual page is required
  Default.meta		# meta text loaded after <title>
  Default.head		# optional additional <head> text
			# that is on every page, end of page
  Default.top		# optional body text that appears
			# on every page before menu-bar
			# i.e. logo, etc...
 # for each individual page
  Home.meta		# meta text loaded after <title>
  Home.head		# optional additional <head> text
  Home.top		# body text that appears before
			# menu-bar. i.e. logo, etc...
  Home.c1		# column 1 content
  Home.c2		# column 2 content
  Home.cn		# column 'n' content

=cut

my $menu = [qw(
	Home
	Schema
	Page-Source
	manpage
	Sitemap
)];

my $now = (localtime())[5] + 1900;
my $copyright = 'Copyright 2006 - '. $now .', Michael@bizsystems.com';
my $top = '|#top|TOP|TOP of page';

%pages = (

# REQUIRED page
#
	Home	=> {
	    menu	=> $menu,

# optional table row immediately under menu. This allows a "drop"
# shadow to be added to the menu bar with a "1" pixel wide image, 'example'  
	    menustripe	=> '<img src="images/stripe1.gif" height=4 width=100%>',

# optional title text - if missing, 'heading' text will be used
	    title	=> 'Web::Scaffold, a perl extension for building web sites',

	    heading	=> '&nbsp;&nbsp;&nbsp;&nbsp;A perl extension for building web sites',

# number of columns and column width in pixels
	    column	=> [20, 160, 400],    # two columns

# optional
	    submenu	=> [qw(specs pages)], # drop down menu

# optional trailer bar
	    trailer	=> {

# a named page
#		links	=> [qw(Page5 Page6)],

# optional right hand side text. if there are no links then the
# text will be placed on the left hand side of the trailer bar
		text	=> $copyright,

# optional table row immediately above trailer bar. this allows a "drop"  
# shadow to be added to trailer bar with a "1" pixel wide image, 'example'
		top	=> '<img src="images/stripe2.gif" height=4 width=100%>',

# optional table row immediately below trailer bar. This allows a "top"       
# shadow to be added to trailer bar with a "1" pixel wide image, 'example'   
		bottom	=> '<img src="images/stripe1.gif" height=4 width=100%>',
	    },
	},

	Schema	=> {
	    menu	=> $menu,
	    title	=> 'Web::Scaffold example site schema',
	    heading	=> '&nbsp;&nbsp;Site Schema for this example',
	    column	=> ['50%', '50%'],
	    submenu	=> ['Structure'],
	    trailer	=> {
		links	=> [$top,'Home'],
		text	=> $copyright,
	    },
	},
	Structure	=> {
	    menu	=> $menu,
	    menustripe	=> '<img src="images/stripe1.gif" height=4 width=100%>',
	    title	=> 'Web::Scaffold page structure',
	    heading	=> '&nbsp;&nbsp;Site schema and page structure',
	    column	=> ['50%', '50%'],
	    trailer	=> {
		links	=> [$top, 'Home'],
		text	=> $copyright,
		top	=> '<img src="images/stripe2.gif" height=4 width=100%>',
	    },
	},

	'Page-Source'	=> {
	    menu	=> $menu,
	    title	=> 'Web::Scaffold, page source text',
	    heading	=> '&nbsp;&nbsp;&nbsp;&nbsp;View the Page Source text',
	    column	=> [qw( 20 600)],
	    submenu	=> [qw(
			Default.meta Default.head Default.top 
			Home.meta Home.c2 Home.c3
			manpage.c1 pages.cgi pages.c2 specs.c2
			scaffold.js winMenus.js winUtils.js
			)],
	    trailer	=> {
		links	=> [$top, 'Home'],
		text	=> $copyright,
	    },
	},
	Sitemap		=> {
	    menu	=> $menu,
	    title	=> 'Sitemap',
	    autocol	=> 2,
	    column	=> [qw( 20 600)],
	    trailer	=> {
		links	=> [$top, 'Home'],
		text	=> $copyright,
	    },
	},
	manpage		=> {
	    menu	=> $menu,
	    heading	=> 'Web::Scaffold manpage',
	    trailer	=> {
		links	=> [$top, 'Home'],
		text	=> $copyright,
	    },
	},
	specs		=> {
	    menu	=> $menu,
	    heading	=> 'Typical specification hash: %specs, (from POD)',
	    column	=> [20, 600],
	    trailer	=> {
		links	=> ['|#top|TOP|TOP of page','Home'],
		text	=> $copyright,
	    },
	},
	pages		=> {
	    menu	=> $menu,
	    heading	=> 'Typical specification hash: %pages, (from POD)',
	    column	=> [20, 600],
	    trailer	=> {
		links	=> [$top,'Home'],
		text	=> $copyright,
	    },
	},


# and for debug... example
# load this page segment as source in a single window
#            location    => 'path/to/filename',

	'Default.meta'	=> {
# copy prototype page structure from this page. 

	    debug	=> 'Page-Source',
	},
	'Default.top'	=> {
	    debug	=> 'Page-Source',
	},
	'Default.head'	=> {
	    debug	=> 'Page-Source',
	},
	'Home.meta'	=> {
	    debug	=> 'Page-Source',
	},
	'Home.c2'	=> {
	    debug	=> 'Page-Source',
	},
	'Home.c3'	=> {
	    debug	=> 'Page-Source',
	},
	'manpage.c1'	=> {
	    debug	=> 'Page-Source',
	},
	'pages.c2'	=> {
	    debug	=> 'Page-Source',
	},
	'specs.c2'	=> {
	    debug	=> 'Page-Source',
	},
	'pages.cgi'	=> {
	    debug	=> 'Page-Source',
	    location	=> './pages.cgi',
	},
	'scaffold.js'	=> {
	    debug	=> 'Page-Source',
	    location	=> 'lib/scaffold.js',
	},
	'winUtils.js'	=> {
	    debug	=> 'Page-Source',
	    location	=> 'lib/winUtils.js',
	},
	'winMenus.js'	=> {
	    debug	=> 'Page-Source',
	    location	=> 'lib/winMenus.js',
	},
#
#	... and so on

);

Web::Scaffold::build(\%specs,\%pages);
