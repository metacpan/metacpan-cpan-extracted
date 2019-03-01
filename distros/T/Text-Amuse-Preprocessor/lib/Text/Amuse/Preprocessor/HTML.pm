package Text::Amuse::Preprocessor::HTML;

use strict;
use warnings;
use utf8;
# use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw( html_to_muse html_file_to_muse );

our $VERSION = '0.59';

=encoding utf8

=head1 NAME

Text::Amuse::Preprocessor::HTML - HTML importer

=head1 DESCRIPTION

This module tries its best to convert the HTML into an acceptable
Muse string. It's not perfect, though, and some manual adjustment is
needed if there are tables or complicated structures.

=head1 SYNOPSIS

  use utf8;
  use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
  my $html = '<p>Your text here... &amp; &quot; &ograve; àùć</p>'
  my $muse = html_to_muse($html);

=cut

use IO::HTML qw/html_file/;
use HTML::PullParser;

my %preserved = (
		 "em" => [["<em>"], ["</em>"]],
		 "i"  => [["<em>"], ["</em>"]],
		 "u"  => [["<em>"], ["</em>"]],
		 "strong" => [["<strong>"], ["</strong>"]],
		 "b"      => [["<strong>"], ["</strong>"]],
		 "blockquote" => ["\n<quote>\n", "\n</quote>"],
		 "ol" => ["\n\n", "\n\n"],
		 "ul" => ["\n\n", "\n\n"],
		 "li" => { ol => [ " 1. ", "\n\n"],
			   ul => [ " - ", "\n\n"],
			 },
		 "code" => [["<code>"], ["</code>"]],
		 "a" => [[ "[[" ] , [ "]]" ]],
		 "pre" => [ "\n<example>\n", "\n</example>\n" ],
		 table => ["\n\n", "\n\n"],
		 "tr" => ["\n ", "" ],
		 "td" => [[" "], [" | "] ],
		 "th" => [[ " "], [" || "] ],
		 "dd" => ["\n\n", "\n\n"],
		 "dt" => ["\n***** ", "\n\n" ],
		 "h1" => ["\n* ", "\n\n"],
		 "h2" => ["\n* ", "\n\n"],
		 "h3" => ["\n** ", "\n\n"],
		 "h4" => ["\n*** ", "\n\n"],
		 "h5" => ["\n**** ", "\n\n"],
		 "h6" => ["\n***** ", "\n\n"],
		 "sup" => [["<sup>"], ["</sup>"]],
		 "sub" => [["<sub>"], ["</sub>"]],
		 "strike" => [["<del>"], ["</del>"]],
		 "del" => [["<del>"], ["</del>"]],
		 "p" => ["\n\n", "\n\n"],
		 "br" => ["\n<br>", "\n"],
		 "div" => ["\n\n", "\n\n"],
		 "center" => ["\n\n<center>\n", "\n</center>\n\n"],
		 "right"  => ["\n\n<right>\n", "\n</right>\n\n"],
		 
);

=head1 FUNCTIONS

=head2 html_to_muse($html_decoded_text)

The first argument must be a decoded string with the HTML text.
Returns the L<Text::Amuse> formatted body.

=head2 html_file_to_muse($html_file)

The first argument must be a filename.

=cut

sub html_to_muse {
  my ($rawtext) = @_;
  return unless defined $rawtext;
  # pack the things like hello<em> there</em> with space. Be careful
  # with recursions.
  return _html_to_muse(\$rawtext);
}

sub html_file_to_muse {
  my ($text) = @_;
  die "$text is not a file" unless (-f $text);
  return _html_to_muse(html_file($text));
}

sub _html_to_muse {
  my $text = shift;
  my %opts = (
              start => '"S", tagname, attr',
              end   => '"E", tagname',
              text => '"T", dtext',
              empty_element_tags => 1,
              marked_sections => 1,
              unbroken_text => 1,
              ignore_elements => [qw(script style)],
             );
  if (ref($text) eq 'SCALAR') {
    $opts{doc} = $text;
  }
  elsif (ref($text) eq 'GLOB') {
    $opts{file} = $text;
  }
  else {
    die "Nor a ref, nor a file!";
  }

  my $p = HTML::PullParser->new(%opts) or die $!;
  my @textstack;
  my @spanpile;
  my @lists;
  my @parspile;
  my @tagpile = ('root');
  my $current = '';
  while (my $token = $p->get_token) {
    my $type = shift @$token;
    # starttag?
    if ($type eq 'S') {
      my $tag = shift @$token;
      push @tagpile, $tag;
      $current = $tag;
      my $attr = shift @$token;
      # see if processing of span or font are needed
      if (($tag eq 'span') or ($tag eq 'font')) {
	$tag = _span_process_attr($attr);
	push @spanpile, $tag;
      }
      elsif (($tag eq "ol") or ($tag eq "ul")) {
	push @lists, $tag;
      }
      elsif (($tag eq 'p') or ($tag eq 'div')) {
	$tag = _pars_process_attr($tag, $attr);
	push @parspile, $tag;
      }
      # see if we want to skip it.
      if ((defined $tag) && (exists $preserved{$tag})) {

	# is it a list?
	if (ref($preserved{$tag}) eq "HASH") {
	  # does it have a parent?
	  if (my $parent = $lists[$#lists]) {
	    push @textstack, "\n",
	      "    " x $#lists,
		$preserved{$tag}{$parent}[0];
	  } else {
	    push @textstack, "\n",
	      $preserved{$tag}{ul}[0];
	  }
	}
	# no? ok
	else {
	  push @textstack, $preserved{$tag}[0];
	}
      }
      if ((defined $tag) &&
	  ($tag eq 'a') &&
	  (my $href =  $attr->{href})) {
	push @textstack, [ $href, "][" ];
      }
    }

    # stoptag?
    elsif ($type eq 'E') {
      $current = '';
      my $tag = shift @$token;
      my $expected = pop @tagpile;
      if ($expected ne $tag) {
        warn "tagpile mismatch: $expected, $tag\n";
      }

      if (($tag eq 'span') or ($tag eq 'font')) {
	$tag = pop @spanpile;
      }
      elsif (($tag eq "ol") or ($tag eq "ul")) {
	$tag = pop @lists;
      }
      elsif (($tag eq 'p') or ($tag eq 'div')) {
	if (@parspile) {
	  $tag = pop @parspile
	}
      }

      if ($tag && (exists $preserved{$tag})) {
	if (ref($preserved{$tag}) eq "HASH") {
	  if (my $parent = $lists[$#lists]) {
	    push @textstack, $preserved{$tag}{$parent}[1];
	  } else {
	    push @textstack, $preserved{$tag}{ul}[1];
	  }
	} else {
	  push @textstack, $preserved{$tag}[1];
	}
      }
    }
    # regular text
    elsif ($type eq 'T') {
      my $line = shift @$token;
      # Word &C. (and CKeditor), love the no-break space.
      # but preserve it it's only whitespace in the line.
      $line =~ s/\r//gs;
      $line =~ s/\t/    /gs;
      # at the beginning of the tag
      if ($current =~ m/^(p|div)$/) {
        if ($line =~ m/\A\s*([\x{a0} ]+)\s*\z/) {
          $line = "\n<br>\n";
        }
      }
      $line =~ s/\x{a0}/ /gs;
      # remove leading spaces from these tags
      if ($current =~ m/^(h[1-6]|li|ul|ol|p|div)$/) {
        $line =~ s/^\s+//gms;
      }
      if ($current ne 'pre') {
        push @textstack, [ $line ];
      }
      else {
        push @textstack, $line;
      }
    } else {
      warn "which type? $type??\n"
    }
  }
  my @current_text;
  my @processed;
  while (@textstack) {
    my $text = shift(@textstack);
    if (ref($text)) {
      push @current_text, @$text;
    }
    else {
      push @processed, _merge_text_lines(\@current_text);
      push @processed, $text;
    }
  }
  push @processed, _merge_text_lines(\@current_text);
  my $full = join("", @processed);
  $full =~ s/\n\n\n+/\n\n/gs;
  return $full;
}

sub _cleanup_text_block {
  my $parsed = shift;
  return '' unless defined $parsed;
  # here we are inside a single text block.
  $parsed =~ s/\s+/ /gs;
  # print "<<<$parsed>>>\n";
  # clean the footnotes.
  $parsed =~ s!\[
	       \[
	       \#\w+ # the anchor
	       \]
	       \[
	       (<(sup|strong|em)>|\[)? # sup or [ 
	       \[*
	       (\d+) # the number
	       \]*
	       (</(sup|strong|em)>|\])? # sup or ]
	       \] # close 
	       \] # close
	      ![$3]!gx;

  # add a newline if missing
#  unless ($parsed =~ m/\n\z/) {
#    $parsed .= "\n";
#  }
  my $recursion = 0;
  while (($parsed =~ m!( </|<[^/]+?> )!) && ($recursion < 20)) {
    $parsed =~ s!( +)(</.*?>)!$2$1!g;
    $parsed =~ s!(<[^/]*?>)( +)!$2$1!g;
    $recursion++;
  }
  # empty links artifacts.
  $parsed =~ s/\[\[\]\]//g;
  $parsed =~ s/\s+/ /gs;
  $parsed =~ s/\A\s+//;
  $parsed =~ s/\s+\z//;
  $parsed =~ s/^\*/ */gm;
  # print ">>>$parsed<<<\n";
  return $parsed;
}

sub _span_process_attr {
  my $attr = shift;
  my $tag;
  my @attrsvalues = values %$attr;
  if (grep(/italic/i, @attrsvalues)) {
    $tag = "em";
  }
  elsif (grep(/bold/i, @attrsvalues)) {
    $tag = "strong";
  }
  else {
    $tag = undef;
  }
  return $tag;
}

sub _pars_process_attr {
  my ($tag, $attr) = @_;
  # warn Dumper($attr);
  if (my $style = $attr->{style}) {
    if ($style =~ m/text-align:\s*center/i) {
      $tag = 'center';
    }
    if ($style =~ m/text-align:\s*right/i) {
      $tag = 'right';
    }
    if ($style =~ m/padding-left:\s*\d/si) {
      $tag = 'blockquote'
    }
  }
  if (my $align = $attr->{align}) {
    if ($align =~ m/center/i) {
      $tag = 'center';
    }
    if ($align =~ m/right/i) {
      $tag = 'right';
    }
  }
  return $tag;
}

sub _merge_text_lines {
  my $lines = shift;
  return '' unless @$lines;
  my $text = join ('', @$lines);
  @$lines = ();
  return _cleanup_text_block($text);
}

1;


=head1 AUTHOR, LICENSE, ETC.,

See L<Text::Amuse::Preprocessor>

=cut

# Local Variables:
# tab-width: 8
# cperl-indent-level: 2
# End:
