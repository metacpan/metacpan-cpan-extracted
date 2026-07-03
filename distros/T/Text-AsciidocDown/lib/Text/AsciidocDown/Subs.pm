package Text::AsciidocDown::Subs;

use strict;
use warnings;

our $VERSION = '0.1.0';

my $ATTR_REF_RX = qr/(\\)?\{([a-z0-9_][a-z0-9_-]*)\}/i;
my $INLINE_ANCHOR_RX = qr/\[\[([A-Za-z_][A-Za-z0-9_\-:.]*)\]\]/;
my $INLINE_IMG_RX = qr/image:([^\s:`[\\][^[\\]*)\[(|.*?[^\\])\]/;
my $XREF_SHORT_RX = qr/<<([^\s,>][^,>]*)(?:, ?([^>]+))?>>/;
my $BOLD_RX = qr/(?<![A-Za-z0-9_\\])\*(\S(?:.*?\S)?)\*(?![A-Za-z0-9_])/;
my $EMPH_RX = qr/(?<![A-Za-z0-9_\\])_(\S(?:.*?\S)?)_(?![A-Za-z0-9_])/;
my $MARK_RX = qr/(?<![A-Za-z0-9_\\])#(\S(?:.*?\S)?)#(?![A-Za-z0-9_])/;
my $STRIKE_MARK_RX = qr/(?<![A-Za-z0-9_\\])\[\.line-through\]#(\S(?:.*?\S)?)#(?![A-Za-z0-9_])/;
my $MONO_PASSTHRU_RX = qr/`\+(.*?)\+`/;
my $MONO_RX = qr/`(\S(?:.*?\S)?)`/;

sub build_attributes {
  my ($runtime) = @_;

  my %attrs = (
    empty => '',
    idprefix => '_',
    idseparator => '_',
    'markdown-line-break' => '\\',
    'markdown-strikethrough' => '~~',
    nbsp => '&#160;',
    quotes => '<q> </q>',
    sp => ' ',
    vbar => '|',
    zwsp => '&#8203;',
  );

  if (ref($runtime) eq 'HASH') {
    for my $k (keys %{$runtime}) {
      $attrs{$k} = $runtime->{$k};
    }
  }

  return \%attrs;
}

sub substitute_attributes {
  my ($text, $attrs) = @_;
  return '' unless defined $text;
  return $text unless ref($attrs) eq 'HASH';

  return $text =~ /\{/ ? $text =~ s/$ATTR_REF_RX/_replace_attr_ref($1, $2, $attrs)/gier : $text;
}

sub apply_normal_subs {
  my ($text, $attrs) = @_;
  return '' unless defined $text;

  # Order mirrors a pragmatic flow similar to downdoc:
  # escape-sensitive quote/format handling first, then attrs/macros.
  $text = escape_lt_outside_monospace($text);
  $text = apply_quotes($text, $attrs);
  $text = apply_inline_formatting($text, $attrs);
  $text = substitute_attributes($text, $attrs);
  $text = apply_macros($text, $attrs);
  $text = apply_curly_apostrophe($text);

  return $text;
}

sub apply_inline_formatting {
  my ($text, $attrs) = @_;
  return '' unless defined $text;

  my @mono;
  $text =~ s/$MONO_PASSTHRU_RX/_stash_mono(\@mono, $1)/ge;
  $text =~ s/$MONO_RX/_stash_mono(\@mono, $1)/ge;

  $text =~ s/$STRIKE_MARK_RX/_strikethrough($1, $attrs)/ge;
  $text =~ s/$MARK_RX/<mark>$1<\/mark>/g;
  $text =~ s/$BOLD_RX/*$1*/g;
  $text =~ s/$EMPH_RX/_$1_/g;

  $text =~ s/\x{1F}MONO(\d+)\x{1E}/'`' . $mono[$1] . '`'/ge;
  return $text;
}

sub apply_quotes {
  my ($text, $attrs) = @_;
  return '' unless defined $text;
  return $text unless defined($attrs) && ref($attrs) eq 'HASH';

  my ($q_open, $q_close) = _quote_pair($attrs->{quotes});

  # AsciiDoc quote syntax in this phase: "`text`" and '`text`'
  $text =~ s/"`(.*?)`"/$q_open$1$q_close/g;
  $text =~ s/'`(.*?)`'/$q_open$1$q_close/g;
  return $text;
}

sub apply_macros {
  my ($text, $attrs) = @_;
  return '' unless defined $text;

  $text = _apply_inline_anchor($text) if index($text, '[[') >= 0;
  $text = _apply_images($text, $attrs) if index($text, 'image:') >= 0;
  $text = _apply_links($text, $attrs) if index($text, 'http://') >= 0 || index($text, 'https://') >= 0 || index($text, 'link:') >= 0;
  $text = _apply_xrefs($text) if index($text, 'xref:') >= 0 || index($text, '<<') >= 0;
  return $text;
}

sub block_image_to_markdown {
  my ($line, $attrs) = @_;
  return undef unless defined $line;
  return undef unless $line =~ /^image::([^\s[][^[]*)\[(.*)\]$/;

  my ($target, $attrlist) = ($1, $2);
  $target = substitute_attributes($target, $attrs);
  return image_to_markdown($target, $attrlist, $attrs);
}

sub image_to_markdown {
  my ($target, $attrlist, $attrs) = @_;
  $target = '' unless defined $target;
  $attrlist = '' unless defined $attrlist;

  my $alt = '';
  if (length $attrlist) {
    ($alt) = split /,/, $attrlist, 2;
  }
  if (!defined($alt) || $alt eq '') {
    my $base = $target;
    $base =~ s{.*/}{};
    $base =~ s{\.[^.]+$}{};
    $alt = $base;
  }

  if (ref($attrs) eq 'HASH' && defined $attrs->{imagesdir} && $attrs->{imagesdir} ne '' && $target !~ m{^(?:https?://|/)}) {
    $target = $attrs->{imagesdir} . '/' . $target;
  }

  return '![' . $alt . '](' . $target . ')';
}

sub escape_lt_outside_monospace {
  my ($text) = @_;
  return '' unless defined $text;

  my @mono;
  $text =~ s/$MONO_PASSTHRU_RX/_stash_mono(\@mono, $1)/ge;
  $text =~ s/$MONO_RX/_stash_mono(\@mono, $1)/ge;

  # Preserve xref shorthand delimiters while escaping normal less-than signs.
  $text =~ s/<</\x{1F}XREFL\x{1E}/g;
  $text =~ s/>>/\x{1F}XREFR\x{1E}/g;
  $text =~ s/</&lt;/g;
  $text =~ s/\x{1F}XREFL\x{1E}/<</g;
  $text =~ s/\x{1F}XREFR\x{1E}/>>/g;

  $text =~ s/\x{1F}MONO(\d+)\x{1E}/'`' . $mono[$1] . '`'/ge;
  return $text;
}

sub apply_curly_apostrophe {
  my ($text) = @_;
  return '' unless defined $text;

  return $text =~ s/(?<=[A-Za-z0-9])'(?=[A-Za-z])/"\x{2019}"/ger;
}

sub _replace_attr_ref {
  my ($escaped, $name, $attrs) = @_;
  return '{' . $name . '}' if $escaped;
  return exists $attrs->{$name} ? _stringify($attrs->{$name}) : '{' . $name . '}';
}

sub _apply_inline_anchor {
  my ($text) = @_;
  return $text =~ s{$INLINE_ANCHOR_RX}{'<a name="' . $1 . '"></a>'}ger;
}

sub _apply_images {
  my ($text, $attrs) = @_;
  $text =~ s{$INLINE_IMG_RX}{image_to_markdown($1, $2, $attrs)}ge;
  return $text;
}

sub _apply_links {
  my ($text, $attrs) = @_;

  # link:target[text]
  $text =~ s{(?<!\\)link:([^\s\[]+)\[(.*?)\]}{_rewrite_link_macro($1, $2, $attrs)}ge;

  # URL macro https://target[text]
  $text =~ s{(?<!\\)(https?://[^\s\[]+)\[(.*?)\]}{_rewrite_url_macro($1, $2, $attrs)}ge;

  # Bare URL
  $text =~ s{(?<![\\\w/])(https?://[^\s\])]+)}{_rewrite_bare_url($1, $attrs)}ge;

  # Escaped URL macro/bare URL handling.
  $text =~ s{\\(https?://)([^\s\]]+)}{'<span>' . $1 . '</span>' . $2}ge;
  $text =~ s{\\link:([^\s\[]+)\[(.*?)\]}{'link:' . $1 . '[' . $2 . ']'}ge;

  return $text;
}

sub _apply_xrefs {
  my ($text) = @_;

  $text =~ s{(?<!\\)xref:([^\[]+)\[(.*?)\]}{_rewrite_xref_macro($1, $2)}ge;
  $text =~ s{$XREF_SHORT_RX}{_rewrite_xref_short($1, $2)}ge;
  return $text;
}

sub _rewrite_xref_macro {
  my ($target, $text) = @_;
  $target =~ s/^\s+|\s+$//g;
  my $label = (defined($text) && $text ne '') ? $text : $target;

  if ($target =~ /^#(.+)$/) {
    my $id = $1;
    return 'xref:#' . $id . '[' . (defined($text) ? $text : '') . ']' if $id =~ /\s/;
    return '[' . (($label ne '#'.$id) ? $label : $id) . '](#!' . $id . ')';
  }

  if ($target =~ /\.adoc#(.+)/) {
    my $frag = $1;
    return 'xref:' . $target . '[' . (defined($text) ? $text : '') . ']' if $frag =~ /\s/;
  }

  # Natural/internal xref target: defer resolution to parser post-pass.
  if ($target !~ m{^(?:https?://|/)} && $target !~ /\.adoc(?:#.*)?$/) {
    return '[' . $label . '](#!' . $target . ')';
  }

  # External/interdocument fallback.
  $target =~ s/#$//;
  return '[' . ($label ne '' ? $label : $target) . '](' . $target . ')';
}

sub _rewrite_xref_short {
  my ($id, $text) = @_;
  return '<<' . $id . (defined($text) ? ', ' . $text : '') . '>>' if $id =~ /\s/;
  return '[' . (defined($text) && $text ne '' ? $text : $id) . '](#!' . $id . ')';
}

sub _hide_uri_scheme {
  my ($attrs) = @_;
  return ref($attrs) eq 'HASH' && exists $attrs->{'hide-uri-scheme'};
}

sub _rewrite_link_macro {
  my ($target, $text, $attrs) = @_;
  return 'link:' . $target . '[' . $text . ']' if $target =~ /\s/;
  my $label = (defined($text) && $text ne '') ? $text : $target;
  return '[' . $label . '](' . $target . ')';
}

sub _rewrite_url_macro {
  my ($url, $text, $attrs) = @_;
  my $label;
  if (defined($text) && $text ne '') {
    $label = $text;
  } elsif (_hide_uri_scheme($attrs)) {
    ($label = $url) =~ s{^https?://}{};
  } else {
    $label = $url;
  }
  return '[' . $label . '](' . $url . ')';
}

sub _rewrite_bare_url {
  my ($url, $attrs) = @_;
  return $url unless _hide_uri_scheme($attrs);
  (my $label = $url) =~ s{^https?://}{};
  return '[' . $label . '](' . $url . ')';
}

sub _quote_pair {
  my ($quotes) = @_;
  $quotes = '<q> </q>' unless defined $quotes && length $quotes;
  my @parts = split /\s+/, $quotes;
  my ($open, $close) = @parts >= 2 ? @parts[0, 1] : ('<q>', '</q>');
  return ($open, $close);
}

sub _strikethrough {
  my ($text, $attrs) = @_;
  my $mark = ref($attrs) eq 'HASH' && defined($attrs->{'markdown-strikethrough'})
    ? $attrs->{'markdown-strikethrough'}
    : '~~';

  my @parts = split /\s+/, $mark;
  my ($open, $close) = @parts >= 2 ? @parts[0, 1] : ($mark, $mark);
  return $open . $text . $close;
}

sub _stash_mono {
  my ($stash, $content) = @_;
  push @{$stash}, $content;
  return "\x{1F}MONO" . ($#{$stash}) . "\x{1E}";
}

sub _stringify {
  my ($value) = @_;
  return '' unless defined $value;
  return "$value";
}

1;

__END__

=head1 NAME

Text::AsciidocDown::Subs - Attribute substitution and inline formatting

=head1 SYNOPSIS

  use Text::AsciidocDown::Subs;

  my $attrs = Text::AsciidocDown::Subs::build_attributes(\%runtime);
  my $text  = Text::AsciidocDown::Subs::apply_normal_subs($input, $attrs);

=head1 DESCRIPTION

This module provides attribute building, attribute reference substitution,
and inline formatting/macro expansion for Text::AsciidocDown. It is not
intended for direct use; callers should use the OO interface provided by
L<Text::AsciidocDown>.

=head1 INTERFACE

=head2 build_attributes

  my $attrs = Text::AsciidocDown::Subs::build_attributes(\%runtime);

Builds a complete attribute hash from runtime attributes, adding built-in
defaults (C<empty>, C<idprefix>, C<idseparator>, C<nbsp>, C<quotes>,
C<sp>, C<vbar>, C<zwsp>, and Markdown-specific attributes).

=head2 substitute_attributes

  my $text = Text::AsciidocDown::Subs::substitute_attributes($text, $attrs);

Substitutes C<{name}> attribute references in the text with their values.

=head2 apply_normal_subs

  my $text = Text::AsciidocDown::Subs::apply_normal_subs($text, $attrs);

Applies the full normal substitution chain:

=over 4

=item * Escape C<E<lt>> outside monospace

=item * Apply AsciiDoc quotes (C<"`text`">)

=item * Inline formatting (bold, emphasis, monospace, mark, strikethrough)

=item * Attribute substitution

=item * Macros (anchors, images, links, xrefs)

=item * Curly apostrophe conversion

=back

=head2 block_image_to_markdown

  my $md = Text::AsciidocDown::Subs::block_image_to_markdown($line, $attrs);

Converts a block image macro (C<image::[]>) to Markdown if the line matches.

=head2 image_to_markdown

  my $md = Text::AsciidocDown::Subs::image_to_markdown($target, $attrlist, $attrs);

Converts an image macro to Markdown C<![]()> syntax.

=head2 escape_lt_outside_monospace

  my $text = Text::AsciidocDown::Subs::escape_lt_outside_monospace($text);

Escapes angle brackets to HTML entities while preserving xref shortcuts.

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

Same terms as Perl itself.

=cut