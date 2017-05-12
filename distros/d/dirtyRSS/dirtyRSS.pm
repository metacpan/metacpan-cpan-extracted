package dirtyRSS;

use strict;
use warnings;

require Exporter;

@dirtyRSS::ISA = qw[Exporter];
@dirtyRSS::EXPORT = qw[&parse &disptree];
$dirtyRSS::VERSION = '0.3';

our %htmlescapes = (
		    'quot' => 34,
		    'amp' => 38,
		    'apos' => 39,
		    'lt' => 60,
		    'gt' => 62,
		    'nbsp' => 32, # Was 160, but we make it a normal space
		    'iexcl' => 161,
		    'cent' => 162,
		    'pound' => 163,
		    'curren' => 164,
		    'yen' => 165,
		    'brvbar' => 166,
		    'sect' => 167,
		    'uml' => 168,
		    'copy' => 169,
		    'ordf' => 170,
		    'laquo' => 171,
		    'not' => 172,
		    'shy' => 173,
		    'reg' => 174,
		    'macr' => 175,
		    'deg' => 176,
		    'plusmn' => 177,
		    'sup2' => 178,
		    'sup3' => 179,
		    'acute' => 180,
		    'micro' => 181,
		    'para' => 182,
		    'middot' => 183,
		    'cedil' => 184,
		    'sup1' => 185,
		    'ordm' => 186,
		    'raquo' => 187,
		    'frac14' => 188,
		    'frac12' => 189,
		    'frac34' => 190,
		    'iquest' => 191,
		    'agrave' => 192,
		    'aacute' => 193,
		    'acirc' => 194,
		    'atilde' => 195,
		    'auml' => 196,
		    'aring' => 197,
		    'aelig' => 198,
		    'ccedil' => 199,
		    'egrave' => 200,
		    'eacute' => 201,
		    'ecirc' => 202,
		    'euml' => 203,
		    'igrave' => 204,
		    'iacute' => 205,
		    'icirc' => 206,
		    'iuml' => 207,
		    'eth' => 208,
		    'ntilde' => 209,
		    'ograve' => 210,
		    'oacute' => 211,
		    'ocirc' => 212,
		    'otilde' => 213,
		    'ouml' => 214,
		    'times' => 215,
		    'oslash' => 216,
		    'ugrave' => 217,
		    'uacute' => 218,
		    'ucirc' => 219,
		    'uuml' => 220,
		    'yacute' => 221,
		    'thorn' => 222,
		    'szlig' => 223,
		    'agrave' => 224,
		    'aacute' => 225,
		    'acirc' => 226,
		    'atilde' => 227,
		    'auml' => 228,
		    'aring' => 229,
		    'aelig' => 230,
		    'ccedil' => 231,
		    'egrave' => 232,
		    'eacute' => 233,
		    'ecirc' => 234,
		    'euml' => 235,
		    'igrave' => 236,
		    'iacute' => 237,
		    'icirc' => 238,
		    'iuml' => 239,
		    'eth' => 240,
		    'ntilde' => 241,
		    'ograve' => 242,
		    'oacute' => 243,
		    'ocirc' => 244,
		    'otilde' => 245,
		    'ouml' => 246,
		    'divide' => 247,
		    'oslash' => 248,
		    'ugrave' => 249,
		    'uacute' => 250,
		    'ucirc' => 251,
		    'uuml' => 252,
		    'yacute' => 253,
		    'thorn' => 254,
		    'yuml' => 255
);

# These are typical HTML tags, which should be omitted.

our %ignore_tags = (
		    'img'     => 1,
		    'a'       => 1,
		    'p'       => 1,
		    'br'      => 1,
		    'div'     => 1,
		    'span'    => 1,
		    'b'       => 1,
		    'i'       => 1,
		    'u'       => 1,
		    'body'    => 1,
		    'center'  => 1,
		    'code'    => 1,
		    'font'    => 1,
		    'form'    => 1,
		    'h1'      => 1,
		    'h2'      => 1,
		    'h3'      => 1,
		    'h4'      => 1,
		    'head'    => 1,
		    'hr'      => 1,
		    'html'    => 1,
		    'li'      => 1,
		    'ul'      => 1,
		    'ol'      => 1,
		    'pre'     => 1,
		    'style'   => 1,
		    'sub'     => 1,
		    'sup'     => 1,
		    'script'  => 1,
		    'small'   => 1,
		    'big'     => 1,
		    'table'   => 1,
		    'td'      => 1,
		    'tr'      => 1,
		    'th'      => 1,
		    'textarea'=> 1,
		    'strong'  => 1,
		    'strike'  => 1,
		    'blockquote' => 1,
	      );

our %ns = (
	   # RSS 2.0 tags
	   'xml'          => 'xml',
	   'rss'          => 'rss',
	   'rdf'          => 'rdf',
	   'item'         => 'item',
	   'channel'      => 'channel',
	   'image'        => 'image',
	   'title'        => 'title',
	   'link'         => 'link',
	   'description'  => 'description',
           'language'     => 'language',
	   'copyright'    => 'copyright',
	   'pubdate'      => 'pubdate',
	   'lastbuilddate'=> 'lastbuilddate',
	   'category'     => 'category',
	   'generator'    => 'generator',
	   'ttl'          => 'ttl',
	   'url'          => 'url',
	   'width'        => 'width',
	   'height'       => 'height',
	   'version'      => 'version',
	   'encoding'     => 'encoding',
	   'guid'         => 'guid',
	   'enclosure'    => 'enclosure',

	   # RSS 1.0 tags translated to RSS 2.0
	   'subject'      => 'category',
	   'rights'       => 'copyright',
	   'modified'     => 'lastbuilddate',
	   'date'         => 'pubdate',
	   'resource'     => 'resource', # 1.0 specific!

	   # Atom 1.0 tags translated to RSS 2.0
	   'feed'      => 'channel',
	   'summary'   => 'description',
	   'content'   => 'description',
	   'subtitle'  => 'description',
	   'lang'      => 'language',
	   'published' => 'pubdate',
	   'updated'   => 'lastbuilddate',
	   'logo'      => 'image',
	   'entry'     => 'item',
	   'href'      => 'link',
	  );

# Note that %specials refer to the *right* side of %ns, so only one
# entry is needed for each functional tag or its alias

# TRUE means array type
our %specials = (
		 'item' => 1,
		 'channel' => 1,
		 'image' => 1,
		 'xml' => 0,
		 'rss' => 0,
		 'rdf' => 0,
		);

sub parse {
  my ($in, $debug) = @_;
  
  $in =~ s/<!--.*?-->//gs; # Remove comments

  my @segs = map { /^[ \n\r\t]*(.*?)[ \n\r\t]*$/s } ($in =~ /(<!\[CDATA\[.*?\]\]>|<[^>]+?>|[^<]+)/gs);
  
  # Strip off CDATAs. Added a prefix space to avoid accidental tag hits
  @segs = map { /^<!\[CDATA\[(.*?)\]\]>$/s ? " $1" : $_ } @segs;

  @segs = grep { length > 0 } @segs;
  
  my @stack = ();
  my @valstack = ();
  my %tree = ();
  my $here = \%tree;
  my @parent = ();
  my $lastval = "";
  
  foreach my $elem (@segs) {
    my ($modifier, $tag, $attr, $empty) = ($elem =~ /^<([!?\#]{0,1})[ \n\r\t]*([^ \n\r\t]*[^ \/\n\r\t])[ \n\r\t]*(.*?)[ \n\r\t]*(\/{0,1})>$/s);

    $empty = 1 if ($modifier); 
    
    if (defined $tag) {
      $tag = lc $tag;		# We're case-insensitive

      # Note that the regex below removes "dc:"-like namespace prefices
      my $closing;
      ($closing, $tag) = ($tag =~ /^(\/{0,1}).*?:{0,1}([^:]*)$/);

      if ($ignore_tags{$tag}) {
	htmltags($here, unescape($elem));
	next;
      }
      
      unless ($closing) {	# Opening tags...
	push @stack, $tag;
	
	my $alias = $ns{$tag};
	
	if (defined $alias) {
	  push @valstack, $lastval;
	  $lastval = "";

	  if (defined $specials{$alias}) {
	    push @parent, $here;
	    $here = {};	    
	  }

	  # Note that attributes may pollute the parent hash. This is
	  # necessary to support Atom 1.0

	  my @pairs = ($attr =~ /([^ \n\r\t]+?=\'[^\']*?\'|[^ \n\r\t]+?=\"[^\"]*?\"|[^ \n\r\t]+?=[^ \n\r\t]*)/g);
	  
	  foreach my $p (@pairs) {	    
	    my ($k, $v) = ($p =~ /(.+?)=(.*)/);

	    $k = lc $k;

	    $v = $1 
	      if (($v =~ /^\'(.*)\'$/s) || ($v =~ /^\"(.*)\"$/s));    
	    
	    ($k) = ($k =~ /([^:]*)$/); # Remove namespace prefix if present
	    
	    my $alias = $ns{$k};
	    
	    if (defined $alias) {
	      $here->{$alias} = unescape($v);
	    } else {
	      warn "Ignored attribute $k=$v\n"
		if $debug;
	    }
	  }	 
	} else {
	  warn "Ignored tag $tag\n"
	    if $debug;
	}
      }
      
      if ($closing || $empty) { # Closing tags, or close an empty opening tag
	my $p = pop @stack;
	
	return "Bad XML tag nesting. Expected end tag for '$p', got '/$tag'"
	  unless ($p eq $tag);
	
	my $alias = $ns{$tag};
	
	if (defined $alias) {
	  my $thislastval = $lastval;
	  $lastval = pop @valstack;
  
	  if (defined $specials{$alias}) {
	    my $parent = pop @parent;
	    
	    if ($specials{$alias}) { # Array type
	      $parent->{$alias} = []
		unless ((ref $parent->{$alias}) &&
			(ref $parent->{$alias}) eq 'ARRAY');
	      push @{$parent->{$alias}}, $here;
	    } else {
	      $parent->{$alias} = $here;
	    }
	    
	    # UGLY HACK ALERT:
	    # Just before leaving a tree node, we clean the 'description'
	    # from possible HTML tags, and harvest the relevant values,
	    # if applicable. This is because some feeds think that the
	    # description should be rendered on a browser as is (cross
	    # scripting, anybody?)

	    $here->{'description'} =~ s/(<.*?>)/htmltags($here, $1)/ges
	      if (defined $here->{'description'});
	   
	    $here = $parent;	
	  } else {
	    $here->{$alias} = unescape($thislastval)
	      unless ((length($thislastval) == 0) &&
		      (defined $here->{$alias}) &&
		      (length $here->{$alias}));	    
	  }
	}
      }
    } else {
      $lastval = (length $lastval) ? "$lastval $elem" : $elem;    
    }
    
  }
  return("Bad XML nesting: There were unclosed tags at EOF")
    if (@stack);
  
  return \%tree;
  
}

sub htmltags {
  my ($here, $seg) = @_;

  my ($tag, $attr) = ($seg =~ /^<[ \n\r\t]*([^ \n\r\t]+)[ \n\r\t]*(.*?)[ \n\r\t]*>$/s);

  return "" unless (defined $tag);

  $tag = lc $tag;

  # Respect HTML line breaks, even though the renderer won't
  return "\n"
    if (($tag eq 'p') || ($tag eq 'br'));

  if (($tag eq 'img') && !(defined $here->{'altimage'})) {
    my $new = {};
    $here->{'altimage'} = $new;
    $here = $new;
  } elsif (($tag eq 'a') && !(defined $here->{'altlink'})) {
    my $new = {};
    $here->{'altlink'} = $new;
    $here = $new;
  } else { return ""; }
	   
  my @pairs = ($attr =~ /([^ \n\r\t]+?=\'[^\']*?\'|[^ \n\r\t]+?=\"[^\"]*?\"|[^ \n\r\t]+?=[^ \n\r\t]*)/g);
  
  foreach my $p (@pairs) {	    
    my ($k, $v) = ($p =~ /(.+?)=(.*)/);
    
    $k = lc $k;

    $v = $1 
      if (($v =~ /^\'(.*)\'$/s) || ($v =~ /^\"(.*)\"$/s));    
    
    $here->{$k} = $v;
  }
  
  return ""; # This makes the function useful in substitutions
}

sub single_unescape {
  my ($ent) = @_;

  my $ord = $htmlescapes{lc($ent)};
  return chr($ord) if defined $ord;
  return ""; # Conversion failed, return nothing
}

sub unescape {
  # Note! Unicode characters are escaped to space!
  my ($x) = @_;
  # For now, we go wild, and convert all escape markers

  # Run twice, because of double-nested markups :-O
  for (my $i=0; $i<2; $i++) {
    $x =~ s/&(\w+);/single_unescape($1)/ge;
    $x =~ s/&\#(\d+);/chr($1 < 256 ? $1 : 32)/ge;
    $x =~ s/&\#x([0-9a-fA-F]+);/chr(hex($1) < 256 ? hex($1) : 32)/ige;
  }
  return $x;
}

sub disptree {
  my ($what, $s) = @_;

  foreach my $k (sort keys %{$what}) {
    my $v = $what->{$k};

    if ((ref $v) eq 'HASH') {
      print " "x$s."$k\n";
      disptree($v, $s+2);
      next;
    }

    if ((ref $v) eq 'ARRAY') {
      my $count;
      for ($count=0; $count<=$#{$v}; $count++) {
	print " "x$s.$k."[$count]\n";
	disptree($v->[$count], $s+2);
      }
      next;
    }

    print " "x$s."$k => $v\n";    
  }    
}

1;

__END__

=head1 NAME

dirtyRSS - A dirty but self-contained RSS parser

=head1 SYNOPSIS

  use dirtyRSS;

  $tree = parse($in);

  die("$tree\n") unless (ref $tree);

  disptree($tree, 0);

=head1 DESCRIPTION

dirtyRSS is a terribly dirty RSS parser, which doesn't require any other module
to work. It parses a string, and creates a tree, which represents the RSS feed.

It doesn't support the complete XML syntax, only things that are commonly used
in feeds.

All tags are lowercased, namespace indicators are removed, and several typical
non-RSS-2.0 tags are translated shamelessly to their 2.0 counterpart. There is
also plenty of fiddling with the data on the way.

The only good thing about this parser, is that it works most of the time, and
it makes the tree look as if it came from an RSS 2.0, for a large parts of
feeds of various sorts.

If the parse fails, an error message is passed via the return value, rather
than a reference to an array.

=head1 EXPORT

The following functions are exported:

parse() and disptree().

=head1 BUGS

The module is based upon trials and errors, so naturally there are going to
be more errors.

=head1 LICENSE

This module is released to the open domain. There are no restrictions using
it.

=head1 HISTORY

The module is part of the Editaste site, L<http://www.editaste.com/rawlist>

=head1 AUTHOR

Eli Billauer, E<lt>perldev@editaste.comE<gt>

=cut
