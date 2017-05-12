package WWW::Blog::Identify;

use strict;
use warnings;

require Exporter;
 
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/identify/;


our $VERSION = '0.06';


sub identify {
	my ($url, $text) = @_; 
	
	$url = lc( $url ); 
	local $_ = $url;
	
	# patterns ordered roughly in terms of frequency


	#
	# 	URL CHECKING
	#
	
	return "blogspot" if /\.blogspot\.com/o;
	return "blogger" if m|\.blogger\.com/|o;
	
	return "blogger (br)" if  m|\.blogger\.com\.br|o; # Brazilian Blogger
	return 'terra' if  m|weblogger\.(terra\.)?com\.br/|o;
	return "diaryland" if  /\.diaryland\./o;
	return "livejournal" if  /\.livejournal\.com/o;
	return "journalspace" if  /\.journalspace\.com/o;
	return "blogalia" if  /\.blogalia\.com/o;
	return "pitas" if  /\.pitas\.com/o;
	return "persianblog" if  /\.persianblog\.com/o; # Farsi
	return "persianlog" if  /\bpersianlog\.com/o;  # Farsi
	return "diaryhub" if  /\.diaryhub\.(?:com|net)\/?$/io; # Thai
	
	return "radio" if  /radio.weblogs\.com/o;
	return "radio" if /blogs.law.harvard.edu/o;
	return "radio" if /\.blogs.it\b/o;	
	
	return "manila" if  /\.manilasites\.com/o;
	return "manila" if  /\.editthispage\.com/o;
	return "manila" if  m|\.weblogger\.com/|o;
	return "manila" if  m|\.weblogs\.com/|o;
	
 	return "20six" if m|\.20six\.|o;
 	return "typepad" if m|\.typepad\.|o;
	
	return "twoday" if  /\.twoday\.net/o;
	return "salon" if  /blogs\.salon\.com/o;
	return "splinder" if  /\.splinder\.it/o;		# Italy
	return "diarist" if  /\.diarist\.com/o;
	return "antville" if  /\.antville\.org/o;
	return 'bloggingnetwork' if  m|\.bloggingnetwork\.com/blogs|o;
	return "crimsonblog" if  /\.crimsonblog\./o;
	return "skyblog" if  /\.skyblog\.com/o;	# French
	
	return "blog.pl (polish)" if  /\.blog\.pl/o;
	return "e-blog.pl (polish)" if  /\.e-blog\.pl/o;
	return "weblog.pl (polish)" if  /\.weblog\.pl/o;
	
	return "twoday" if  /\.twoday\.net/o;
	return "monblogue" if  /\.monblogue\.com/o;
	return 'joueb' if  m|joueb\.com/|o;				# France
	return 'blogstudio' if  m|\.blogstudio\.com/|o;
	return 'blog-city' if  m|blog-city\.com/|o;
	return 'blogsky' if  m|\.blogsky\.com/|o;		# English and Persian
	return 'u-blog' if  m|u-blog\.net/|o;	 		# France
	return 'barrapunto' if  m|\bbarrapunto\.com/index\.pl|o;	# Spain
	return 'blig' if  m|\.blig\.(?:ig.)?com\.br|o;	# Brazil
	return 'g-blog' if  m|g-blog\.net/|o;
	return 'babelogue' if m|babelogue\.citypages\.com|io;
	return 'jevon' if m|\.jevon\.org/|io;
	return 'tripod' if m|\.tripod\.com/|io;
	
	return 'xanga' if m|\.xanga\.com|o;
	#
	#	 CONTENT CHECKING
	#

	local $_ = $text;
	
	# First, check META tags
	
	return "postnuke" if m|CONTENT="Post-?Nuke|io;	# Nuke is nice enough to use META tags
	return "php-nuke" if m|CONTENT="PHP-?Nuke|io;
	return "microsoft" if m|<meta[^>]+Content=['"]Microsoft Visual|io;
	return "nucleus" if m|<meta[^>]+content=['"]Nucleus|io;
	return "greymatter" if m|<meta[^>]+content=['"]Greymatter|io;
	return "land down under" if m|<meta[^>]+content=['"]Land Down Under|io;
	
	# Next, check actual content
	
	return "movable type" if m|cgi-bin/mt|o;
	return "movable type" if m|Powered by.*Move?able ?Type|io; # common typo is 'Moveable'
	return "movable type" if m|mtblog.gif|io;
	return "movable type" if m|move?abletype.gif|o;
	return "movable type" if m!function Open(Trackback|Comments)\s+\(c\)!o; # default MT JavaScript

	return "blogger pro" if m|powered_by_blogger_pro[0-9]*\.gif|io;
	return "blogger pro" if m|powered by:? <a href="[^>]+>blogger pro</a>|io;
		
	return "blogger" if m|bloggerbutton[0-9]+.gif|io;
	return "blogger" if m|bloggertemplate[^.]+.gif|io;
	return "blogger" if m|blogger_bluelong.gif|o;
	return "blogger" if m|powered by (<a href="[^>]+>)?blogger(</a>)?|io;
	
	return "radio" if m|img src="http://radio.weblogs.com|io;
	return "radio" if m|http://radio.xmlstoragesystem.com/weblogStats|oi;
	return "radio" if m|images/radioUserLand|oi;
	return "radio" if m|xmlCoffeeCup|oi;
	
	return "manila" if m|thisIsAManilaSite|oi;
	
	return "cafelog" if m!function b2(?:open|comment)!o;	# default cafelog JavaScript
	return "cafelog" if m|powered by (<a href="[^>]+)?b2|io;
	
	return "pivot" if m|<!-- Created with Pivot [0-9.]+ -->|io;
	return "pivot" if m|pivot-?banner[^.]*.gif|io;
	
	return "textpattern" if m|txp_slug|o;
	return "blosxom" if /blosxom\.gif/o;
	
	return "slogger" if /Created by Slogger/io;
	
	return "greymatter" if /gm-icon.gif/o;
	return "greymatter" if /Powered by Greymatter/io;
	
	return "pMachine" if m|alt="[^"]+ pMachine|io; # This can be "Powered by" or "Gemaakt mit", for example
	return "pMachine" if m|powered by (?:<a href="[^>]+>)?pMachine|io;
	return "pMachine" if m|pmachine.gif|io;
	
	return "psychoblogger" if m|Powered by (?:<a [^>]+>)?Psychoblogger|io;
	return "WebCrimson" if m|Powered by (?:<a [^>]+>)?WebCrimson|io;
	
	# Tests of last resort
	my @blog_count = $text =~ /\bblog\b/gi;
	
	return "suspected by URL" if $url =~ /[\W\-_](?:we)?blog/o;
	return "suspected by URL" if $url =~ /\bbitacoras\b/i;
	return "suspected by rss" if $text =~ /\brss\b/i;
	return "suspected by content" if scalar @blog_count > 5;
	
	return;
	
}

1;

__END__


=head1 NAME

WWW::Blog::Identify - Identify blogging tools based on  URL and content

=head1 SYNOPSIS

  use WWW::Blog::Identify "identify";
  
  my $flavor = identify( $url, $html );
  
=head1 FUNCTIONS

=over

=item identify URL, HTML

Attempts to identify the blog based on an examination of the URL and content. Returns undef if
all tests fail, otherwise returns a guess as to the blog 'flavor'.


=head1 DESCRIPTION

This is a heuristic module for identifying weblogs based on their URL and content.
The module is a compilation of identifying patterns observed in the wild, for a variety
of blogging tools and providers worldwide.   You can read a full list of blogs represented
in the README.  Please email the author if you have a blogging engine you would like
added to the detector.

The module first checks the URL for common blog hosts (BlogSpot, Userland, Persianblog, etc.)
and returns immediately if it can find a match.  Failing that,  it will look through the blog HTML for distinctive markers (such as "powered by" images)
or META generator tags.   As a last resort, it will test to see if the page contains
an RSS feed, or has the word 'blog' in it repeated at least five times. 

The philosophy of this module is to favor false negatives over false positives.  If you
are a blog tool author, you can vastly improve the detection rate simply by using a generator
tag in your default template, like this:

E<lt>meta name="generator" content="myBlogTool 0.01" /E<gt>

This module is in active use on a large blog index, so I'll try to keep it reasonably 
up to date.

=head2 EXPORT

None by default.  You can export 'identify' out into your namespace if you like.


=head1 AUTHOR

Maciej Ceglowski, E<lt>developer@ceglowski.comE<gt>

=head1 COPYRIGHT

(c) 2003  Maciej Ceglowski

This module is distributed under the same license as Perl itself.

=cut
