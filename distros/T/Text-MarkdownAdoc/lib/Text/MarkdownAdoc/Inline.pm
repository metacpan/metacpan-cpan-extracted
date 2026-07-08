package Text::MarkdownAdoc::Inline;

use 5.016;
use strict;
use warnings;

#===========================================================================
# Inline formatting processor
#===========================================================================

sub new
{
   my ($class, %opts) = @_;

   my $self = {
               options  => {%opts},
               has_math => 0,
               };

   bless $self, $class;
   return $self;
}

sub process
{
   my ($self, $text) = @_;

   my $input = $text // '';
   return '' if $input eq '';

   # Processing order:
   # 1. Handle backslash escapes (protect escaped chars BEFORE code spans)
   # 2. Extract code spans (protect from further processing)
   # 3. Inline math $...$ (after code spans so $ in code is safe)
   # 4. Inline links (must come before reference-style; exclude image prefix)
   # 5. Footnotes → placeholders (must come BEFORE reference-style links
   #    because [^label] would otherwise be consumed by the [ref] shorthand regex)
   # 6. Reference-style links → placeholders
   # 7. Images (protect [alt] from reference link processing)
   # 8. Autolinks
   # 9. Bold, strikethrough → placeholders
   # 10. Italic (process inside placeholders, then main text)
   # 11. Resolve bold/strikethrough placeholders (AFTER italic)
   # 12. HTML entities
   # 13. Inline HTML
   # 14. Smart quotes
   # 15. Typographic symbols (em dash, ellipsis)
   # 16. Clean up PROT markers
   # 17. Restore code spans and protected content

   my @protected;
   $input = _protect_escapes($input, \@protected);

   my @code_spans;
   $input = _extract_code_spans($input, \@code_spans);

   $input = _convert_inline_links($input);
   $input = _convert_footnotes($input);
   $input = _convert_reference_links($input);
   $input = _convert_inline_math($input, $self);
   $input = _convert_images($input);
   $input = _convert_autolinks($input);
   $input = _convert_bold_and_strikethrough($input);
   $input = _convert_italic($input);
   $input = _resolve_bold_and_strikethrough($input);
   $input = _convert_html_entities($input);
   $input = _convert_inline_html($input);
   $input = _convert_smart_quotes($input);
   $input = _convert_typographic_symbols($input);

   $input = _cleanup_prot($input);
   $input = _restore_protected($input, \@protected);
   $input = _restore_code_spans($input, \@code_spans);

   return $input;
}

#===========================================================================
# Backslash escapes — protect from further processing (BEFORE code spans)
#===========================================================================

sub _protect_escapes
{
   my ($text, $stash) = @_;

   # Protect backslash-escaped punctuation characters
   $text =~ s{\\([!"#\$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~])}{
        push @$stash, $1;
        "\x01ESC" . ($#$stash) . "\x01";
    }eg;

   return $text;
}

sub _restore_protected
{
   my ($text, $stash) = @_;

   $text =~ s{\x01ESC(\d+)\x01}{
        my $idx = $1;
        $stash->[$idx];
    }eg;

   return $text;
}

#===========================================================================
# Code span extraction (AFTER escapes)
#===========================================================================

sub _extract_code_spans
{
   my ($text, $stash) = @_;

   $text =~ s{
        (`{1,})          # opening backticks (capture count)
        (.+?)            # code content (non-greedy)
        \1               # closing backticks (same count)
    }{
        my $code = $2;
        push @$stash, $code;
        "\x01CODE" . ($#$stash) . "\x01";
    }xesg;

   return $text;
}

sub _restore_code_spans
{
   my ($text, $stash) = @_;

   $text =~ s{\x01CODE(\d+)\x01}{
        my $idx = $1;
        '`' . $stash->[$idx] . '`';
    }eg;

   return $text;
}

#===========================================================================
# Inline links — must process BEFORE reference-style links
#===========================================================================

sub _convert_inline_links
{
   my ($text) = @_;

   # Match [text](url) or [text](url "title")
   # Must NOT be preceded by ! (image syntax)
   $text =~ s{
        (?<!\!)               # not an image
        \[
        ( (?:\\.|[^\]])*? )   # link text (allow escaped ])
        \]
        \(
        [ \t]*
        ( [^)\s]+ )           # URL (no spaces)
        (?: [ \t]+ "([^"]*)" )?  # optional title
        [ \t]*
        \)
    }{
        my $link_text = $1;
        my $url       = $2;

        # Unescape brackets in link text
        $link_text =~ s/\\\[/[/g;
        $link_text =~ s/\\\]/]/g;

        _format_link($link_text, $url);
    }xeg;

   return $text;
}

sub _format_link
{
   my ($text, $url) = @_;

   # Anchor link: [text](#anchor) → deferred xref placeholder
   if ($url =~ m/^#(.+)/)
   {
      my $anchor = $1;
      return "\x00XREF:$anchor:$text\x00";
   }

   # .md file → .adoc xref
   if ($url =~ m/^(.+)\.md$/i)
   {
      my $base = $1;
      return "xref:$base.adoc\x01PROT$text\x01PROT";
   }

   # URL-only link where text equals URL → bare URL
   if ($text eq $url)
   {
      return $url;
   }

   # Standard link: [text](url) → url[text]
   return "$url\x01PROT$text\x01PROT";
}

#===========================================================================
# Reference-style links → placeholders
#===========================================================================

sub _convert_reference_links
{
   my ($text) = @_;

   # [text][ref] → placeholder
   $text =~ s{
        \[
        ( (?:\\.|[^\]])*? )   # link text
        \]
        \[
        ( [^\]]*? )           # reference label (may be empty)
        \]
    }{
        my $link_text = $1;
        my $ref_label = $2;

        $link_text =~ s/\\\[/[/g;
        $link_text =~ s/\\\]/]/g;

        if ($ref_label eq '') {
            $ref_label = $link_text;
        }

        my $normalized = lc($ref_label);
        $normalized =~ s/\s+/ /g;
        $normalized =~ s/^\s+|\s+$//g;

        "\x00REFLINK:$normalized:$link_text\x00";
    }xeg;

   # [ref] (shorthand, but NOT followed by '(' which would be an inline link)
   $text =~ s{
        (?<!\!)               # not an image
        \[
        ( [^\[\]\(]+? )       # reference label (no brackets or parens)
        \]
        (?!\()                # NOT followed by '(' (inline link)
    }{
        my $ref_label = $1;

        my $normalized = lc($ref_label);
        $normalized =~ s/\s+/ /g;
        $normalized =~ s/^\s+|\s+$//g;

        "\x00REFLINK:$normalized:$ref_label\x00";
    }xeg;

   return $text;
}

#===========================================================================
# Inline images — protect [alt] from reference link processing
#===========================================================================

sub _convert_images
{
   my ($text) = @_;

   # Reference-style images: ![alt][ref]
   $text =~ s{
        !\[
        ( (?:\\.|[^\]])*? )   # alt text
        \]
        \[
        ( [^\]]*? )           # reference label
        \]
    }{
        my $alt  = $1;
        my $label = $2;

        $alt =~ s/\\\[/[/g;
        $alt =~ s/\\\]/]/g;

        if ($label eq '') {
            $label = $alt;
        }

        my $normalized = lc($label);
        $normalized =~ s/\s+/ /g;
        $normalized =~ s/^\s+|\s+$//g;

        "\x00REFIMG:$normalized:$alt\x00";
    }xeg;

   # Inline images: ![alt](src) or ![alt](src "title")
   $text =~ s{
        !\[
        ( (?:\\.|[^\]])*? )   # alt text
        \]
        \(
        [ \t]*
        ( [^)\s]+ )           # URL
        (?: [ \t]+ "([^"]*)" )?  # optional title
        [ \t]*
        \)
    }{
        my $alt = $1;
        my $src = $2;

        $alt =~ s/\\\[/[/g;
        $alt =~ s/\\\]/]/g;

        # Protect the [alt] part from reference link processing
        "image:$src\x01PROT$alt\x01PROT";
    }xeg;

   return $text;
}

#===========================================================================
# Footnotes → placeholders for deferred resolution in Refs.pm
#===========================================================================

sub _convert_footnotes
{
   my ($text) = @_;

   # [^label] → \x00FOOTNOTE:label\x00
   $text =~ s{\[\^([^\]]+)\]}{
        my $label = $1;
        "\x00FOOTNOTE:$label\x00";
    }xeg;

   return $text;
}

#===========================================================================
# Autolinks
#===========================================================================

sub _convert_autolinks
{
   my ($text) = @_;

   # <url> → bare URL
   $text =~ s{<([a-zA-Z][a-zA-Z0-9+.-]*://[^>\s]+)>}{$1}g;

   return $text;
}

#===========================================================================
# Bold and strikethrough → placeholders
#===========================================================================

sub _convert_bold_and_strikethrough
{
   my ($text) = @_;

   # **bold** → placeholder
   $text =~ s{\*\*(.+?)\*\*}{
        "\x01BOLD$1\x01";
    }xeg;

   # __bold__ → placeholder
   $text =~ s{__(.+?)__}{
        "\x01BOLD$1\x01";
    }xeg;

   # ~~strikethrough~~ → placeholder
   $text =~ s{~~(.+?)~~}{
        "\x01STRIKE$1\x01";
    }xeg;

   return $text;
}

#===========================================================================
# Italic (process inside placeholders, then main text)
#===========================================================================

sub _convert_italic
{
   my ($text) = @_;

   # Process italic inside bold/strikethrough placeholders
   $text =~ s{\x01BOLD(.+?)\x01}{
        my $inner = $1;
        $inner = _apply_italic($inner);
        "\x01BOLD$inner\x01";
    }xeg;

   $text =~ s{\x01STRIKE(.+?)\x01}{
        my $inner = $1;
        $inner = _apply_italic($inner);
        "\x01STRIKE$inner\x01";
    }xeg;

   # Process italic in the main text
   $text = _apply_italic($text);

   return $text;
}

sub _apply_italic
{
   my ($text) = @_;

   # *italic* → _text_ (must be bounded by non-word chars)
   $text =~ s{(?<!\w)\*(.+?)\*(?!\w)}{
        "_$1_";
    }xeg;

   # _italic_ → _text_ (must be bounded by non-word chars)
   $text =~ s{(?<!\w)_(.+?)_(?!\w)}{
        "_$1_";
    }xeg;

   return $text;
}

#===========================================================================
# Resolve bold/strikethrough placeholders (AFTER italic processing)
#===========================================================================

sub _resolve_bold_and_strikethrough
{
   my ($text) = @_;

   $text =~ s{\x01BOLD(.+?)\x01}{*$1*}g;
   $text =~ s{\x01STRIKE(.+?)\x01}{[.line-through]#$1#}g;

   return $text;
}

#===========================================================================
# Clean up PROT markers → [...]
#===========================================================================

sub _cleanup_prot
{
   my ($text) = @_;

   $text =~ s{\x01PROT([^\x01]*)\x01PROT}{[$1]}g;

   return $text;
}

#===========================================================================
# HTML entities
#===========================================================================

sub _convert_html_entities
{
   my ($text) = @_;

   # &nbsp; → {nbsp}
   $text =~ s/&nbsp;/\{nbsp\}/gi;

   return $text;
}

#===========================================================================
# Inline HTML
#===========================================================================

sub _convert_inline_html
{
   my ($text) = @_;

   # <br> or <br/> → hard line break
   $text =~ s{<br\s*/?>}{ +}gi;

   # <strong>text</strong> → *text*
   $text =~ s{<strong>(.+?)</strong>}{*$1*}gi;

   # <b>text</b> → *text*
   $text =~ s{<b>(.+?)</b>}{*$1*}gi;

   # <em>text</em> → _text_
   $text =~ s{<em>(.+?)</em>}{_$1_}gi;

   # <i>text</i> → _text_
   $text =~ s{<i>(.+?)</i>}{_$1_}gi;

   # <code>text</code> → `text`
   $text =~ s{<code>(.+?)</code>}{`$1`}gi;

   # <del>text</del> → [.line-through]#text#
   $text =~ s{<del>(.+?)</del>}{[.line-through]#$1#}gi;

   # <s>text</s> → [.line-through]#text#
   $text =~ s{<s>(.+?)</s>}{[.line-through]#$1#}gi;

   # <mark>text</mark> → #text#
   $text =~ s{<mark>(.+?)</mark>}{#$1#}gi;

   # <sup>text</sup> → ^text^
   $text =~ s{<sup>(.+?)</sup>}{^$1^}gi;

   # <sub>text</sub> → ~text~
   $text =~ s{<sub>(.+?)</sub>}{~$1~}gi;

   # Unknown inline tags: pass through as +++<tag>+++content+++</tag>+++
   $text =~ s{<(/?)([a-zA-Z][a-zA-Z0-9]*)(\s[^>]*)?>}{
        my $slash = $1;
        my $tag   = $2;
        "+++<$slash$tag>+++";
    }xeg;

   return $text;
}

#===========================================================================
# Smart quotes
#===========================================================================

sub _convert_smart_quotes
{
   my ($text) = @_;

   # Unicode smart quotes → AsciiDoc typographic syntax
   $text =~ s/\x{201C}/"\`/g;
   $text =~ s/\x{201D}/\`"/g;
   $text =~ s/\x{2018}/'\`/g;
   $text =~ s/\x{2019}/\`'/g;

   return $text;
}

#===========================================================================
# Inline math — $...$ → stem:[...]
#===========================================================================

sub _convert_inline_math
{
   my ($text, $self) = @_;

   # $...$ where content does not span lines (single-line math)
   # Must not be preceded by $ (avoid $$ block math)
   # Content must have at least one non-space character
   # Use PROT markers for brackets to avoid ref link consumption
   $text =~ s{
        (?<!\$)           # not preceded by $ (avoid $$)
        \$
        ( [^\$\n]+? )    # math content (no $ chars, no newlines)
        \$
        (?!\$)           # not followed by $ (avoid $$)
    }{
        $self->{has_math} = 1;
        "stem:\x01PROT" . $1 . "\x01PROT";
    }xeg;

   return $text;
}

#===========================================================================
# Typographic symbols
#===========================================================================

sub _convert_typographic_symbols
{
   my ($text) = @_;

   # --- (em dash in paragraph text) → -- (AsciiDoc em dash)
   # In inline context, --- is not a thematic break, so convert.
   # Code spans are already protected at this point.
   $text =~ s/---/--/g;

   # ... (ellipsis) passes through unchanged (already ... in AsciiDoc)
   # en dash -- passes through unchanged

   return $text;
}

1;

__END__

=head1 NAME

Text::MarkdownAdoc::Inline - Inline formatting processor

=head1 DESCRIPTION

Handles inline formatting: bold, italic, code spans, strikethrough,
links, images, hard breaks, HTML entity handling, inline HTML
conversion, and smart quote conversion.

=head1 AUTHOR

Sandor Patocs

=head1 SEE ALSO

L<Text::MarkdownAdoc>, L<Text::MarkdownAdoc::Parser>,
L<Text::MarkdownAdoc::Refs>

=cut
