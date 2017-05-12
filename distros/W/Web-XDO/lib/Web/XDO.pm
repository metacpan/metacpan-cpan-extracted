package Web::XDO;
use strict;
use CGI;
use URI::URL;
use String::Util ':all';

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# VERSION
our $VERSION = '0.11';


=head1 NAME

Web::XDO -- static web site tool

=head1 SYNOPSIS

 #!/usr/bin/perl -wT
 use strict;
 use Web::XDO;
 
 # variables
 my ($xdo);
 
 # get XDO object
 $xdo = Web::XDO->new();
 
 # custom configurations here
 
 # output XDO page
 $xdo->output();

=head1 DESCRIPTION

XDO ("extensible document objects") is a tool for creating simple static web
sites.  Full documentation for XDO is in the
L<official web site|http://www.idocs.com/xdo/>. This POD documentation focuses
on the internals of Web::XDO.

=head1 INSTALLATION

The module Web::XDO can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

After you install Web::XDO you should check out the
L<online installation guide|http://idocs.com/xdo/guides/version-0-10/install/>
for the remaining steps.

=head1 OVERVIEW

Web::XDO is called from a Perl CGI script that you write. The script should
look something like this:

 #!/usr/bin/perl -wT
 use strict;
 use Web::XDO;
 
 # variables
 my ($xdo);
 
 # get XDO object
 $xdo = Web::XDO->new();
 
 # custom configurations here
 
 # output XDO page
 $xdo->output();

The $xdo object does all the work or creating a CGI object, parsing and
processing the contents of the .xdo page, and outputing the results.  This POD
page documents thos internals.

=head1 CLASSES

=head2 Web::XDO

=cut

#------------------------------------------------------------------------------
# new
#

=head3 Web::XDO->new()

Web::XDO->new() creates a new Web::XDO object. It takes no parameters or
options.

 # get XDO object
 $xdo = Web::XDO->new();

=cut

sub new {
	my ($class) = @_;
	my $xdo = bless {}, $class;
	
	# TESTING
	# println $class, '->new()'; ##i
	
	# build and untaint document root
	# NOTE: I'm not real satisfied with this technique for getting the document
	# root. It's based on an environment variable (i.e. external data) and the
	# only security check is to make sure the directory really exists. If
	# someone could find a way to change $ENV{'DOCUMENT_ROOT'} to, say, /etc
	# then they could easily read /etc/passwd.  For now using this technique
	# because I can't think of a better way to get the document root.
	$xdo->{'document_root'} = $ENV{'DOCUMENT_ROOT'};
	
	# make sure document root really exists
	unless (-r($xdo->{'document_root'}) && -d($xdo->{'document_root'})) {
		die "do not find document root $xdo->{'document_root'}";
	}
	
	# clean up document root a little
	$xdo->{'document_root'} =~ s|/*$||s;
	
	# initialize some other properties
	$xdo->{'nested'} = {};
	$xdo->{'cgi'} = CGI->new();
	$xdo->{'cgi_params'} = {};
	
	# root of XDO document set
	# default to /
	$xdo->{'root'} = '/';
	
	# file name of directory index file
	# defaults to index.xdo
	$xdo->{'directory_index'} = 'index.xdo';
	
	# set tag definitions
	$xdo->initial_tag_defs();
	
	# TESTING
	# showcgi($xdo->{'cgi'});
	
	# return
	return $xdo;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# initial_tag_defs
#

=head3 $xdo->initial_tag_defs()

initial_tag_defs() is a private method that defines the default behavior of
XDO and HTML tags.  In subsequent releases the hash of tag definitions will be
configurable.

=cut

sub initial_tag_defs {
	my ($xdo) = @_;
	my ($classes, $tags);
	
	# TESTING
	# println '$xdo->initial_tag_defs()'; ##i
	
	# initialize tag definitions
	$tags = $xdo->{'tags'} = {};
	
	# convenience: get tag classes hash
	$classes = \%Web::XDO::Token::Tag::tag_classes;
	
	# loop through tag definitions
	TAG_LOOP:
	foreach my $tag_name (keys %$classes) {
		my ($def);
		
		# get definition
		$def = $classes->{$tag_name};
		
		# if definition isn't a hash, make it one
		unless (UNIVERSAL::isa $def, 'HASH') {
			$def = {class=>$def};
		}
		
		# hold on to definition
		$tags->{$tag_name} = $def;
	}
	
	# add some default definitions for adjust root attributes
	# Yes, these definitions include some pretty ancient tags. Go with it.
	$tags->{'img'}     =  {adjust_for_root => [qw{src lowsrc}]                      };
	$tags->{'link'}    =  {adjust_for_root => [qw{href}]                            };
	$tags->{'applet'}  =  {adjust_for_root => [qw{code codebase}]                   };
	$tags->{'base'}    =  {adjust_for_root => [qw{href}]                            };
	$tags->{'bgsound'} =  {adjust_for_root => [qw{href}]                            };
	$tags->{'body'}    =  {adjust_for_root => [qw{background}]                      };
	$tags->{'embed'}   =  {adjust_for_root => [qw{src pluginspage pluginurl href}]  };
	$tags->{'form'}    =  {adjust_for_root => [qw{action}]                          };
	$tags->{'frame'}   =  {adjust_for_root => [qw{src}]                             };
	$tags->{'iframe'}  =  {adjust_for_root => [qw{src}]                             };
	$tags->{'input'}   =  {adjust_for_root => [qw{src lowsrc}]                      };
	$tags->{'script'}  =  {adjust_for_root => [qw{src}]                             };
	$tags->{'table'}   =  {adjust_for_root => [qw{background}]                      };
	$tags->{'tr'}      =  {adjust_for_root => [qw{background}]                      };
	$tags->{'td'}      =  {adjust_for_root => [qw{background}]                      };
	$tags->{'th'}      =  {adjust_for_root => [qw{background}]                      };
}
#
# initial_tag_defs
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# output
#

=head3 $xdo->output()

output() outputs the requested XDO page. It take no params or options.

=cut

sub output {
	my ($xdo, %opts) = @_;
	my ($cgi, $top, $xdo_class, $request_path, $page_class);
	
	# TESTING
	# println '$xdo->output()'; ##i
	
	# get cgi
	$cgi = $xdo->{'cgi'};
	
	# get request path
	$request_path = $cgi->param('p');
	
	# if no cgi param, throw 400
	if (! hascontent $request_path) {
		my ($this_page);
		
		# get file name of this page
		$this_page = $0;
		$this_page =~ s|^.*/||s;
		$this_page = htmlesc($this_page);
		
		# HTTP header
		print $cgi->header(-status=>400);
		
		# page
		print <<"(HTML)";
<html>
<head>
<title>XDO: working but 400 bad request</title>
</head>
<body>
<h1><span id="http-status">400</span> Bad request</h1>
The XDO script <code>$this_page</code>
is working, but the <code>p</code> param was not sent.
</body>
</html>
(HTML)
		
		# we're done
		exit 0;
	}
	
	# if $xdo isn't an object, assume it's a class and instantiate that class
	if (ref $xdo) {
		$xdo_class = ref($xdo);
	}
	else {
		$xdo_class = $xdo;
		$xdo = $xdo->new(%opts);
	}
	
	# instantiate top page object
	$page_class = $xdo->page_class();
	$top = $page_class->new('/', $request_path, $xdo);
	$top or $xdo->status_404();
	
	# note top as top
	$top->{'top'} = 1;
	
	# output headers
	print "content-type: text/html\n\n";
	
	# show source if allowed and requested, else output page
	unless ($xdo->show_src($top)) {
		$top->output();
	}
}
#
# output
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# show_src
#

=head3 $xdo->show_src()

show_src() is a private method that handles showing the XDO code when the
L<src URL parameter|http://idocs.com/xdo/guides/version-0-10/configuration/src-param/>
is sent.

=cut

sub show_src {
	my ($xdo, $top) = @_;
	my ($src_param, $src, $tokens, $file_name, $tags);
	
	# TESTING
	# println '$xdo->show_src()'; ##i
	
	# get name of show src param
	$src_param = $xdo->{'src'};
	defined($src_param) or return 0;
	
	# get src param
	$src = $xdo->{'cgi'}->param($src_param);
	$src or return 0;
	
	# get name of requested page
	$file_name = $ENV{'REDIRECT_URL'};
	
	# parse out just file name
	if (defined $file_name) {
		$file_name =~ s|^.*/||s;
		$file_name = htmlesc($file_name );
	}
	else {
		$file_name = 'this page';
	}
	
	# get token array
	$tokens = $top->{'tokens'};
	
	# get hash of tag definitions
	$tags = $xdo->{'tags'};
	
	# open page
	print <<"(HTML)";
<html>
<head>
<title>XDO source for $file_name</title>
<style type="text/css">
pre {
	border-style: solid;
	border-color: black;
	border-width: 1px;
	padding: 7px;
	margin-top: 15px;
	margin-bottom: 15px;
	background-color: #eeeeee;
}

pre em {
	color:#009999;
	font-style: normal;
	font-family: monospace;
	font-weight:bold;
}
</style>
</head>
<body>
<h1>XDO source for $file_name</h1>
<pre>
(HTML)
	
	# loop through tokens
	foreach my $token (@$tokens) {
		my ($em);
		
		# if this is an XDO-significant tag, wrap the output element
		# in <em>
		if ($xdo->xdo_significant_tag($token)) {
			print '<em>';
			$em = 1;
		}
		
		# output raw tag code
		print htmlesc($token->{'raw'});
		
		# close </em> if necessary
		$em and print '</em>';
	}
	
	print <<"(HTML)";
</pre>
</body>
</html>
(HTML)

	return 1;
}
#
# show_src
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# xdo_significant_tag
#

=head3 $xdo->xdo_significant_tag($token)

xdo_significant_tag() is a private method that returns true if the given token
is specially processed by XDO, as opposed to output as-is for tags that aren't
significant. So, for example, an
L<E<lt>includedE<gt>|/Web::XDO::Token::Tag::Include> tag is significant, but the
E<lt>i<gt> tag is not.

=cut

sub xdo_significant_tag {
	my ($xdo, $token) = @_;
	
	# if not a tag or endtag, we're done
	unless (
		UNIVERSAL::isa($token, 'Web::XDO::Token::Tag') ||
		UNIVERSAL::isa($token, 'Web::XDO::Token::EndTag')
		) {
		return 0;
	}
	
	# if this ia an XDO significant tag
	if (my $def = $xdo->{'tags'}->{$token->{'name'}}) {
		if ($def->{'class'}) {
			unless (
				($def->{'class'} eq 'Web::XDO::Token::Tag') ||
				($def->{'class'} eq 'Web::XDO::Token::EndTag')
				) {
				return 1;
			}
		}
	}
	
	# else return 0
	return 0;
}
#
# xdo_significant_tag
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# page_class
#

=head3 $xdo->page_class()

page_class() returns the class name for an object representing an XDO page.
Right now page_class() always returns Web::XDO::Page. In susequent releases
this method will allow coders to create custom classes for different types
of pages. I haven't worked out the details on how that's going to work.

=cut

sub page_class {
	return 'Web::XDO::Page';
}

#
# page_class
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# default_tag_class
#

=head3 $xdo->default_tag_class()

default_tag_class() returns the tag class used for tags that are not recognized
by XDO. In subsequent releases programmers will be able to override Web::XDO
and have this method return their own custom tag class.

=cut

sub default_tag_class {
	return 'Web::XDO::Token::Tag';
}
#
# default_tag_class
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# status_404
#

=head3 $xdo->status_404()

status_404() outputs a "404 Not Found" page and exits.  This method is called
when the requested XDO page is not found.

=cut

sub status_404 {
	my ($xdo) = @_;
	my ($cgi);
	
	# TESTING
	# println ref($page), '->status_404'; ##i
	
	# get cgi
	if ($xdo && $xdo->{'cgi'})
		{ $cgi = $xdo->{'cgi'} }
	else
		{ $cgi = CGI->new }
	
	# 404 header
	print $cgi->header(-status=>404);
	
	# message
	print
		qq|<h1><span id="http-status">404</span> Not Found</h1>\n|,
		"<p>The requested URL ",
		htmlesc($cgi->param('p')),
		" was not found on this server.</p>\n";
	
	# exit
	exit 0;
}
#
# status_404
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# adjust_url_for_root
#

=head3 $xdo->adjust_url_for_root($url)

adjust_url_for_root() is an internal method that removes
L<E<lt>xdo-rootE<gt>|/Web::XDO::Token::Tag::XdoRoot>
from the beginning of a URL and substitutes in the value of
L<$xdo-E<gt>{'root'}|http://idocs.com/xdo/guides/version-0-10/configuration/xdo-root/>.
Care is taken in this method to ensure that a single / is put between
E<lt>xdo-rootE<gt> and whatever comes after it.

=cut

sub adjust_url_for_root {
	my ($xdo, $url) = @_;
	my ($root);
	
	# TESTING
	# println ref($xdo), '->adjust_url_for_root(', $url,')'; ##i
	
	# if url doesn't start with <xdo-root> then just return url
	unless ($url =~ s|\s*\<\s*xdo\-root\s*\>\s*||si) {
		return $url;
	}
	
	# remove leading / in sent url
	$url =~ s|^\/+||s;
	
	# remove trailing / from xdo root
	$root = $xdo->{'root'};
	$root =~ s|\/+$||s;
	
	# set final url
	$url = "$root/$url";
	
	# return
	return $url;
}
#
# adjust_url_for_root
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tag_class
#

=head3 $xdo->tag_class()

tag_class() is an internal method for determining the class name for a given
tag name.  If the tag is defined in
L<$xdo-E<gt>{'tags'}|/$xdo-E<gt>initial_tag_defs()>
then that name is returned,
otherwise the value of
L<$xdo-E<gt>default_tag_class()|/$xdo-E<gt>default_tag_class()>
is returned.

In subsequent programmers will be able to superclass Web::XDO and override
this method to use their own routines for determining tag class.

=cut

sub tag_class {
	my ($xdo, $tag_name) = @_;
	
	# get tag class from tags hash
	if ($xdo->{'tags'}->{$tag_name} && $xdo->{'tags'}->{$tag_name}->{'class'}) {
		return $xdo->{'tags'}->{$tag_name}->{'class'};
	}
	else {
		return $xdo->default_tag_class;
	}
}
#
# tag_class
#------------------------------------------------------------------------------



###############################################################################
# Web::XDO::Page
#
package Web::XDO::Page;
use strict;
use String::Util ':all';
use FileHandle;
use Carp 'croak';

# subclass HTML::Parser
use base 'HTML::Parser';

# debug tools
# use Debug::ShowStuff ':all';

=head2 Web::XDO::Page

A Web::XDO::Page object represents a single XDO file.  When an XDO page is
requested, the corresponding XDO file is parsed into a Web::XDO::Page
object.  Each page that object includes is itself parsed into a Web::XDO::Page
object.

Web::XDO::Page superclasses
L<HTML::Parser|http://search.cpan.org/dist/HTML-Parser/Parser.pm>.  The XDO
file is parsed as part of Web::XDO::Page-E<gt>new().

=cut


#------------------------------------------------------------------------------
# new
#

=head3 Web::XDO::Page->new()

Web::XDO::Page->new() takes four parameters plus one optional parameter:

=over 1

=item *

$class: The name of the page class. For this release it's always
"Web::XDO::Page".

=item *

$url_root: The base page against which an absoulte URL path should be
calculated from $url_rel_path.  Yes, this variable should actually be called
$url_base.  That will be fixed in subsequent releases.

=item *

$url_rel_path: The relative URL path from $url_root.

=item *

$xdo: The Web::XDO object that is handling the entire process.

=item *

caller=>$page

If a page is being included in another page then the included page needs to
know its "caller" page.  That information is set with the caller option. So,
for example, the L<E<lt>includedE<gt>|/Web::XDO::Token::Tag::Include> tag
creates the included page object with a call like this:

 $included = $xdo->page_class->new($url_base, $atts->{'src'}, $xdo, 'caller'=>$caller);

If a caller is sent then that object is stored in the included page in the
$page->{'caller'} property.

=back

=cut

sub new {
	my ($class, $url_root, $url_rel_path, $xdo, %opts) = @_;
	my ($tokens, $token_idx, $page);
	
	# TESTING
	# println $class, '->new()'; ##i
	
	# create page object
	$page = $class->SUPER::new();
	
	# don't recognize cdata tags
	$page->xml_mode(1);
	
	# must either designate a caller or explicitly set as top page
	if (my $caller = $opts{'caller'}) {
		if (UNIVERSAL::isa($caller, 'Web::XDO::Page')) {
			$page->{'caller'} = $caller;
		}
		else {
			croak q|caller is not a page object|;
		}
	}
	else {
		$page->{'props'} = {};
	}
	
	# hold on to xdo object
	$page->{'xdo'} = $xdo;
	
	# build path to file
	$page->set_paths($url_root, $url_rel_path) or return 0;
	
	# initialize token array
	$tokens = $page->{'tokens'} = [];
	
	# parse
	$page->parse_file("$page->{'local_path'}");
	
	# initialize $token_idx to 0
	$token_idx = 0;
	
	# set page properties
	# NOTE: This rather odd construction for iterating through the tokens is
	# based on the fact that set_page_prop tokens are removed from the token
	# array, and they might remove other tokens after them.  Therefore the
	# length of the array can change during the loop.
	while ($token_idx < @$tokens) {
		my $token = $tokens->[$token_idx];
		
		if (UNIVERSAL::isa($token, 'Web::XDO::Token::Tag')) {
			if (UNIVERSAL::can($token, 'set_page_prop')) {
				$token->set_page_prop($page, $token_idx);
			}
		}
		
		# increment to next token
		$token_idx++;
	}
	
	# return
	return $page;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# top
#

=head3 $page->top()

This method returns the top page in the hierarchy of included pages. If a
Web::XDO::Page object is created with the 'caller' option (which means the
caller page is stored in $page->{'caller'}), then the page's caller's
top() method is called and returned.  The top() method is called recursively
up the hierarchy until the top page (which has no caller) is reached. The top
page returns itself and that result is returned back down the hierarchy to page
that initiated the routine.

=cut

sub top {
	my ($page) = @_;
	
	# if there is a caller, return that page's top()
	if ($page->{'caller'})
		{ return $page->{'caller'}->top }
	
	# else this page is the top
	return $page;
}
#
# top
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# top_props
#

=head3 $page->top_props()

Returns the top page's {'props'} hash. Only the top page should have a
{'props'} hash and only properties in that hash should be set.

=cut

sub top_props {
	my ($page) = @_;
	return $page->top->{'props'};
}
#
# top_props
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# set_paths
#

=head3 $page->set_paths($url_root, $url_rel_path)

This internal method sets the page's url_path property to an absolute path.
The absolute path is calculated using the $url_root and $url_rel_path
params. The final result is put into the $page-E<gt>{'url_path'}.

I<Note:> I put a lot of effort into addressing attempts to read files outside
the document root.  A particular concern is for someone to send a request
directly to xdo.pl with something like this:

 xdo.pl?p=../../../../../etc/passwd

If set_paths() doesn't properly filter the request then such a request could
return unauthorized files.

=cut

sub set_paths {
	my ($page, $url_root, $url_rel_path) = @_;
	my ($doc_root_rx);
	
	# TESTING
	# println ref($page), '->set_paths'; ##i
	
	# build url path
	# stringify URI object
	$page->{'url_path'} = URI->new_abs($url_rel_path, $url_root);
	
	# return false if we don't get a URI object
	if (! ref($page->{'url_path'}))
		{ return 0 }
	
	# stringify URI object
	$page->{'url_path'} .= '';
	
	# if the path contains .. then it's an invalid path, return 0
	# KLUDGE: This check is basically an attempt to filter out the
	# bad instead of filtering in the good.
	if ($page->{'url_path'} =~ m|\.\.|s)
		{ return 0 }
	
	# build file path
	$page->{'local_path'} = $page->{'xdo'}->{'document_root'} . $page->{'url_path'};
	
	# if path doesn't exist, return 404
	if (! -r $page->{'local_path'})
		{ return 0 }
	
	# return success
	return 1;
}
#
# set_paths
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# output
#

=head3 $page->output()

output() outputs the page.

=cut

sub output {
	my ($page) = @_;
	my ($xdo, $nested, $local_path, $tokens, $token_idx);
	$token_idx = 0;
	
	# TESTING
	# println $page->{'url_path'}, '->output'; ##i
	
	# convenience objects
	$xdo = $page->{'xdo'};
	$nested = $xdo->{'nested'};
	$local_path = $page->{'local_path'};
	$tokens = $page->{'tokens'};
	
	# check if this page has already been output
	if ($nested->{$local_path}) {
		return 0;
	}
	
	# note as output
	$nested->{$local_path} = 1;
	
	# loop through tokens
	while ($token_idx <= $#$tokens) {
		my $token = $tokens->[$token_idx];
		
		# if object, call output method
		# else just print
		if (ref $token) {
			$token->output($page, $token_idx);
		}
		else {
			print $token;
		}
		
		# increment
		$token_idx++;
	}
	
	# note not longer output
	delete $nested->{$local_path};
}
#
# output
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# start
#

=head3 $page->start()

Web::XDO::Page superclasses
L<HTML::Parser|http://search.cpan.org/dist/HTML-Parser/Parser.pm>.
start() handles HTML::Parser's event when a start tag is parsed.

start() creates a new tag object using the class returned by
L<$xdo-E<gt>tag_class()|/$xdo-E<gt>tag_class()>.

=cut

sub start {
	my ($page, $tag_name, $atts, $att_order, $raw) = @_;
	my ($self_ender, $def, $token, $xdo);
	$xdo = $page->{'xdo'};
	
	# TESTING
	# println $tag_name, '->start'; ##i
	
	# normalize tag name
	# NOTE: We need to normalize here because the parser is in xml_mode. That
	# mode is on so that content of cdata tags (specificall <title>) are
	# parsed. It has the side-effect that tag names are sent as they appear
	# in the document being parsed.  If anybody knows a more global way to send
	# lowercased tag names I'll be glad to hear about it.  - Miko
	$tag_name = lc($tag_name);
	
	# if the tag has a trailing slash then it's a self-ender
	if ($raw =~ m|/\s*\>$|s)
		{ $self_ender = 1 }
	
	# NOTE: Funky code ahead. The following few lines take into account several
	# different possibilities of how the tag definition might be structured.
	# It might be:
	#    - a hashref with a class name
	#    - a hashref without a class name
	#    - just a class name
	#
	# The following code ensures that the definition is a hashref with a
	# class name.
	
	# get tag definition
	$def = $page->{'xdo'}->{'tags'}->{$tag_name} || $xdo->default_tag_class();
	
	# ensure tag definition is a hashref
	ref($def) or $def = {class=>$def};
	
	# ensure definition has a tag class
	$def->{'class'} ||= $xdo->default_tag_class();
	
	# create token object
	$token = $def->{'class'}->new();
	$token->{'type'} = 'tag';
	$token->{'name'} = $tag_name;
	$token->{'atts'} = $atts;
	$token->{'raw'} = $raw;
	
	# note if self-ender
	if ($self_ender)
		{ $token->{'self_ender'} = 1 }
	
	# hold on to token
	push @{$page->{'tokens'}}, $token;
}
#
# start
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# end
#

=head3 $page->end()

end() handles HTML::Parser's event when an end tag is parsed.
end() creates a new end tag object with the
Web::XDO::Token::EndTag class.

=cut

sub end {
	my ($page, $tag_name, $raw) = @_;
	my ($token);
	
	# normalize tag name
	# NOTE: We need to normalize here because the parser is in xml_mode. That
	# mode is on so that content of cdata tags (specificall <title>) are
	# parsed. It has the side-effect that tag names are sent as they appear
	# in the document being parsed.  If anybody knows a more global way to send
	# lowercased tag names I'll be glad to hear about it.  - Miko
	$tag_name = lc($tag_name);
	
	# create token object
	$token = Web::XDO::Token::EndTag->new();
	$token->{'type'} = 'end_tag';
	$token->{'name'} = $tag_name;
	$token->{'raw'} = $raw;
	
	# hold on to token
	push @{$page->{'tokens'}}, $token;
}
#
# end
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# text
#

=head3 $page->text()

text() handles HTML::Parser's event when an end tag is parsed.
text() creates a new text object with the
Web::XDO::Token::Text class.

=cut

sub text {
	my ($page, $raw) = @_;
	my ($token);
	
	# create text object
	$token = Web::XDO::Token::Text->new();
	$token->{'type'} = 'text';
	$token->{'raw'} = $raw;
	
	# hold on to token
	push @{$page->{'tokens'}}, $token;
}
#
# text
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# is_directory_index
#

=head3 $page->is_directory_index()

is_directory_index() returns true if the XDO page is a
L<directory index|http://httpd.apache.org/docs/2.2/mod/mod_dir.html#directoryindex>
file.  Generally you should
L<configure your server|http://idocs.com/xdo/guides/version-0-10/install/configure-web-server.xdo>
so that the directory index file is named index.xdo.

=cut

sub is_directory_index {
	my ($page) = @_;
	my ($file_name);
	
	# TESTING
	# println '$page->is_directory_index()'; ##i
	
	# get file name
	$file_name = $page->{'url_path'};
	$file_name =~ s|^.*/||s;
	
	# return
	if ($file_name eq $page->{'xdo'}->{'directory_index'})
		{ return 1 }
	else
		{ return 0 }
}
#
# is_directory_index
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# url_path_sans_directory_index
#

=head3 $page->url_path_sans_directory_index()

This method returns the $page->{'url_path'} property with the name of the
directory index file removed.  If the page is not a directory index file then
the path isn't changed.  So, for example, this url_path

 /mysite/index.xdo

would be return as /mysite/, whereas this url_path

 /mysite/resume.xdo

would be returned as /mysite/resume.xdo.

=cut

sub url_path_sans_directory_index {
	my ($page) = @_;
	
	# if this page is a directory page, return url_path without file name
	if ($page->is_directory_index) {
		my $url_path = $page->{'url_path'};
		$url_path =~ s|[^/]+$||s;
		return $url_path;
	}
	
	# else just return url_path
	else {
		return $page->{'url_path'};
	}
}
#
# url_path_sans_directory_index
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# title
#

=head3 $page->title()

This method returns the title of the page as set with the
L<E<lt>propertyE<gt>|/Web::XDO::Token::Tag::Property> tag. The tag should
have the name attribute set to "title", like this:

 <property name="title" value="My Home Page">

If the path option is sent, and if a property of path-title is set, then
path-title will be returned.  The path-title is used with the
L<E<lt>pathE<gt>|/Web::XDO::Token::Tag::Path> tag. So, for example, suppose
you want the title of your home page to be "My Home Page" when the page itself
is displayed, but just "Home" for a link to it in the path, then you would set
the E<lt>propertyE<gt> tags like this:

 <property name="title" value="My Home Page">
 <property name="path-title" value="Home">

title() would be called like this:

 $page->title(path=>1)

=cut

sub title {
	my ($page, %opts) = @_;
	my ($props, $title);
	$props = $page->top_props;
	
	# if path title is requested and set
	if ($opts{'path'} && defined($title = $props->{'path-title'})) {
		return $title;
	}
	
	# if title property is set, send that
	elsif (defined($title = $props->{'title'}))
		{ return $title }
	
	# else send url path
	else {
		return $page->{'url_path'};
	}
}
#
# title
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# parent
#

=head3 $page->parent()

parent() returns the page's parent page.  Be careful to avoid confusing the
terms "caller" and "parent".  "caller" is the page that is embedding the
page represented by this object.  "parent" is the page that is one step up in
the web site hierarchy.  The parent page is always going to be either a
directory index file or (for the home page) nothing.

=cut

sub parent {
	my ($page) = @_;
	my ($xdo, $parent, $url_path, $page_class);
	$xdo = $page->{'xdo'};
	
	# TESTING
	# println '$page->parent()'; ##i
	
	# get parent page url path
	$url_path = $page->{'url_path'};
	
	# if this is the top page, and the request was for the directory index,
	# (i.e. the requests ends in a /) then remove the file name (probably
	# index.xdo).
	if ($page->{'top'}) {
		# If a directory index was requested, either there is no parent (because
		# it's the xdo-root) or we should go up one directory.
		if ($ENV{'REQUEST_URI'} =~ m|/$|s) {
			$url_path =~ s|[^/]+$||s;
		}
	}
	
	# else if page is directory index
	elsif ($page->is_directory_index) {
		$url_path =~ s|[^/]+$||;
	}
	
	# if the page is the xdo root, there is no parent
	if ($url_path eq $xdo->{'root'}) {
		return 0.
	}
	
	# if path has trailing / then remove one directory
	# else remove the file name
	unless ($url_path =~ s|[^/]+/$||s) {
		$url_path =~ s|[^/]+$||s;
	}
	
	# parent is always a directory index file
	$url_path .= $xdo->{'directory_index'};
	
	# instantiate top page object
	$page_class = $xdo->page_class();
	$parent = $page_class->new('/', $url_path, $xdo);
	
	# return
	$parent or return 0;
	return $parent;
}
#
# parent
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# path_pages
#

=head3 $page->path_pages()

path_pages() returns an array of the pages in the web site hierarcy leading
down to and including the page represented by this object. In array context
this method returns an array.  In scalar context it returns an array reference.

=cut

sub path_pages {
	my ($page) = @_;
	my (@rv, $current, $sanity);
	
	# I've had problems with an endless loop in this routine, so just to be
	# safe I'm assuming nobody will nest pages more than 100 deep.  Feel free
	# to express disagreement.
	$sanity = 100;
	
	# start with this page
	$current = $page;
	
	# while we get a parent, add it to the return array
	while ($current) {
		unshift @rv, $current;
		$current = $current->parent();
		
		# sanity check
		if ($sanity-- <= 0)
			{ die 'too many iterations' }
	}
	
	# return
	wantarray() and return @rv;
	return \@rv;
}
#
# path_pages
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# link_path
#

=head3 $page->link_path()

This method returns the URL path to link to the page represented by this
object. This method always returns an absolute path.

=cut

sub link_path {
	my ($page) = @_;
	my ($index_rx, $path);
	
	# TESTING
	# println '$page->link_path()'; ##i
	
	# regex for directory index
	$index_rx = $page->{'xdo'}->{'directory_index'};
	$index_rx = quotemeta($index_rx);
	
	# build path, removing directory index file name
	$path = $page->{'url_path'};
	$path =~ s|/$index_rx$|/|s;
	
	# return
	return $path;
}
#
# link_path
#------------------------------------------------------------------------------


#
# Web::XDO::Page
###############################################################################



###############################################################################
# Web::XDO::Token
#
package Web::XDO::Token;
use strict;

# debug tools
# use Debug::ShowStuff ':all';


=head2 Web::XDO::Token

This class represents a generic token in an XDO page.  All token classes
superclass this class.

=cut


#------------------------------------------------------------------------------
# new
#

=head3 $class->new()

Creates a new Web::XDO::Token object and returns it.  Doesn't do anything else.

=cut

sub new {
	my ($class) = @_;
	my $token = bless({}, $class);
	
	# return
	return $token;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# output
#

=head3 $token->output()

Outputs $token->{'raw'} if it is defined. This method is overridden by many
tag classes.

=cut

sub output {
	my ($token) = @_;
	my $raw = $token->{'raw'};
	
	if (defined $raw)
		{ print $raw }
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token
###############################################################################




###############################################################################
# Web::XDO::Token::Tag
#
package Web::XDO::Token::Tag;
use strict;
use base 'Web::XDO::Token';
use String::Util ':all';

# debug tools
# use Debug::ShowStuff ':all';

# tag classes
our (%tag_classes);

=head2 Web::XDO::Token::Tag

This class represents a tag.  This is the default class for tags that XDO
doesn't recognize. This class superclasses
L<Web::XDO::Token|/Web::XDO::Token>.

=cut


#------------------------------------------------------------------------------
# add_class
#

=head3 $tag->add_class()

This method adds a CSS class to the tag's "class" attribute.  If such an
attribute doesn't already exist then it is created.  If the new CSS class
is already in the "class" attribute then no change is made.

After calling add_class() and before outputting the tag you should call
L<$tag-E<gt>rebuild()|/$tag-E<gt>rebuild()> or the output tag will not have the
added class.

=cut

sub add_class {
	my ($tag, $new_class) = @_;
	my ($atts);
	$atts = $tag->{'atts'};
	
	# if class attribute exists, add class
	if (defined $atts->{'class'}) {
		my @classes = split(' ', crunch($atts->{'class'}));
		@classes = grep {$_ eq $new_class} @classes;
		
		unless (@classes)
			{ $atts->{'class'} .= ' ' . $new_class }
	}
	
	# else just add class attribute
	else {
		$atts->{'class'} = $new_class;
	}
}
#
# add_class
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rebuild
#

=head3 $tag->rebuild()

rebuild() rebuilds the $tag->{'raw'} attribute.  'raw' is the string that is
output by L<$token-E<gt>output()|/$token-E<gt>output()>.

=cut

sub rebuild {
	my ($tag) = @_;
	my ($raw, $atts);
	$atts = $tag->{'atts'};
	
	# open tag
	$raw = '<' . $tag->{'name'};
	
	# add attributes
	foreach my $key (keys %$atts) {
		$raw .= ' ' . $key . '="' . htmlesc($atts->{$key}) . '"';
	}
	
	# close tag
	$raw .= '>';
	
	# save raw
	$tag->{'raw'} = $raw;
}
#
# rebuild
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# adjust_atts_for_root
#

=head3 $tag->adjust_atts_for_root()

adjust_atts_for_root() modifies the given tag attributes if they have the
L<E<lt>xdo-rootE<gt>|/Web::XDO::Token::Tag::XdoRoot>
tag.

=cut

sub adjust_atts_for_root {
	my ($tag, $page, @att_names) = @_;
	my ($xdo, $atts);
	$xdo = $page->{'xdo'};
	$atts = $tag->{'atts'};
	
	# TESTING
	# println ref($tag), '->adjust_atts_for_root()';
	
	# loop through attributes adjusting for <xdo-root>
	foreach my $att_name (@att_names) {
		if (defined $atts->{$att_name} ) {
			$atts->{$att_name} = $xdo->adjust_url_for_root($atts->{$att_name});
		}
	}
}
#
# adjust_atts_for_root
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# content
#

=head3 $tag->content()

Returns the elements contained within the tag represented by this object. The
elements are removed from the page's tokens array.  The end tag is removed from
the tokens array but is not returned by this method.

$tag->contents() is an alias for $tag->content().

=cut

sub contents {return shift->content(@_)}

sub content {
	my ($tag, $page, $idx) = @_;
	my ($next_idx, $tokens, @rv, $nested);
	$next_idx = $idx + 1;
	$tokens = $page->{'tokens'};
	$nested = 0;
	
	# TESTING
	# println ref($tag), '->content()'; ##i
	
	# get next tokens until we get to the </wrapper> end tag
	NEXT_LOOP:
	while (my $next = splice(@$tokens, $next_idx, 1)) {
		# if end tag for this element, we're done
		if (UNIVERSAL::isa $next, 'Web::XDO::Token::EndTag') {
			if ($next->{'name'} eq $tag->{'name'}) {
				if ($nested)
					{ $nested-- }
				else
					{ last NEXT_LOOP }
			}
		}
		
		# else if this is another tag with the same name, note as nested
		elsif (UNIVERSAL::isa $next, 'Web::XDO::Token::Tag') {
			if ($next->{'name'} eq $tag->{'name'}) {
				$nested++;
			}
		}
		
		# add token to return array
		push @rv, $next;
	}
	
	# return
	wantarray and return @rv;
	return \@rv;
}
#
# content
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# included_page
#

=head3 $tag->included_page()

This method returns a page object representing the page referenced in a tag.
Most commonly this method is used by
L<E<lt>includedE<gt>|/Web::XDO::Token::Tag::Include>
to retrieve the included page.

=cut

sub included_page {
	my ($tag, $caller) = @_;
	my ($atts, $xdo, $included, $url_base);
	$atts = $tag->{'atts'};
	$xdo = $caller->{'xdo'};
	
	# TESTING
	# println ref($tag), '->included_page()'; ##i
	
	# start with url_path of page
	$url_base = $caller->{'url_path'};
	
	# if page is a plain file, remove file name
	if (-f $caller->{'local_path'})
		{ $url_base =~ s|[^/]*$||s }
	
	# adjust urls for xdo-root
	$tag->adjust_atts_for_root($caller, 'src');
	
	# instantiate page object
	$included = $xdo->page_class->new($url_base, $atts->{'src'}, $xdo, 'caller'=>$caller);
	
	# return
	return $included;
}
#
# included_page
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# output
#

=head3 $tag->output()

Outputs the tag.
L<$tag-E<gt>adjust_atts_for_root()|/$tag-E<gt>adjust_atts_for_root()>
is called before the tag is output.

=cut

sub output {
	my ($tag, $page, $idx) = @_;
	
	# TESTING
	# println $tag->{'name'}, '->output'; ##i
	
	# get definition
	if (my $def = $page->{'xdo'}->{'tags'}->{$tag->{'name'}}) {
		if ($def->{'adjust_for_root'}) {
			$tag->adjust_atts_for_root($page, @{$def->{'adjust_for_root'}});
			$tag->rebuild();
		}
	}
	
	# output raw
	print $tag->{'raw'};
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag
###############################################################################


###############################################################################
# Web::XDO::Token::EndTag
#
package Web::XDO::Token::EndTag;
use strict;
use base 'Web::XDO::Token';

#
# Web::XDO::Token::EndTag
###############################################################################


###############################################################################
# Web::XDO::Token::Text
#
package Web::XDO::Token::Text;
use strict;
use base 'Web::XDO::Token';

#
# Web::XDO::Token::Text
###############################################################################


###############################################################################
# Web::XDO::Token::Tag::Include
#
package Web::XDO::Token::Tag::Include;
use strict;
use base 'Web::XDO::Token::Tag';
use String::Util ':all';
use Carp 'croak';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'include'} = __PACKAGE__;


=head2 Web::XDO::Token::Tag::Include

This class represents an E<lt>includeE<gt> tag. This tag embeds the referenced
page in the current page.

=cut


#------------------------------------------------------------------------------
# output
#
sub output {
	my ($tag, $page, $idx) = @_;
	my ($included);
	
	# TESTING
	# println ref($tag), '->output'; ##i
	
	# get included page
	$included = $tag->included_page($page);
	
	# output included page
	if ($included)
		{ $included->output() }
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::Include
###############################################################################


###############################################################################
# Web::XDO::Token::Tag::Property
#
package Web::XDO::Token::Tag::Property;
use strict;
use Carp 'croak';
use base 'Web::XDO::Token::Tag';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'property'} = __PACKAGE__;

=head2 Web::XDO::Token::Tag::Property

This class represents a E<lt>propertyE<gt> tag.  That tag sets a page property.
It does not output anything.

=cut


#------------------------------------------------------------------------------
# set_page_prop
#

=head3 $property->set_page_prop()

This method sets a property of the L<top page|/$page-E<gt>top()>.

=cut

sub set_page_prop {
	my ($tag, $page, $token_idx) = @_;
	my ($atts, $name, $value, $props, $tokens);
	$atts = $tag->{'atts'};
	$props = $page->top_props();
	$tokens = $page->{'tokens'};
	
	# TESTING
	# println ref($tag), '->set_page_prop'; ##i
	
	# name of property
	unless (defined($name = $atts->{'name'}))
		{ return 0 }
		
	# get value from attribute
	if (exists $atts->{'value'}) {
		$value = $atts->{'value'};
	}
	
	# set property
	$props->{$name} = $value;
}
#
# set_page_prop
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# output
#

=head3 $property->output()

This method sets a property of the L<top page|/$page-E<gt>top()> again. When an
XDO page is loaded the properties of the page are set as the page is parsed.
Because properties can be changed between parsing and output, the
E<lt>propertyE<gt> tag sets properties in both parsing and output.

=cut

sub output {
	my ($tag, $page, $idx) = @_;
	$tag->set_page_prop($page);
}
#
# output
#------------------------------------------------------------------------------



#
# Web::XDO::Token::Tag::Property
###############################################################################



###############################################################################
# Web::XDO::Token::Tag::ShowProperty
#
package Web::XDO::Token::Tag::ShowProperty;
use strict;
use Carp 'croak';
use base 'Web::XDO::Token::Tag';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'show-property'} = __PACKAGE__;


=head2 Web::XDO::Token::Tag::ShowProperty

This class represents a E<lt>show-propertyE<gt> tag. This tag outputs the
property of the L<top page's|/$page-E<gt>top()> that is named in the "name"
attribute. Note that the value of the property is not HTML-escaped.

=cut

#------------------------------------------------------------------------------
# output
#
sub output {
	my ($tag, $page, $idx) = @_;
	my ($atts, $xdo, $props);
	$atts = $tag->{'atts'};
	$props = $page->top_props();
	
	# must have name attribute
	unless (defined $atts->{'name'}) {
		return 0;
	}
	
	# output value if there is one
	if (defined $props->{$atts->{'name'}}) {
		print $props->{$atts->{'name'}}
	}
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::ShowProperty
###############################################################################



###############################################################################
# Web::XDO::Token::Tag::XdoRoot
#
package Web::XDO::Token::Tag::XdoRoot;
use strict;
use base 'Web::XDO::Token::Tag';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'xdo-root'} = __PACKAGE__;


=head2 Web::XDO::Token::Tag::XdoRoot

This class represents an
L<E<lt>xdo-rootE<gt>|http://idocs.com/xdo/guides/version-0-10/tags/xdo-root/>
tag. This tag outputs the L<$xdo object's|/Web::XDO> {'root'} property.

=cut


#------------------------------------------------------------------------------
# output
#
sub output {
	my ($tag, $page, $idx) = @_;
	my ($xdo);
	$xdo = $page->{'xdo'};
	
	# TESTING
	# println ref($tag), '->output()'; ##i
	
	# output xdo root
	print $xdo->{'root'};
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::XdoRoot
###############################################################################



###############################################################################
# Web::XDO::Token::Tag::Wrapper
#
package Web::XDO::Token::Tag::Wrapper;
use strict;
use base 'Web::XDO::Token::Tag';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'wrapper'} = __PACKAGE__;


=head2 Web::XDO::Token::Tag::Wrapper

This class represents a
L<E<lt>wrapperE<gt>|http://idocs.com/xdo/guides/version-0-10/tags/wrapper/>
tag.  The contents of the E<lt>wrapperE<gt> tag are used to replace the
included page's
L<E<lt>wrapper-contentE<gt>|/Web::XDO::Token::Tag::WrapperContent> tag.

=cut

#------------------------------------------------------------------------------
# output
#
sub output {
	my ($tag, $page, $idx) = @_;
	my ($xdo, $atts, @contents, $wrapper, $included, $inc_tokens, $inc_idx);
	$xdo = $page->{'xdo'};
	$atts = $tag->{'atts'};
	$inc_idx = 0;
	
	# TESTING
	# println ref($tag), '->output()'; ##i
	
	# adjust attributes for root
	$tag->adjust_atts_for_root($page, 'src');
	
	# get contents of tag
	@contents = $tag->contents($page, $idx);
	
	# create wrapper page object
	$included = $tag->included_page($page);
	$included or return 0;
	
	# get included page tokens
	$inc_tokens = $included->{'tokens'};
	
	# loop through include's tokens looking for <wrapper-content>
	while ($inc_idx <= $#$inc_tokens) {
		my $token = $inc_tokens->[$inc_idx];
		
		# If token is is <wrapper-content> then splice in the contents
		# of the <wrapper> tag.
		if (UNIVERSAL::isa $token, 'Web::XDO::Token::Tag::WrapperContent') {
			# remove <wrapper-content> tag and add <wrapper> contents
			splice @$inc_tokens, $inc_idx, 1, @contents;
			
			# increase index to after contents tags
			$inc_idx += @contents;
		}
		
		# else increment $inc_idx
		else {
			$inc_idx++;
		}
	}
	
	# output included page
	$included->output();
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::Wrapper
###############################################################################



###############################################################################
# Web::XDO::Token::Tag::WrapperContent
#
package Web::XDO::Token::Tag::WrapperContent;
use strict;
use Carp 'croak';
use base 'Web::XDO::Token::Tag';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'wrapper-content'} = __PACKAGE__;

=head2 Web::XDO::Token::Tag::WrapperContent

This class represents a
L<E<lt>wrapper-contentE<gt>|http://idocs.com/xdo/guides/version-0-10/tags/wrapper/>
tag.

This tag itself does not output anything.  The E<lt>wrapper-contentE<gt> tag is a
placeholder. When a L<E<lt>wrapperE<gt>|/Web::XDO::Token::Tag::Wrapper>
tag is output it removes the <E<lt>wrapper-contentE<gt> tag and substitutes in
its own contents.


=cut


#------------------------------------------------------------------------------
# output
# don't output anything
#
sub output {
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::WrapperContent
###############################################################################



###############################################################################
# Web::XDO::Token::Tag::XdoTest
#
package Web::XDO::Token::Tag::XdoTest;
use strict;
use Carp 'croak';
use base 'Web::XDO::Token::Tag';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'xdo-test'} = __PACKAGE__;

=head2 Web::XDO::Token::Tag::XdoTest

This class represents an
L<E<lt>xdo-testE<gt>|http://idocs.com/xdo/guides/version-0-10/tags/xdo-test/>
tag.

=cut

# output
sub output {
	print qq|<p style="font-size:300%;text-align:center;background-color:yellow;">XDO is installed</p>\n|;
}

#
# Web::XDO::Token::Tag::XdoTest
###############################################################################


###############################################################################
# Web::XDO::Token::Tag::Parent
#
package Web::XDO::Token::Tag::Parent;
use strict;
use Carp 'croak';
use String::Util ':all';
use base 'Web::XDO::Token::Tag';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'parent'} = __PACKAGE__;

=head2 Web::XDO::Token::Tag::Parent

This class represents a
L<E<lt>parentE<gt>|http://idocs.com/xdo/guides/version-0-10/tags/parent/>
tag.

=cut


#------------------------------------------------------------------------------
# output
#
sub output {
	my ($tag, $page, $idx) = @_;
	my ($parent);
	
	# TESTING
	# println '<parent>'; ##i
	
	# get parent, return false of there is none
	$parent = $page->parent();
	$parent or return 0;
	
	# output link to parent
	if ($page->is_directory_index)
		{ print '<a href="../">' }
	else
		{ print '<a href="./">' }
	
	# if self-ender, output title of parent and close tag
	if ($tag->{'self_ender'}) {
		print $parent->title(), '</a>';
	}
	
	# else change trailing </parent> to </a>
	else {
		my ($tokens, $next_idx);
		$tokens = $page->{'tokens'};
		
		# loop through tokens looking for the next </parent> (or whatever the
		# tag name is).
		TOKEN_LOOP:
		for (my $next_idx=$idx+1; $next_idx <= $#$tokens; $next_idx++) {
			my $next = $tokens->[$next_idx];
			
			if (UNIVERSAL::isa $next, 'Web::XDO::Token::EndTag') {
				# Note that we don't assume the tag's name is "parent" because
				# XDO tags can be configured to have names other than the
				# default.
				if ($next->{'name'} eq $tag->{'name'}) {
					$next->{'raw'} = '</a>';
					$next->{'name'} = 'a';
					last TOKEN_LOOP;
				}
			}
		}
	}
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::Parent
###############################################################################


###############################################################################
# Web::XDO::Token::Tag::Path
#
package Web::XDO::Token::Tag::Path;
use strict;
use Carp 'croak';
use String::Util ':all';
use base 'Web::XDO::Token::Tag';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'path'} = __PACKAGE__;


=head2 Web::XDO::Token::Tag::Path

This class represents a
L<E<lt>pathE<gt>|http://idocs.com/xdo/guides/version-0-10/tags/path/>
tag.

=cut


#------------------------------------------------------------------------------
# output
#
sub output {
	my ($tag, $page, $idx) = @_;
	my ($top, $xdo, $atts, @path, $a_class, @tokens, $separator, $first_done);
	$xdo = $page->{'xdo'};
	$atts = $tag->{'atts'};
	
	# TESTING
	# println '<', $tag->{'name'}, '>'; ##i
	
	# get top page
	$top = $page->top;
	$top or return 0;
	
	# get path pages
	@path = $top->path_pages();
	
	# get class for <a> tag
	$a_class = $xdo->tag_class('a');
	
	# determine separator
	if (defined $atts->{'separator'})
		{ $separator = $atts->{'separator'} }
	else
		{ $separator = " &gt;\n" }
	
	# create <a> tag objects
	foreach my $ancestor (@path) {
		my ($a, $text, $end_tag);
		
		# add separator if necessary
		if ($first_done)
			{ push @tokens, $separator }
		else
			{ $first_done = 1 }
		
		# add <a> object to tokens array
		$a = $a_class->new();
		$a->{'type'} = 'tag';
		$a->{'name'} = 'a';
		$a->{'atts'} = {href=>$ancestor->link_path};
		$a->{'raw'} = '<a href="' . htmlesc($ancestor->link_path) . '" class="path-link">';
		push @tokens, $a;
		
		# add text object
		$text = Web::XDO::Token::Text->new();
		$text->{'type'} = 'text';
		$text->{'raw'} = $ancestor->title(path=>1);
		push @tokens, $text;
		
		# add </a> object
		$end_tag = Web::XDO::Token::EndTag->new();
		$end_tag->{'type'} = 'end_tag';
		$end_tag->{'name'} = 'a';
		$end_tag->{'raw'} = '</a>';
		push @tokens, $end_tag;
	}
	
	# add tokens to page tokens
	if (@tokens) {
		# add <span> elements before and after token array
		unshift @tokens, '<span class="path">';
		push @tokens, '</span>';
		
		# add tokens to page's tokens array
		splice @{$page->{'tokens'}}, $idx+1, 0, @tokens;
	}
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::Path
###############################################################################


###############################################################################
# Web::XDO::Token::Tag::A
#
package Web::XDO::Token::Tag::A;
use strict;
use base 'Web::XDO::Token::Tag';
use String::Util ':all';
use Carp 'croak';

# debug tools
# use Debug::ShowStuff ':all';

# note tag class
$Web::XDO::Token::Tag::tag_classes{'a'} = __PACKAGE__;

=head2 Web::XDO::Token::Tag::A

This class represents an
L<E<lt>aE<gt>|http://idocs.com/xdo/guides/version-0-10/tags/a/>
tag.

=cut


#------------------------------------------------------------------------------
# output
#
sub output {
	my ($tag, $page, $idx) = @_;
	my ($top, $atts, $url_path, $abs_href);
	$top = $page->top;
	$atts = $tag->{'atts'};
	
	# TESTING
	# println '<', $tag->{'name'}, '>'; ##i
	
	# adjust href for root
	$tag->adjust_atts_for_root($page, 'href');
	$tag->rebuild();
	
	# get absolute href path
	$abs_href = $atts->{'href'};
	defined($abs_href) or return $tag->SUPER::output($page, $idx);
	$abs_href = URI->new_abs($abs_href, $top->{'url_path'});
	
	# if href contains any backticks, return super method
	if ($abs_href =~ m|\.\.|s)
		{ return $tag->SUPER::output($page, $idx) }
	
	# if absolute href is the same as this page, change from <a> to <span>
	if ($abs_href eq $top->url_path_sans_directory_index()) {
		my ($span_class, $tokens);
		
		# change tag name to span
		$tag->{'name'} = 'span';
		
		# rebless as <span> tag
		bless $tag, $page->{'xdo'}->tag_class('span');
		
		# add current-page class
		$tag->add_class('current-page');
		
		# remove href attribute
		delete $atts->{'href'};
		
		# rebuild tag
		$tag->rebuild();
		
		# output
		print $tag->{'raw'};
		
		# get array of page's tokens
		$tokens = $page->{'tokens'};
		
		# loop for closing tag and change it to </span>
		TOKEN_LOOP:
		for (my $next_idx=$idx+1; $next_idx < @$tokens; $next_idx++) {
			my $next = $tokens->[$next_idx];
			
			# if end tag for this tag, change to </span>
			if (UNIVERSAL::isa $next, 'Web::XDO::Token::EndTag') {
				if ($next->{'name'} eq $tag->{'name'}) {
					$next->{'name'} = 'span';
					$next->{'raw'} = '</span>';
					last TOKEN_LOOP;
				}
			}
		}
	}
	
	# else output tag like normal
	else {
		return $tag->SUPER::output($page, $idx);
	}
}
#
# output
#------------------------------------------------------------------------------


#
# Web::XDO::Token::Tag::A
###############################################################################



# return true
1;

__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2013 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

=over

=item Version 0.10 - December 1, 2013

Initial release

=item Version 0.11 - December 2, 2013

Fixed problem with prerequisites.

=back


=cut
