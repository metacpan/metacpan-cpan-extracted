#

=head1 NAME

Text::EtText::HTML2EtText - convert from HTML to the EtText editable-text
format

=head1 SYNOPSIS

  my $t = new Text::EtText::HTML2EtText;
  print $t->html2text ($html);

or

  my $t = new Text::EtText::HTML2EtText;
  print $t->html2text ();			# from STDIN

=head1 DESCRIPTION

ethtml2text will convert a HTML file into the EtText editable-text format,
for use with webmake or ettext2html.

For more information on the EtText format, check the WebMake documentation on
the web at http://webmake.taint.org/ .

=head1 METHODS

=over 4

=cut

package Text::EtText::HTML2EtText;

use Carp;
use strict;
use locale;
use HTML::Entities;

use vars qw{
	@ISA
};

@ISA = qw();

###########################################################################

=item $f = new Text::EtText::HTML2EtText

Constructs a new C<Text::EtText::HTML2EtText> object.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    # in parameters:
    'text_line_width'	=> 72,		# line width
    'text_wrap_lines'	=> 1,		# wrap to fit in line width
    'text_strip_para_fonts' => 1,	# strip font tags surrounding paras
    'text_link_indent'	=> '    ',	# default indent for links

    'html_link_open'	=> '[[',		# characters used to wrap links
    'html_link_close'	=> ']]',		# characters used to wrap links
  };

  bless ($self, $class);
  $self;
}

###########################################################################

=item $text = $f->html2text( [$html] )

Convert HTML, either from the argument or from STDIN, into EtText.

=cut

sub html2text {
  my ($self, @txt) = @_;
  local ($_);

  my $txt = '';

  if ($#txt >= 0) {
    $txt = join ('', @txt);
  } else {
    while (<STDIN>) { $txt .= $_; }
  }

  my $line1 = ('-' x $self->{text_line_width});

  $txt =~ s{<!--etsafe-->(.*?)<!--\/etsafe-->}{
    "<!--etsafe-->".&protect_html ($1)."<!--/etsafe-->";
  }gies;
  $txt =~ s{<listing>(.*?)<\/listing>}{
    "<listing>".&protect_html ($1)."</listing>";
  }gies;
  $txt =~ s{<xmp>(.*?)<\/xmp>}{
    "<xmp>".&protect_html ($1)."</xmp>";
  }gies;
  $txt =~ s{<pre>(.*?)<\/pre>}{
    "<pre>".&protect_html ($1)."</pre>";
  }gies;

  $txt =~ s/\s+/ /gs;
  $txt =~ s/^ //gs;
  $txt =~ s/ $//gs;
  $txt =~ s/ *<p> */\n\n/gis; $txt =~ s/\s*<\/p>\s*/\n\n/gis;
  $txt =~ s/<br(?:| [^>]+)>\s*/\n/gis;

  $txt =~ s/(<table(?:| [^>]+)>\s*)/\n\n$1/gis;
  $txt =~ s/<(td|tr)(?:| [^>]+)>\s*/\n<$1>\n\n/gis;
  $txt =~ s/<\/(td|tr)>\s*/\n\n<\/$1>\n/gis;
  $txt =~ s/<\/(table)>\s*/\n<\/$1>\n\n/gis;

  $txt =~ s/<hr(?:| [^>]+)>\s*/\n${line1}\n/gis;
  $txt =~ s/<h1>\s*(.*?)\s*<\/h1>\s*/"\n\n$1\n".('=' x length($1))."\n\n";/geis;
  $txt =~ s/<h2>\s*(.*?)\s*<\/h2>\s*/"\n\n$1\n".('-' x length($1))."\n\n";/geis;
  $txt =~ s/<h3>\s*(.*?)\s*<\/h3>\s*/"\n\n$1\n".('~' x length($1))."\n\n";/geis;

  $txt =~ s/\n[ \t]+/\n/gs;
  $txt =~ s/^\s+//gs;
  $txt =~ s/\s+$//gs;

  $txt =~ s{\s*<ul>(.*?)<\/ul>\s*}{ &html2text_list ('ul', $1, '-'); }geis;
  $txt =~ s{\s*<ol>(.*?)<\/ol>\s*}{ &html2text_list ('ol', $1, '1.'); }geis;

  $txt =~ s{\s*<blockquote>(.*?)<\/blockquote>\s*}{
    $_ = $1; s/^/    /gm; "\n\n$_\n\n";
  }gies;

  $txt =~ s,<b>(\w.*?\w)<\/b>,\*\*$1\*\*,gis;
  $txt =~ s,<i>(\w.*?\w)<\/i>,\_\_$1\_\_,gis;
  $txt =~ s,<code>(\w.*?\w)<\/code>,\#\#$1\#\#,gis;

  # convert "quotes" to ''quotes'', but keep parameters inside
  # HTML tags safe, and preserve double-apostrophes.
  $txt =~ s{<[^>]+>}{$_ = $&; s/\"/__ET_QUOTE__/g; $_;}gies;
  $txt =~ s,'',\&\#39;\&\#39;,gs;
  $txt =~ s,\"(.*?)\",''$1'',gis;
  $txt =~ s/__ET_QUOTE__/\"/g;		# fix vim: "

  # square-bracket entities.
  $txt =~ s/\[/\&etsqi;/gs;
  $txt =~ s/\]/\&etsqo;/gs;

  $self->{links} = { };
  $self->{href2label} = { };
  $self->{linkdict} = { };
  $self->{linknum} = 0;
  $self->{thislink} = 0;

  $txt =~ s{\B<a href=([^>]+)>(.*?)<\/a>\B}{
    $self->h2t_fix_link ($1, $2);
  }gies;

  # decode HTML entities.
  $txt =~ s/&nbsp;/ /gs;	# never mind that \240 wierdness!
  decode_entities ($txt);

  # split into lines to strip off paragraph-surrounding <font> tags.
  # s///gm does not seem to work here unfortunately.
  #
  if ($self->{text_strip_para_fonts}) {
    my $newtxt = '';
    foreach $_ (split (/\n/, $txt)) {
      if (/font/i) {
	# strip <font> tags around paragraphs
	1 while s/^\s*<font\s[^>]+>\s*//gi;
	# and around list items
	1 while s/^(\s*[\*\#\-]\s+)<font\s[^>]+>\s*/$1/gi;
	# and the closing tags
	1 while s/\s*<\/font>\s*$//gi;
      }

      $newtxt .= $_."\n";
    }
    $txt = $newtxt; undef $newtxt;
  }

  my @lines = split (/\n/, $txt); $txt = '';
  my $paradict = '';

  foreach $_ (@lines) {
    if ($self->{thislink} != 0) {
      while (/\B\[(\d+)\]\B/g) {
	if (!defined $self->{linkdict}->{$1}) { next; }
	if ($paradict eq '') { $paradict = "\n\n"; }
	$paradict .= $self->{linkdict}->{$1}; undef $self->{linkdict}->{$1};
      }
    }

    $txt .= $_."\n";

    if ($self->{thislink} != 0) {
      if (/^\s*$/) {
	$txt .= $paradict."\n\n"; $paradict = '';
      }
    }
  }

  $txt .= $paradict; $paradict = '';

  # wrap each line after $line_width columns. Preserve indentation
  # caused by <blockquote> tags, lists etc.
  #
  if ($self->{text_wrap_lines}) {
    my @lines = split (/\n/, $txt); $txt = '';
    my $indent = '';
    my $last_was_blank = 1;
    my $is_blank = 1;
    my $cur_width;

    foreach $_ (@lines) {
      $last_was_blank = $is_blank;
      if (/^\s*$/) { $is_blank = 1; }
      else { $is_blank = 0; }

      s/^(\s*)//;
      if ($last_was_blank) {
	$indent = $1;
      } elsif (/^\[\S+\]/) {
	$indent = $self->{text_link_indent};		# links
      } else {
	$indent = '';
      }

      $cur_width = $self->{text_line_width} - length($indent) - 5;
      while (s/^(.{${cur_width}}\S*)\s+//) { $txt .= $indent.$1."\n"; }
      $txt .= $indent.$_."\n";
    }
    undef @lines;
  }

  # compress spaces down to one blank line at most.
  $txt =~ s/([ \t]*\n){3,}/\n\n/gs;

  undef $self->{links};
  undef $self->{href2label};
  undef $self->{linkdict};
  undef $self->{linknum};
  undef $self->{thislink};

  $txt = &unprotect_html ($txt);
  $txt;
}

sub h2t_fix_link {
  my ($self, $href, $ltxt) = @_;
  $href =~ s/^\s*\"//; $href =~ s/\"\s*$//;
  my $thisl;

  if (defined $self->{href2label}->{$href}) {
    $thisl = $self->{thislink} = $self->{href2label}->{$href};
  } else {
    $thisl = $self->{thislink} = $self->{linknum}++;
    $self->{links}->{$thisl} = $href;
    $self->{href2label}->{$href} = $thisl;
    $self->{linkdict}->{$thisl} = $self->{text_link_indent}."[$thisl]: $href\n";
  }

  $self->{html_link_open}.$ltxt." [$thisl".$self->{html_link_close};
}

###########################################################################

sub protect_html {
  local ($_) = shift;
  s/ /\016\001/gs;
  s/\t/\016\002/gs;
  s/</\016\003/gs;
  s/>/\016\004/gs;
  s/\&/\016\005/gs;
  s/\"/\016\006/gs;
  s/\'/\016\007/gs;
  s/\//\016\010/gs;
  s/\n/\016\017/gs;
  $_;
}

###########################################################################

sub unprotect_html {
  local ($_) = shift;
  s/\016\001/ /gs;
  s/\016\002/\t/gs;
  s/\016\003/</gs;
  s/\016\004/>/gs;
  s/\016\005/\&/gs;
  s/\016\006/\"/gs;
  s/\016\007/\'/gs;
  s/\016\010/\//gs;
  s/\016\017/\n/gs;
  $_;
}

###########################################################################

sub html2text_list {
  my ($listtag, $str, $bullet) = @_;

  $str =~ s/<\/li>\s*/\n\n/gis;
  $str =~ s/<li>\s*/\n\n${bullet} /gis;
  $str =~ s/^/    /gm;
  "\n\n$str\n\n";
}

###########################################################################

1;

__END__

=back

=head1 MORE DOCUMENTATION

See also http://webmake.taint.org/ for more information.

=head1 SEE ALSO

C<webmake>
C<ettext2html>
C<ethtml2text>
C<HTML::WebMake>
C<Text::EtText::EtText2HTML>
C<Text::EtText::HTML2EtText>

=head1 AUTHOR

Justin Mason E<lt>jm /at/ jmason.orgE<gt>

=head1 COPYRIGHT

WebMake is distributed under the terms of the GNU Public License.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN
as well as:

  http://webmake.taint.org/

=cut

