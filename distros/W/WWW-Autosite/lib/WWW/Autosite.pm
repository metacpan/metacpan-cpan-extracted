package WWW::Autosite;
use strict;
use warnings;
use Carp;
use YAML;
use File::PathInfo;
use HTML::Template;
use Cwd;
require Exporter;
use vars qw(@EXPORT_OK @ISA %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT_OK = qw(
slurp script_dir get_tmpl
feed_ENV feed_META feed_FILE feed_PLUGIN_PATH_NAVIGATION feed_PLUGIN_SITE_MAIN_MENU feed_PLUGIN_FILE_INFO
get_plugin_path_navigation
handler_filename handler_exts handler_tmpl handler_content handler_sgc handler_write_sgc 
request_abs_content request_sgc request_has_handler request_route request_exts 
get_meta set_meta
icon
abs_path_n
);
%EXPORT_TAGS = ( 
	feed => [ qw(	
		feed_ENV feed_META feed_FILE feed_PLUGIN_PATH_NAVIGATION feed_PLUGIN_SITE_MAIN_MENU feed_PLUGIN_FILE_INFO
	)], 
	handler => [qw(
		handler_filename handler_exts handler_tmpl handler_content handler_sgc handler_write_sgc
	)],
	request => [qw(
		request_abs_content request_sgc request_has_handler request_route request_exts
	)],
	meta => [qw(set_meta get_meta)],
	all => \@EXPORT_OK,
);

our $VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)/g;

our $DEBUG = 0;
sub DEBUG : lvalue { $DEBUG }

our $WRITE_SGC = 0;
sub WRITE_SGC : lvalue { $WRITE_SGC }






{ no warnings;
$ENV{AUTOSITE_TMPL} ||= set_AUTOSITE_TMPL();
};

$ENV{DOCUMENT_ROOT} or carp('WWW::Autosite needs ENV DOCUMENT_ROOT to be set') if DEBUG;

sub set_AUTOSITE_TMPL {

	print STDERR  __PACKAGE__." note: ENV AUTOSITE_TMPL is not set\n" if DEBUG;
	
	unless( $ENV{DOCUMENT_ROOT} ){
		print STDERR __PACKAGE__." note: ENV DOCUMENT_ROOT is not set either. giving up.\n" if DEBUG;
		return;
	}	
		#TODO what happens to subs reading ENV AUTOSITE TMPL, tripple check
	
	my $default_path =  "$ENV{DOCUMENT_ROOT}/.tmpl";
	if ( -d $default_path ){
		print STDERR __PACKAGE__." note: setting [$default_path] instead.\n" if DEBUG;
		return $default_path;
	}	
	
	print STDERR __PACKAGE__." note: no directory for templates resolved. will use all default hardcoded templates\n" if DEBUG;
	return;
}





=pod

=head1 NAME

WWW::Autosite - support subroutines for autosite handlers, router, and misc cgi scripts

=head1 SYNOPSIS
	
In /var/www/cgi-bin/wraphtm.cgi:

	#!/usr/bin/perl -w
	use strict;
	use WWW::Autosite ':all';
	
	my $tmpl = handler_tmpl();
	
	feed_META( $tmpl, $ENV{PATH_TRANSLATED}  );
	feed_ENV( $tmpl);
	feed_FILE( $tmpl, $ENV{PATH_TRANSLATED}  );
	feed_PLUGIN_PATH_NAVIGATION($tmpl, $ENV{PATH_TRANSLATED});
		
	$tmpl->param( BODY => slurp($ENV{PATH_TRANSLATED}));
	
	print "Content-Type: text/html\n\n";
	print $tmpl->output;
	exit;

In /var/www/html/barebones.htm:
	
	<h1>Welcome!</h1>
	<p>This is some wonderful html content here.</p>

In /var/www/html/barebones.htm.meta:
	
	---
	title: BareBones file.
	description: This is one lonely file.
	keywords: bare,bare bones,barebone
	author: Myself A I

In /var/www/html/.htaccess:

	Action wraphtm /cgi-bin/wraphtm.cgi
	AddHandler wraphtm .htm


=head1 DESCRIPTION

Support subroutines for building cgi with HTML::Template.

=cut

=head1 Subroutines

No subs are exported by default. None.

=cut


# quick way to allow designer to override a template, if not on disk, use provided
# this sub expects filename (filename) 
sub get_tmpl { # tmpl (d)efault (o)r (o)verride
	my $label = shift; 
	$label or croak('get_tmpl(): no filename provided');
	my $default = shift;
	
	print STDERR "get_tmpl() called for [$label]\ndefault provided:".($default ? 1 :0)."\n" if DEBUG;
	
	my $_tmpl;	


	if ($label=~/^\//){
			$_tmpl = new HTML::Template(  filename => "$label", die_on_bad_params => 0 );
			print STDERR "found abs path tmpl : $label used.\n" if DEBUG;			
			return $_tmpl;
	}

	elsif ($ENV{AUTOSITE_TMPL} and -f "$ENV{AUTOSITE_TMPL}/$label"){
			$_tmpl = new HTML::Template(  filename => "$ENV{AUTOSITE_TMPL}/$label", die_on_bad_params => 0 );
			print STDERR "found ENV AUTOSITE_TMPL tmpl : $ENV{AUTOSITE_TMPL}/$label used.\n" if DEBUG;			
			return $_tmpl;
	} 	

	elsif ($default){  # a default tmpl present
			$_tmpl = new HTML::Template( die_on_bad_params => 0, scalarref => $default );	
			print STDERR "default provided for [$label] used.\n"if DEBUG;
			return $_tmpl;
	}

	croak("get_tmpl(): no template file found and no default provided for [$label]");
	
}

=head2 get_tmpl()

Takes two arguments. Returns HTML::Template object.

First is a path or filename to an HTML::Template file.
If the path to template is not absolute (if it's just a filename, ie:'this.html')
it will seek it inside ENV AUTOSITE_TMPL.

Second argument, optional, is a scalar with default code for the template.
This is what allows a user to override the default look by simply creating a file inside 
the ENV AUTOSITE_TMPL.


Returns HTML::Template object. The HTML::Template object returned will have a die_on_bad_params set to 0.

(If you are creating a handler, you can use get_tmpl() to provide a default template to feed stuff into.
This also allows user to place a template of their own in the AUTOSITE_TMPL directory.)

=head3 Example 1

In the following example, if main.html does not exist in ENV AUTOSITE_TMPL, the '$default' 
code provided is used as the template.

	my $default = "<html>
	<head>
	 <title>Hi.</title>
	</head> 
	<body>
		<TMPL_VAR BODY>		
	</body>	
	</html>";

	my $tmpl = get_tmpl('main.html',$default);

To override that template, one would create the file main.html in ENV AUTOSITE_TMPL. The perl
code need not change. This merely lets you provide a default, optionally.

Again, if main.html is not in AUTOSITE_TMPL, it will use default string provided- 
if no default string provided, and filename is not found, croaks.

=head3 Example 2

In the following example, the template file 'awesome.html' must exist in ENV AUTOSITE_TMPL.
Or the application croaks.

	my $tmpl = get_tmpl('awesome.html');

=cut

# TODO: THIS SHOULD BE IN CGI-PATHREQUEST OR SOMETIHNG
sub _path_to_hash { # prep an abs path as hash suitable for element in a template loop
   my $abs_path = shift; # practically replacing CGI::PathRequest isnt it
   
   my $r = new File::PathInfo;
   $r->set($abs_path) or croak("is $abs_path on disk?");
   #$r->is_in_DOCUMENT_ROOT or return;
      
      my $hash = $r->get_datahash;
	

      $hash->{rel_path}=~s/^/\//;
      $hash->{rel_path}=~s/\/{2,}/\//;
		$hash->{icon} = 'dir' if $r->is_dir;
		$hash->{icon} ||= icon($r->abs_path);
		$hash->{is_image} = $hash->{icon} eq 'image' ? 1 : 0 ;

		
		print STDERR Data::Dumper::Dump($hash) if DEBUG;		
      return $hash;
}

=head2 _path_to_hash()

argument is full file path
returns hash with useful file info, moslty intended to further transform to feed into the template

=cut

sub icon {
	my $abs = shift; $abs or croak('missing abs file arg to icon()'); 

	my $type = undef;
	
	my $ext = {
		image => qr/\.jpe{,1}g$|\.gif$|\.png$|\.bmp$|\.tif{1,2}$/i,		
		video => qr/\.mpe{,1}g$|\.mov$|\.avi$|\.wmv$|\.mp4$/i,
		script => qr/\.h$|\.js$|\.p[lm]$|\.cgi$|\.PL$/,
		html => qr/\.s{,1}htm{,1}$/i,
		audio => qr/\.mp3$|\.wmf$/i,
		text => qr/\.conf$|\.meta$|\.txt$|\.css$/i,
	};	

	for ( keys %$ext ){
		$abs=~$ext->{$_} or next;
		$type = $_ and last;
	}
	
	$type or $type = 'dir' if -d $abs;

	my $pse= pseudomime($abs);
	$type = $pse if exists $ext->{$pse};

	$type ||='default';

	return $type;
}

=head2 icon()

argument is abs path to file, returns icon name for resource.

=cut



sub script_dir {
	my $script_dir = $0; 
	$script_dir=~s/\/[^\/]+$// or $script_dir = './';
#	if ($script_dir _ ){ # i thought $0 would always hold full path to the script being executed./. nope// not on bsd GRRRR!!
#		$script_dir = './';
#	}	
	return $script_dir;
}

=head2 script_dir()

Accepts no arguments.
Returns absolute location of running script.
I said absolute 'location', which is the directory it resides in.

=cut

sub slurp {
   my $abs_path = shift;   
	my $content = do { local( @ARGV, $/ ) = $abs_path; <> } ;
   return $content;
}

=head2 slurp()

argument is abs path to a -t text file
returns content

	my $src - slurp('/path/to/default.css');
	
=cut

sub abs_path_n {
	my $absPath = shift;
	return $absPath if $absPath =~ m{^/$};
   my @elems = split m{/}, $absPath;
   my $ptr = 1;
   while($ptr <= $#elems)
    {
        if($elems[$ptr] eq q{})
        {
            splice @elems, $ptr, 1;
        }
        elsif($elems[$ptr] eq q{.})
        {
            splice @elems, $ptr, 1;
        }
        elsif($elems[$ptr] eq q{..})
        {
            if($ptr < 2)
            {
                splice @elems, $ptr, 1;
            }
            else
            {
                $ptr--;
                splice @elems, $ptr, 2;
            }
        }
        else
        {
            $ptr++;
        }
    }
    return $#elems ? join q{/}, @elems : q{/};

	# by JohnGG 
	# http://perlmonks.org/?node_id=603442	
}

=head2 abs_path_n()

just like Cwd::abs_path() but, does not resolve symlinks. Just cleans up the path.
argument is an abs path.

=cut


sub get_meta {
	my $abs_path = shift; $abs_path or croak('get_meta() needs abs path as argument');

	if( -f $abs_path.'.meta'){
			my $meta = YAML::LoadFile( $abs_path.'.meta' );   
			return $meta;
	}
	# try hidden
	my $abs_meta = $abs_path;
	$abs_meta=~s/\/([^\/]+)$/.$1.meta/;
	if (-f $abs_meta) {
			my $meta = YAML::LoadFile( $abs_meta );
			return $meta;
	}
	return;
}

=head2 get_meta()

argument is absolute path to a file on disk
returns metadata hash if found.

=cut

sub set_meta {
	my $abs_path = shift; 
	my $meta = shift; ref $meta eq 'HASH' or croak('second argument to set_meta() must be a hash ref');	
	YAML::DumpFile("$abs_path.meta",$meta);	
	return 1;
}

=head2 set_meta()

argument is absolute path and hash ref with metadata
does NOT check to see if the file exists.

	set_meta('/home/file',{ name => 'hi', age => 4 });
	
Above example creates meta file '/home/file.meta' :

	---
	name: hi
	age: 4

See also: L<YAML>

=cut

=head1 Html Block Subroutines 

These functions should be useful for general purpose.
They all look for a template that overrides the look and feel provided by default.
That is, you can use all these as is to insert a 'navigation path' for the top of the page,
these all return html blocks.
To change the look, you must create the matching HTML::Template file.

=cut

sub get_plugin_file_info {
	my $abs_path = shift; $abs_path or croak('missing abs path argument to get_plugin_file_info()');

	my $default = <<__DEFAULT__;
<style>
._info {}
</style>

<div class="_info">
<ul>
<li><TMPL_VAR FILE_FILENAME></li>
<li><TMPL_VAR FILE_MTIME_PRETTY></li>
<li><TMPL_VAR FILE_FILESIZE_PRETTY></li>
</ul>
</div>

__DEFAULT__

	my $tmpl= get_tmpl('plugin_file_info.html',\$default);
		
	my $hash = _path_to_hash($abs_path);	
	for (keys %$hash){
		$tmpl->param( "FILE_$_" => $hash->{$_});
	}	
	return $tmpl->output;
}

=head2 get_plugin_file_info()

Required argument is abs path. 
Feeds some data on file. Looks for template 'plugin_file_info.html' in ENV AUTOSITE_TMPL
If not found, uses default template.

		get_plugin_file_info('/path/to/file');

Default template is:

	<style>
	._info {}
	</style>
	
	<div class="_info">
	<ul>
	<li><TMPL_VAR FILE_FILENAME></li>
	<li><TMPL_VAR FILE_MTIME_PRETTY></li>
	<li><TMPL_VAR FILE_FILESIZE_PRETTY></li>
	</ul>
	</div>

=cut

sub get_plugin_path_navigation {
	my $abs_path = shift; $abs_path or croak('get_plugin_path_navigation() missing abs path argument');
	$abs_path = abs_path_n($abs_path);
	
	$ENV{DOCUMENT_ROOT} or carp("ENV DOCUMENT_ROOT is not set, get_plugin_path_navigation() cannot build html for [$abs_path]")
		and return; 
	
	print STDERR "get_path_navigation() given [$abs_path] argument," if DEBUG;
	
	my $rel = $abs_path; $rel=~s/^$ENV{DOCUMENT_ROOT}\///
		or croak("get_plugin_path_navigation(): argument '$abs_path' is not inside document root '$ENV{DOCUMENT_ROOT}");

	print STDERR "rel is [$rel], " if DEBUG;

	if (Cwd::abs_path($ENV{DOCUMENT_ROOT}) eq Cwd::abs_path($abs_path)){
		print STDERR "get_plugin_path_navigation(), argument is document_root, returning undef." if DEBUG;
		return;
	}
	
   my @loop;
   while ( $rel=~s/\/*([^\/]+)$// ){
      my $rpath = "/$rel/$1"; my $filename = $1;
		print STDERR " filename: $filename\n" if DEBUG;
      $rpath =~ s/\/{2,}/\//g;
      
      push @loop, { rel_path => $rpath, filename=> $filename };
   }  
   push @loop, { rel_path => '/', filename => 'home' };   
   shift @loop; # take out first   

	my $default = <<__HEREDOC__;
<style> #path_navigation {} </style>
<div id="path_navigation">
<TMPL_LOOP NAVIGATION><span>&raquo; <a href="<TMPL_VAR REL_PATH>"><TMPL_VAR FILENAME></a></span>
</TMPL_LOOP>
<span>&raquo; <TMPL_VAR FILE_FILENAME></span>
</div>
__HEREDOC__

	my $tmpl = get_tmpl('plugin_path_navigation.html',\$default);
	print STDERR "done.\n" if DEBUG;
   $tmpl->param( NAVIGATION => [ reverse @loop ] );
	my $filename = $abs_path; $filename=~s/^.+\/+//;
	$tmpl->param(FILE_FILENAME => $filename);
	
	
	print STDERR "get_plugin_path_navigation() done.\n" if DEBUG;	
	return $tmpl->output;
}

=head2 get_plugin_path_navigation()

Required argument is absolute path to file.

Builds a step through of the hierarchy navigation for the path. for example if your
content is http://domain/files/document.pdf
The default output is something like

	home >> files >> document.pdf

With links. Self explanatory.
Returns html block.

The default template (if 'plugin_path_navigation.html' is not in your templates dir) is:


	<div id="path_navigation">
	
	<TMPL_LOOP NAVIGATION>
	<span>&raquo;
	 <a href="<TMPL_VAR REL_PATH>"><TMPL_VAR FILENAME></a>
	</span>
	</TMPL_LOOP>

	<span>&raquo;
	 <TMPL_VAR FILE_FILENAME>
	</span>
	
	</div>

If DOCUMENT_ROOT is not set, warns with carp and returns undef.
If the argument *is* document root, returns undef.


=cut



# concepts # {{{

=head1 CONCEPTS

Autosite is meant to create content on the fly. It may be triggered by a 404 not found error,
in which case, ideally, autosite generates the content and saves to disk, so subsequest requests do not
trigger a 404 error- and also, do not use valuable cpu time by calling a script.

Maybe Joe wants to have a website for his 'pigeon salon beauty' business. So he sends you pictures of
his pigeons, and some text blurb about his business, maybe some info about his address and hours of operation.
You piece all this together in to html and create a site.
You are the L<designer>. 
The picture and text Joe gave you is the L<content>. 
The html you pieced together was an ungodly act of horror- And instead should be server generated content, or L<sgc>
for short. Which is what autosite is all about.

The main concepts of this system are:

L<Concept 1: The Content>
L<Concept 2: The Router>
L<Concept 3: The Handler>
L<Concept 4: The SGC>

=head2 What does this do?

Joe's about us blurb is placed inside about_us.txt. This is not a formatted text file, this is text exactly as would
be sent by Joe himself to you over email. It is uploaded to http://joesbirds.com/about_us.txt.
Joe goes online, and punches in http://joesbirds.com/about_us.txt, all he sees is a text file. What you would
expect. But then Joe enters this url in the address bar: http://joesbirds.com/about_us.txt.html
Now, his 'about us' information is presented beautifully embedded into a webpage. Full formatting is present.
It's a professional webpage.

The same can be done with image files, audio files, etc. The L<designer> just tweaks the look and feel in the 
template system. As desired. And has no worry or concern at all whatsoever about the content of the website. 
Because now, anybody that knows how to use email, can use fpt or some other method to upload text files, images,
whatever junk they would normally give the L<designer>.

=head2 How it does it do it?

1) 'about_us.txt' is the L<content> file.

2) 'about_us.txt.html' is the request for a server generated content file L<sgc> which does not exist, and thus
triggers a 404 error. 

3) The L<.htaccess> file says 404 errors are handled by the L<router> script.

4) The router script tries to match up the L<sgc> request with a L<content> file on disk. In this case,
it checks that about_us.txt really is on disk. Then the router tries some heuristic and then mime
checking methods to see if you have a L<handler> script present for creating a 'about_us.txt.html' 
L<sgc> file from the 'about_us.txt' L<content> file.

5) If found, the L<handler> script is asked to create the L<sgc> data.

6) if we are configured to write server generated content (L<sgc>), we write to disk and redirect,
otherwise we send to browser.

=head3 Flowchart

404 error
	\
	 `-> router script -> (does not match sgc request) -> 404 error page
				\
				 `-> (matches sgc request) ->  (no handler found) -> 404 error page
								\
								 `->  handler script -> (WRITE_SGC is on) -> save sgc file, redirect 
													 \
													  `->	(WRITE_SGC is off) -> print output to browser
										


=head2 Concept 1: The Content

=head2 Concept 2: The Router

The purpose of the router is to coordinate what the client browser asked for with what the server is configured to offer.
The client browser may ask for sgc, the router will determine if a handler is present and act accordingly.

Imagine you upload filex.pdf to:

	http://domain.com/filex.pdf

And a client browser requests url:

	http://domain.com/filex.pdf.html

This file does not exist. Apache will trigger a 404 error.
In our .htaccess file we want a directive that says all 404 errors
will be handled by our router:

	ErrorDocument 404 /cgi-bin/autosite/router.cgi

The ENV REQUEST_URI (in this case: '/filex.pdf.html')
Is analized, and in this case a handler called pdf.html.pl would be searched for.
Second, a binary.html.pl handler would be searched for.

This makes it so if you want to add a handler, you just drop it alongside router.cgi.

The subroutines in this section are primarily meant to be used with the router script.
Being functional oriented, they can be used elsewhere.

=head3 The Router Steps

How does the router work?
The router will:

=over 4

=item 1) use heuristics to see if the request looks like it might have a handler

filex.pdf.html would be judged to possibly have a handler. two extensions suggests a handler

=item 2) determine if the content file exists

In this example, we could see if the file filex.pdf exists on the server.

=item 3) find a handler

Now for finding the handler. First we would look for 

	pdf.html.pl 
	
Then

	pdf.html.cgi

Then before we give up, we would analize the content file- and look for a 'text' or 'binary' handler for 
this type.

	binary.html.pl

This way, if you wanted to have a 'catchall' for zipping up binary files, you would have a handler named

	binary.zip.pl

This would allow any xxx.avi.zip, xxx.mp3.zip ,etc (binary content files) to be turned into zip files to be
send to the browser.

You could have had a avi.zip.pl and mp3.zip.pl individual handlers, this is just a shortcut.

=item 4) ask the handler to make the sgc

=item 5) send sgc to the browser

If WWW::Autosite::WRITE_SGC is set to 1, attempts to write to sgc location. otherwise, prints to browser.

=back

=head3 More about sgc requests to the router

these are example sgc requests:

	/demo/doc1.pod.html
	/demo/picture.jpg.html
	/great/video.avi.zip
	/dira/song1.mp3.html
	/demo/doc1.pod.hi # syntax highlighting


the ENV PATH TRANSLATED would hold these urls, which would have triggered a 404 error
inside the .htaccess file is an entry that reads

	ErrorDocument 404 /cgi-bin/autosite/router.cgi 

which is this script.
in the above examples, this script would look for

first, second:

	pod.html.pl		text.html.pl 
	jpg.html.pl 	binary.html.pl
	avi.zip.pl		binary.zip.pl
	mp3.html.pl 	binary.html.pl
	pod.hi.pl		text.hi.pl

In the same directory as this script.	
It would do a system call to one of these scripts and the client would be redirected
to the now existand server generated content (sgc).

To handle other types of conversions, the appropriate script would have to be present
in cgi-bin/autosite
The argument sent to the script is the abs path to the content file 

=head2 Concept 3: The Handler

A handler is a script that takes as argument an absolute file path.
The handler by default does one thing with one type of file.
It may convert simple text to html. It may generate a zip file for the argument.

=head2 Concept 4: The SGC

L<sgc> is short for server generated content. 

=cut 

#}}}

# Router Subs #{{{

=head1 Router Subroutines

=cut

sub request_sgc {
	request_exts() or return;	
	return "$ENV{DOCUMENT_ROOT}/$ENV{REQUEST_URI}";	
}

=head2 request_sgc()

takes no argument.
returns absolute path to request, which will be a L<sgc> file.
if this does not make sense as an sgc file, returns undef.

For example, if you request 'http://domain.com/file1.jpg.html'
Then this returns '/home/xxx/public_html/file1.jpg.html'

If the request was 'http://domain.com/file1.jghtml'
This returns nothing.

request_sgc() does not test for existance of a handler, it just uses heuristics to 
see if the request could have a handler.

=cut

sub request_exts { # request could have handler
	my $request = shift;
	$request ||= $ENV{REQUEST_URI};
	if ($request=~/[^\/]+\.(\w{2,})\.(\w{2,})$/){
		my ($tuplefrom ,$tupleto)= ($1,$2);	
	#	print STDERR  "request_exts(): tuplefrom, tupleto: $tuplefrom, $tupleto\n" if DEBUG;	
		return ($tuplefrom ,$tupleto);		
	}
	 #print STDERR "request_exts(): no tuple match [$request]\n" if DEBUG;
	 return;
}

=head2 request_exts()

Optional argument is request abs path or filename. Otherwise uses ENV REQUEST_URI.
tests ENV REQUEST_URI to see if we have 'from' and 'to' extensions.
returns fromext and toext.
returns undef if no ext tuple is matched.
	
	my ($tuplefrom, $tupleto) = request_exts();
	
	my ($tuplefrom, $tupleto) = request_exts('filename.html.hi');	
	
	request_exts() or die('useless request');

=cut

sub request_has_handler {
	my $request = shift;
	$request ||= request_sgc();
	my $script_dir = shift;
	$script_dir ||= script_dir();
	
	print STDERR "\n=FIND HANDLER for [$request] script_dir $script_dir\n" if DEBUG;
	my $abs_content = request_abs_content($request);
	#print STDERR "abs content: [$abs_content]. " if DEBUG;
	my($content_ext,$sgc_ext) = request_exts($request);
#	print STDERR "\n=request exts: ($content_ext) ($sgc_ext).\n" if DEBUG;
	


	my $handler;
	# 1) first try easy ones, matching the content ext and sgc ext to a handler
	$handler = _try("$content_ext.$sgc_ext",$script_dir);
	if ($handler){ print STDERR "=HANDLER FOUND\n" if DEBUG; return $handler; }	



	# 1.5) heuristic matches
	# FROM EXT:
	# try some basic (fromext) catchalls based on ext
	# image: jpg jpeg gif png					# image.html image.thumb
	# pod: pm pl pod cgi							# pod.html	
	# text: txt										# text.html text.hi
	# code: h cgi pl py pm js css pod		# code.hi
	# audio: mp3 wav
	# video: mpg avi
	# archive: zip tar 
	
	# has to be in order, the vaguest have to be last
	my $ext = [
	 # catchall  # exts	
	 [ 'image' , [qw(jpg jpeg gif png)] ], # .jpg.whatever would seek image.whatever.pl as a possible handler
	 [ 'pod'   , [qw(pm pl cgi pod PL)] ],
	 [ 'audio' , [qw(mp3)] ],
	 [ 'video' , [qw(mov mpg avi)] ],
	 [ 'code'  , [qw(h cgi pl py pm js css html htm shtml html)] ],	
	 [ 'text'  , [qw(h cgi pl py pm js css html htm shtml html txt)] ],		 
	];	

	for ( @$ext ){
		my ($catchall,$exts )= @$_;
		for(@$exts){
			if ($_ eq $content_ext){
						$handler = _try("$catchall.$sgc_ext",$script_dir);	
						if ($handler){ print STDERR "=HANDLER FOUND\n" if DEBUG; return $handler; }	
			}
		}
	
	}


	# 2) try mime ...	

	stat($abs_content);

	# dont handle anything -f and executable?
	# return 0 if -f _ and -x _;

	
	
	if ( -T _ ){  # text (heuristic guess by perl)
		$handler = _try("text.$sgc_ext",$script_dir);	
		if ($handler){ print STDERR "=HANDLER FOUND\n" if DEBUG; return $handler; }	
	}

	else {

		my $pseudomime = pseudomime($abs_content);
		$handler = _try("$pseudomime.$sgc_ext",$script_dir);		
		if ($handler){ print STDERR "=HANDLER FOUND\n" if DEBUG; return $handler; }	

		#else { # binary
		$handler = _try("binary.$sgc_ext",$script_dir);
		return $handler if $handler;
		if ($handler){ print STDERR "=HANDLER FOUND\n" if DEBUG; return $handler; }	
		
	}	
	print STDERR  "=NO HANDLER FOUND\n" if DEBUG;	
	return 0;	
}

sub _try {
	my $filename = shift; $filename or croak('missing filename arg');
	my $script_dir = shift;
	$script_dir ||= script_dir();
	print STDERR " (t scriptdir: $script_dir)\n"if DEBUG;
	
	for (qw(pl cgi)){	
		print STDERR " (t filename:$filename.$_:" if DEBUG;
		if (-f "$script_dir/$filename.$_"){ 
			print STDERR "1)\n" if DEBUG;
			return "$script_dir/$filename.$_";
		}
		print STDERR "0)\n" if DEBUG;		
	}	


	if ($filename=~s/\d+$/_/){
		# this.jpg.im5  -> this.jpg.im_
		for (qw(pl cgi)){	
			print STDERR " (t filename:$filename.$_:" if DEBUG;
			if (-f "$script_dir/$filename.$_"){ 
				print STDERR "1)\n" if DEBUG;
				return "$script_dir/$filename.$_";
			}
			print STDERR "0)\n" if DEBUG;		
		}	
	
	}	
	return;
}

=head2 request_has_handler()

Optional argument is abs path of the requested sgc, and optional scripts directory

uses heuristics and file tests to see if the requested sgc has a handler.
returns abs path to handler script.

	request_has_handler('/var/www/html/wonderful.pod.html','/var/www/cgi-gin/autosite');

returns false if no handler found

=cut

sub pseudomime {
	my $abs_path = shift; $abs_path or croak('no path arg');

	#other media types...
	#my @args = ('file','-ib',$abs_path);
	my $type = `file -ib "$abs_path"`;
	chomp $type; 
#	my $type = 'awkgjakgajjkhwejglweg';
	$type=~s/\/.+$//s;
	#print STDERR "(pseudomime [$abs_path]returns [$type])\n" if DEBUG;
	
	return $type;
}

=head2 pseudomime()

argument is abs path to a file
returns first chunk of mime type, so for a jpg file returns 'image'

=cut

sub request_abs_content {

	my $request = shift;
	$request ||= request_sgc();
	if ( $request=~/(.+\.\w{2,})\.\w{2,}$/ ) {
		my $abs_content = $1;
		#print STDERR " + request_abs_content() matching is $abs_content\n" if DEBUG;
		unless(-e $abs_content){
		#	print STDERR " but it does not exist on disk\n" if DEBUG;
			return;
		}
		#print STDERR " + request_abs_content() returning [$abs_content] \n" if DEBUG;
		return "$abs_content";
	}

#	print STDERR " + request [$request] did not match to resolve to a content file\n" if DEBUG;
	return;
}

=head2 request_abs_content()

optional argument is abs path to sgc. if argument is missing, builds path from ENV REQUEST_URI
eturns absolute path to content.
returns undef if sgc file requested does not have an equivalent content file on disk

That is, if you request http://domain.com/file1.jpg.zip, it returns http://domain.com/file1.jpg if it 
exists.

=cut

sub request_route {
	## route called

	my $handler_script = request_has_handler();
	my $abs_content = request_abs_content();
	my $abs_sgc = request_sgc();

	if (WRITE_SGC){
		no warnings;
		my @args = ($handler_script, $abs_content, '>', $abs_sgc);
		print STDERR  "write route args: @args" if DEBUG;			
		
		exec(@args); 			
		print "Location: $ENV{REQUEST_URI}\n\n";
		exit;		
	}

	# dont write sgcs to server (maybe for testing)
	my @args = ($handler_script, $abs_content); 
	print STDERR  "nowrite route args: @args" if DEBUG;
	my $sgc = `@args`; # test args?

	print STDERR "router about to output to browser ... \n" if DEBUG;
	print "Content-Type: text/html\n\n"; # you sure?? # TODO later these are redirects? what if we are creating binary?
	print $sgc;			
	exit;
}

=head2 request_route()

takes no argument
routes.

if WWW::Autosite::WRITE_SGC is 1, then it attempts to write the sgc file, so subsequent requests do not issue
a 404 error.

otherwise, sends sgc to browser as stream. not very cpu friendly, but.. good for development and testing.

=cut


#}}}

# Handler subs #{{{

=head1 Handler Subroutines 1

They inject stuff into your HTML::Template, provided your template is set up to show it. 
All these subs take your tmpl object as argument.

=cut

sub feed_ENV {
	my $tmpl = shift;
	
   for (keys %ENV){ 
     $tmpl->param( "ENV_$_" => $ENV{$_}); 
   }
	print STDERR "feed_ENV() called, done.\n" if DEBUG;	
	return $tmpl;	
}

=head2 feed_ENV()

argument is a tmpl object ref
returns tmpl object
	
	feed_ENV($tmpl)

feeds all ENV variables to template as

	<TMPL_VAR ENV_DOCUMENT_ROOT>
	<TMPL_VAR ENV_REQUEST_URI>
	<TMPL_VAR ...

=cut

sub feed_PLUGIN_PATH_NAVIGATION {
	my $tmpl = shift;	
   my $abs_content = shift;
	print STDERR "fpn: given [$abs_content] argument," if $abs_content and DEBUG;	
	$abs_content or $abs_content = handler_content();	
	my $html = get_plugin_path_navigation($abs_content) or return $tmpl;
	$tmpl->param( PLUGIN_PATH_NAVIGATION => $html );		
   return $tmpl;
}

=head2 feed_PLUGIN_PATH_NAVIGATION()

Required argument is tmpl object. Optional argument is abs path. If no path argument
is provided, uses the content file.

Provided your template has <TMPL_VAR PLUGIN_PATH_NAVIGATION>, it is fed with 
the output of get_plugin_path_navigation()

=cut

sub feed_PLUGIN_FILE_INFO {
	print STDERR "feed_PLUGIN_FILE_INFO(), "if DEBUG > 1;
	my $tmpl = shift;
	my $abs_path = shift;
	$abs_path ||= handler_content();
	if (my $html = get_plugin_file_info($abs_path)){
		$tmpl->param( PLUGIN_FILE_INFO => $html);
	}	
	return $tmpl;
}

=head2 feed_PLUGIN_FILE_INFO()

Required argument is tmpl object. 
Optional argument is abs path. If no path argument is provided, uses the content file.
Feeds output of get_plugin_file_info() to template.

Your template object should have the variable <TMPL_VAR PLUGIN_FILE_INFO>

	feed_PLUGIN_FILE_INFO($tmpl);
	feed_PLUGIN_FILE_INFO($tmpl,'/home/my/files/thisone');

returns template object.

=cut

sub feed_META {
	my $tmpl = shift; $tmpl or croak('feed_META(): missing tmpl arg');
	my $abs_content = shift; $abs_content ||= handler_content();

	if (my $meta = get_meta($abs_content)){ 
			for (keys %$meta){ 
				$tmpl->param( "META_$_" => $meta->{$_}); 
			}
   }	
	return $tmpl;	
}

=head2 feed_META()

arguments are tmpl object and abs path 
If path argument is missing, uses content file.
This is also for use by a handler.
returns tmpl object

It seeks a matching YAML text file to treat as metadata to feed to your template.


	feed_META($tmpl,'/abs/path/to/what.jpg');

feeds any META variables as 

	<TMPL_VAR META_TITLE>
	<TMPL_VAR META_DESCRIPTION>
	<TMPL_VAR ...

implies that if your file is 

	file.jpg 

and you have a 

	file.jpg.meta 
	
in that same dir, the template will be fed with any meta in that file 
the file must be L<YAML> format.

Imagine you want your 'picture44.jpg' file to have an author and description caption.
The your template would say somewhere:

	<p><img src="/<TMPL_VAR FILE_REL_PATH>"></p>
	<p>author: <TMPL_VAR META_AUTHOR></p>
	<p><TMPL_VAR META_DESCRIPTION></p>

Your metafile would be 'picture44.jpg.meta' and it would contain:

	___
	author: Joe Schmoe
	description: A wonderful picture.

The default handler does call feed_META() by default. Title, and description are looked for.
If you want to add other meta tags, you should modify the template or create a new one.
Imagine you wanted to add a 'location' meta tag. You would add

	<p><img src="/<TMPL_VAR FILE_REL_PATH>"></p>
	<p>author: <TMPL_VAR META_AUTHOR></p>
	<p><TMPL_VAR META_DESCRIPTION></p>
	<p>Shot at: <TMPL_VAR META_LOCATION></p>

And in your meta file

	___
	author: Joe Schmoe
	description: A wonderful picture.
	location: Kensington, MD.

This provides a very simple way of adding data to resources. Without using an application database, etc.
It's very simple. Take the filename and add a .meta extension, without removing the file's extension.
The meta file *must* reside in the same directory as the file you are setting metadata for.
You can set metadata for directories as well.

You could also set a sitewide metadata file and have your hanlder feed it. In it you could place whatever info
you want, such as contact or address information. Then, to change this data sitewide, you would only do it
to that one YAML text file. And all your site would magically match up.

Meta files can also be hidden, starting with a dot.

Please see L<YAML>

=cut

sub feed_FILE {
	my $tmpl = shift; $tmpl or croak('feed_FILE(): missing tmpl arg');
	my $abs_content = shift; $abs_content||=handler_content(); 
	
	my $hash = _path_to_hash($abs_content);
	
	for (keys %$hash){
		$tmpl->param( "FILE_$_" => $hash->{$_});
	}
	return $tmpl;
}

=head2 feed_FILE()

Required argument is tmpl object.
Optional argument is abs path. If not provided, uses content file. 
Will populate the template with file information, such as filesize, file ctime, atime, rel path, rel location, etc..
returns tmpl object

	feed_FILE($tmpl);
	feed_FILE($tmpl,'/home/myself/public_html/file1.jpg');
	

feeds File::PathInfo variables to template as

	<TMPL_VAR FILE_FILENAME>
	<TMPL_VAR FILE_FILESIZE>
	<TMPL_VAR FILE_CTIME>
	<TMPL_VAR FILE_ABS_PATH>
	<TMPL_VAR FILE_ABS_LOC>
	<TMPL_VAR FILE_REL_LOC>
	<TMPL_VAR FILE_REL_PATH>	
	<TMPL_VAR ...

Note that a directory is also a file.
Here is a sample of the variables set for any file (or directory):


	FILE_ABS_LOC = '/root/devel/autosite2/public_html/tmp'
	FILE_ABS_PATH = '/root/devel/autosite2/public_html/tmp/test.pod'
	FILE_ATIME = 1172618786
	FILE_ATIME_PRETTY = '2007/02/27 18:26'
	FILE_BLKSIZE = 4096
	FILE_BLOCKS = 8
	FILE_CTIME = 1172513325
	FILE_CTIME_PRETTY = '2007/02/26 13:08'
	FILE_DEV = 2049
	FILE_EXT = 'pod'
	FILE_FILENAME = 'test.pod'
	FILE_FILENAME_ONLY = 'test'
	FILE_FILESIZE = '361'
	FILE_FILESIZE_PRETTY = '0k'
	FILE_GID = 0
	FILE_ICON = 'text'
	FILE_INO = 1897024
	FILE_IS_BINARY = 0
	FILE_IS_DIR = 0
	FILE_IS_DOCUMENT_ROOT = 0
	FILE_IS_FILE = 1
	FILE_IS_IN_DOCUMENT_ROOT = 1
	FILE_IS_TEXT = 1
	FILE_IS_TOPMOST = 0
	FILE_MODE = 33188
	FILE_MTIME = 1172513325
	FILE_MTIME_PRETTY = '2007/02/26 13:08'
	FILE_NLINK = 1
	FILE_RDEV = 0
	FILE_REL_LOC = 'tmp'
	FILE_REL_PATH = '/tmp/test.pod.html'
	FILE_SIZE = '361'
	FILE_UID = 0

So, if you would like it when someone calls content 'file1.mpg' as 'file1.mpg.html' to also
see the creation time, you would add this variable to main.html 

	<TMPL_VAR NAME="FILE_CTIME_PRETTY">
	
or

	<tmpl_var name=file_ctime_pretty>

or

	<TMPL_VAR FILE_CTIME_PRETTY>

See also L<File::PathInfo>.

=cut

sub feed_PLUGIN_SITE_MAIN_MENU {
	my $tmpl = shift; $tmpl or croak('feed_PLUGIN_SITE_MAIN_MENU(): missing tmpl arg');
	my $o = shift;
	$o ||= {};
	$o->{match} ||= qr//;
	unless ( defined $o->{text_files_only} ){
		$o->{text_files_only} = 1;
	}
	my $regex = $o->{match};
	

my $default =<<__DEFAULT__;
<style>
.mainmenu { font-size:11px; 
border-bottom:1px solid #ddd;
font-weight:bold;
padding-bottom:0em;}
.mainmenu a {
color:#039;
}
.mainmenu a:hover {
color:#000;
}
.mainmenu img {display:none}
.mainmenu div {display:inline;
white-space:nowrap; margin-right: 1em}
</style>
<div class="mainmenu">

<TMPL_LOOP FILES>
<div>
   &#8227;<img src="/icons/<TMPL_VAR ICON>.png"> 
   <a href="<TMPL_VAR REL_PATH>"><TMPL_VAR FILENAME_ONLY></a>
</div>   
</TMPL_LOOP>

<TMPL_LOOP DIRECTORIES>
<div>
   &#8227;<img src="/icons/<TMPL_VAR ICON>.png"> 
   <a href="<TMPL_VAR REL_PATH>"><TMPL_VAR FILENAME_ONLY></a>
</div>   
</TMPL_LOOP>

</div>
__DEFAULT__

	my $subtmpl= get_tmpl('plugin_site_main_menu.html',\$default);


	my @loop_files;
	my @loop_dirs;

	opendir(DIR, $ENV{DOCUMENT_ROOT});
	my @ls = grep { !/^\./ and ~/$regex/ } readdir DIR;
	closedir DIR;
	   
  # my $x = 5;
   for (@ls){		
	
      my $hash = _path_to_hash( $ENV{DOCUMENT_ROOT}."/$_" ) or next;
      
      if ($hash->{is_dir}){
         push @loop_dirs, $hash;
         next;
      }
      if ($o->{text_files_only}){ # will be on by default
			$hash->{is_text} or next;      
		}	
      
      push @loop_files, $hash;         
   }

   $subtmpl->param( DIRECTORIES => \@loop_dirs );
   $subtmpl->param( FILES => \@loop_files );
	
	$tmpl->param(PLUGIN_SITE_MAIN_MENU => $subtmpl->output);
	return $tmpl;
}

=head2 feed_PLUGIN_SITE_MAIN_MENU()

BETA 

Required argument is tmpl (HTML::Template) object.
Optional argument is a hash ref with options.
Will populate the template with main menu for the site.

returns tmpl object

To override default layout, create a plugin_site_main_menu.html file in AUTOSITE_TMPL directory.
This is the template that is populated and injected into your main template via the template variable PLUGIN_SITE_MAIN_MENU.
Thus, your template needs to have <TMPL_VAR PLUGIN_SITE_MAIN_MENU> for this to be injected.


Opens up DOCUMENT ROOT, looks for any directories and html files and feeds them as main menu options.

	feed_PLUGIN_SITE_MAIN_MENU($tmpl);

Optional arguments:

	feed_PLUGIN_MAIN_MENU(
		$tmpl,{
			match => qr/^\w+$/,
			text_files_only => 1, 
		},
	);	

If you provide a 'match' argument, then it is performed for the listing. In the above example,
only files and directories with word characters beginning to end would shoud up as main menu items.
The 'text_files_only' argument, means that only text files in DOCUMENT ROOT will be considered as 
menu items. This is the default.
This means if you have movie.avi in your DOCUMENT ROOT directory, it would not show as a menu item.

Imagine only files and directories starting with uppercase letters should be considered
to be main menu items..

	feed_PLUGIN_MAIN_MENU($tmpl, { match => qr/^[A-Z]/ } );

No files or directories starting with a dot can be used as main menu items with this subroutine.

=cut

=head1 Handler Subroutines 2

=cut

sub handler_filename {
	my $filename = $0;
	$filename=~s/^.+\///; # take out any leading
	$filename or die('handler_filename(): cant determine filename');
	return $filename;
}

=head2 handler_filename()

no arg, returns filename (no leading dirs) of the calling script (the handler). 

=cut

sub handler_exts {
	my $filename = shift;
	$filename ||= handler_filename(); $filename or croak('handler_exts(): missing script filename');
	
	my $content_ext; #what we handle should have this extension
	my $sgc_ext; # the server generated content (sgc, what we make) should have this extension
	$filename=~/^(\w+)\.(\w+)\..+/ or die("handler_exts(): cant match ext.ext. in [$filename]"); 
	# the calling script can be called anything, but must begin with ext.ext.xxxxxxxxxxxxx
		
	($content_ext,$sgc_ext) = ($1,$2);
	
	return ($content_ext,$sgc_ext);
}

=head2 handler_exts()

Determines what input extension (content) the handler will accept, and what kind of output extension (sgf) is should give.
(Argument can be calling scripts filename. This is default.)
This is determined from the running script's filename.
If you want to determine this from the content request, use request_exts() instead


for example if the script makes sure a mp3 file has a zipped up version on disk.. the handler should be called mp3.zip.pl

	my($content_ext,$sgc_ext) = handler_exts();

This would return for mp3.zip.pl

	('mp3','zip')

First is what the script suggests it can handle, second is what it will output.

You script can also be called

	text.*.pl (for example: text.hi.pl, text.html.pl)

Or 

	binary.*.pl (for example binary.zip.pl, binary.info.pl)

These are catchalls. 

If you name any handler starting with text, the request content file must be -T (text).

If you name any handler starting with binary, the request must be not -T (text);


=cut

sub handler_content {
	my $content_path = shift;
	my $method=0;
	if ($content_path){ # as direct argument
		print STDERR "handler_content($content_path): path was provided as direct argument\n" if DEBUG;
		$method = 1;
	}
	elsif ( defined $ARGV[0] ){ # as argument cli
		$content_path = $ARGV[0]; 
		print STDERR "handler_content($content_path): path was provided from ARGV 0 argument\n" if DEBUG; 
		$method = 2;
	}
	elsif ( $ENV{PATH_TRANSLATED} ){ # as handler
		$content_path = $ENV{PATH_TRANSLATED};
		print STDERR "handler_content($content_path): path was provided from ENV PATH TRANSLATED\n" if DEBUG; 
		$method=3;
	}
	## %ENV
	elsif ( $ENV{REQUEST_URI} ){ # redirected here.. via htaccess rewrite rule
		$content_path = $ENV{DOCUMENT_ROOT}.'/'.$ENV{REQUEST_URI}; $content_path=~s/\.\w{2,}$//;
		print STDERR "handler_content($content_path): path was provided from ENV REQUEST URI\n" if DEBUG; 	
		$method=4;
	}
#	elsif ($ENV{QUERY_STRING}){
#		$content_path = $ENV{DOCUMENT_ROOT}.'/'.$ENV{QUERY_STRING}; $content_path=~s/\.\w{2,}$//;		
#		print STDERR "handler_content(): path was provided as ENV QUERY_STRING\n" if DEBUG; 			
#	}
	
	$content_path or croak('handler_content(): missing path argument');
	
	my ($content_ext, $sgc_ext) = handler_exts();	
	
	#$content_path =~/\.$content_ext$/ or die("file ext is not content ext [$content_ext] for [$content_path]");
	$content_path=~/^\// or $content_path= cwd()."/$content_path";
	
	my $abs_content = Cwd::abs_path($content_path); $abs_content or die("$content_path cannot resolve"); 

	-f $abs_content or die("handler_content(): [$abs_content] is not a file on disk.");
	
	return ($method,$abs_content);#freaky weird..
#	so.. calling 
#  my $path  =   handler_content()
# this way, will get the $abs_content value.. 
}

=head2 handler_content()

Preferably takes no arguments. 
Returns absolute path to content file.

	my $abs_content = handler_content()

provided your handler should be passed one argument (the path to the content), this subroutine
will attempt to read $ARGV[0] and resolve to absolute path.
Optionally, you may give as argument a file path. 

This resolves for symlinks etc.

Note that if the handler's filename is mp3.zip.pl, the argument to the handler must be an mp3 file
This is ok:

	perl mp3.zip.pl /home/xxx/public_html/music/mp3file.mp3

This is not ok:

	perl mp3.zip.pl /home/xxx/public_html/music/mp3file.mpg

It will die.
Which is good. Autosite handlers should not be called as cgi.

The file argument t othe handler script also must resolve to disk and must exist- or this dies.

Returns absolute path to content and method it found .
For the method returns a number 0 through 4, which mean:

	0 no argument
	1 argument  (to sub)
	2 ARGV (cli)
	3 ENV PATH TRANSLATED (apache handler)
	4 REQUEST_URI (redirected via htaccess rewrite)

This is useful as..

	my($method,$abs_content) = handler_content()
	print "Content-Type: text/html\n\n" if $method > 2;
	
=cut

sub handler_sgc {
	my $abs_content = shift;
	$abs_content ||= handler_content();
	
	my ($content_ext, $sgc_ext) = handler_exts();	

	my $abs_sgc = "$abs_content.$sgc_ext"; 
	return $abs_sgc;
}

=head2 handler_sgc()

Optionally takes a file path argument. 
Returns absolute path to where the sgc should be for this content. 

	my $abs_sgc = handler_sgc();

In the above example for handler_content() you see 

	perl mp3.zip.pl /home/xxx/public_html/music/mp3file.mp3

The above $abs_sgc variable would in this example hold '/home/xxx/public_html/music/mp3file.mp3.zip'

=cut

sub handler_tmpl {

	my $default = <<__DEFAULT__;
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title><TMPL_VAR TITLE></title>
<meta name="keywords" content="<TMPL_VAR META_KEYWORDS>">
<meta name="description" content="<TMPL_VAR META_DESCRIPTION>">
<meta name="author" content="<TMPL_VAR META_AUTHOR>">
<link href="/.tmpl/default.css" rel="stylesheet" rev="stylesheet" type="text/css" />
</head>
<body>

<div class="title"> <TMPL_VAR VERSION></div>

<TMPL_VAR PLUGIN_SITE_MAIN_MENU>
<TMPL_VAR PLUGIN_PATH_NAVIGATION>

<h1><TMPL_IF META_TITLE><TMPL_VAR META_TITLE><TMPL_ELSE><TMPL_VAR FILE_FILENAME_ONLY></TMPL_IF></h1>

<div class="body">
<TMPL_VAR BODY>
</div>

<TMPL_IF META_DESCRIPTION>
<div class="meta_description"><TMPL_VAR META_DESCRIPTION><div>
</TMPL_IF>

<TMPL_UNLESS FILE_IS_DIR>
 <TMPL_VAR PLUGIN_FILE_INFO>
</TMPL_UNLESS>

<div class="footer"><TMPL_VAR VERSION></div>

</body>
</html>
__DEFAULT__

	my $tmpl = get_tmpl('main.html',\$default);
} 

=head2 handler_tmpl()

Takes no argument. Seeks for ENV AUTOSITE_TMPL / main.html
Returns the main template HTML::Template object.
If none exists at AUTOSITE_TMPL, default is used.

=cut

sub handler_write_sgc {
	my $tmpl = shift;
	my $abs_sgc = shift;
	$abs_sgc ||= handler_sgc();

	my $out = $tmpl->output;

	#-w $abs_sgc or 	
	
	open(SGC,">$abs_sgc") or die("cannot open output for sgc[$abs_sgc], $!");
	print SGC $out;
	close SGC;
	return 1;
}

=head2 handler_write_sgc()

Argument is template object, optionally, the abs sgc. 
Returns true.

	handler_write_sgc($tmpl); # save to path returned by handler_sgc()

	handler_write_sgc($tmpl, $abs_sgc); # if you wanted to save elsewhere

Handlers should by default print to stdout?

=cut 

#}}}

# Glossary # {{{

=head1 GLOSSARY

=item user

The person who manages the L<content> on the site. This is the person who paid you to host and or design their site.

=item designer

The person who manages look and feel of the site. This person is in charge of layout, graphic design, and 
altering the templates.

=item handler

In this document a 'handler' is a script that creates L<sgc> on the fly.

Example: If you have a pod-html handler.
The user uploads file.pod. Then someone opens a browser and types in domain.com/file.pod.html, if the file does not exist,
the handler creates the file. This is managed by the L<router>.

The handler is in charge of fetching your templates, etc and generating content.

A handler is NOT a cgi script. It should function perfectly well as a cli tool.
Various handlers are included in this distro.

One of the major highlights of this system is to allow you to easily add new handlers without doing more then dropping in a file. 

=item content

This is what the L<user> uploads to the site. If your user is a band who paid you to host or design their site, then they may be uploading songs, for example. Then some of their content will be for example; song1.mp3, song2.mp3. 
Maybe they have a bio page, this would be bio.txt. Maybe they are uploading a press kit in zip format, press_kit.zip. These are all content files.
When you are designing a site in a conventional manner, you have the client email you their 'about us' text, 'contact info'- maybe some pictures. With autosite, the L<user> can upload all that content to the website and it is instantly presented with the layout you designed.

=item sgc

The (s)erver (g)enereated (c)ontent.
A 'server generated content' file is a file that was generated by a handler, about a content file.
It is automated content, about user provided content.

Example:
The user content is 'file.mp3'. This file resides in DOCUMENT ROOT. Thus, to download the file:

	http://domain.com/file.mp3

However, what if you want to see a presentation about the file, maybe am excerpt, a link to a zip file?

	http://domain.com/file.mp3.html
	
And maybe you just want to download a zipped up copy

	http://domain.com/file.mp3.zip

The html and the zip files are what we refer to as sgc.	
	
Sgc files should be regarded with contempt- they are not precious. They should not be edited directly. That
would defeat the whole purpose of autosite.

The sgc files can be extremely fine tuned via the editing of L<HTML::Template> files provided. New ones can be created.
Also, you are welcome to code your own L<handler> for whatever.

=item router

The router takes the client browser requests and forwards them to the appropriate handler, if one exists.
The router is a cgi script, an L<.htaccess> file is required to forward 404 errors to this script.

=item .htaccess

The htaccess file is crucial to the autosite system.
It should catch 404 errors and send them to the L<router>.

Example .htaccess file entry:

	ErrorDocument 404 /cgi-bin/autosite/router.cgi

=item ENV AUTOSITE_TMPL

Required for use with router, handlers.
Environment variable. This is the absolute path to templates directory.

=item main template

Required for use with router and handlers.
Must reside in L<ENV AUTOSITE_TMPL>. 
Must be named main.html.
This template's only required L<TMPL_VAR> is BODY.

=cut

#}}}


=head1 DEBUGGING

To debug, set DEBUG to 1

	use WWW::Autosite;
	WWW::Autosite::DEBUG = 1;

=cut

=head1 SEE ALSO

L<HTML::Template>
L<File::PathInfo>

=head1 AUTHOR

Leo Charre

=cut

1;


