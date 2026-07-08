package Text::MarkdownAdoc::Refs;

use 5.016;
use strict;
use warnings;

#===========================================================================
# Reference and cross-reference resolver
#===========================================================================

sub new
{
   my ($class, %opts) = @_;

   my $self = {
               options       => {%opts},
               link_defs     => {},        # normalized label → { url, title }
               image_defs    => {},        # normalized label → { url, title }
               heading_ids   => {},        # normalized anchor → heading title
               footnote_defs => {},        # label → text (raw, not normalized)
               footnote_seen => {},        # label → count of times referenced
               };

   bless $self, $class;
   return $self;
}

# Register a link reference definition
sub add_link_def
{
   my ($self, $label, $url, $title) = @_;

   my $normalized = _normalize_label($label);
   $self->{link_defs}{$normalized} = {
                                      url   => $url,
                                      title => $title,
                                      };
}

# Register an image reference definition
sub add_image_def
{
   my ($self, $label, $url, $title) = @_;

   my $normalized = _normalize_label($label);
   $self->{image_defs}{$normalized} = {
                                       url   => $url,
                                       title => $title,
                                       };
}

# Register a heading ID and its title text
sub register_heading
{
   my ($self, $id, $title) = @_;

   $self->{heading_ids}{$id} = $title // '';
}

# Generate an AsciiDoc-compatible ID from heading text
sub generate_id
{
   my ($self, $text) = @_;

   my $idprefix    = $self->{options}{idprefix}    // '_';
   my $idseparator = $self->{options}{idseparator} // '_';

   my $id = lc($text);
   $id =~ s/[^a-z0-9]+/$idseparator/g;
   $id =~ s/^$idseparator+//;
   $id =~ s/$idseparator+$//;

   return $idprefix . $id;
}

# Register a footnote definition
sub add_footnote_def
{
   my ($self, $label, $text, $inline) = @_;

   # Process inline formatting inside footnote text
   my $processed = $inline->process($text);
   $self->{footnote_defs}{$label} = $processed;
}

# Build a footnote ID from the label (fn + non-word chars → _)
sub _footnote_id
{
   my ($label) = @_;

   my $id = 'fn' . $label;
   $id =~ s/[^\w]/_/g;
   return $id;
}

# Resolve all placeholders in the output text
sub resolve
{
   my ($self, $text) = @_;

   my $input = $text // '';
   return '' if $input eq '';

   # Resolve FOOTNOTE placeholders
   $input =~ s{\x00FOOTNOTE:([^\x00]+)\x00}{
        my $label = $1;

        my $def = $self->{footnote_defs}{$label};
        if ($def) {
            $self->{footnote_seen}{$label}++;
            my $count = $self->{footnote_seen}{$label};

            if ($count == 1) {
                my $id = _footnote_id($label);
                "footnote:$id\[$def\]";
            }
            else {
                my $id = _footnote_id($label);
                "footnote:$id\[\]";
            }
        }
        else {
            # Unresolved footnote: literal fallback
            "[^$label]";
        }
    }eg;

   # Resolve XREF placeholders (deferred cross-reference resolution)
   $input =~ s{\x00XREF:([^\x00]+)\x00}{
        my $payload = $1;

        # Format: id:display
        if ($payload =~ m/^([^:]+):(.*)/s) {
            my $anchor  = $1;
            my $display = $2;

            # Try to find the heading by exact anchor match first,
            # then try the generated ID form.
            my $resolved_anchor;
            if (exists $self->{heading_ids}{$anchor}) {
                $resolved_anchor = $anchor;
            }
            else {
                # Try generating the ID from the raw anchor
                my $gen_id = $self->generate_id($anchor);
                if (exists $self->{heading_ids}{$gen_id}) {
                    $resolved_anchor = $gen_id;
                }
            }

            if ($resolved_anchor) {
                # If display text matches the heading title for this anchor,
                # emit bare <<anchor>> without explicit text.
                my $title = $self->{heading_ids}{$resolved_anchor};
                if (defined $title && $display eq $title) {
                    "<<$resolved_anchor>>";
                }
                else {
                    "<<$resolved_anchor,$display>>";
                }
            }
            else {
                # Unresolved xref: emit the display text as a fallback
                "<<$anchor,$display>>";
            }
        }
        else {
            $payload;
        }
    }eg;

   # Resolve REFLINK placeholders
   $input =~ s{\x00REFLINK:([^:]+):([^\x00]*)\x00}{
        my $label = $1;
        my $display = $2;

        my $def = $self->{link_defs}{$label};
        if ($def) {
            _format_resolved_link($display, $def->{url});
        }
        else {
            # Unresolved: emit literal text
            $display;
        }
    }eg;

   # Resolve REFIMG placeholders
   $input =~ s{\x00REFIMG:([^:]+):([^\x00]*)\x00}{
        my $label = $1;
        my $alt = $2;

        my $def = $self->{image_defs}{$label};
        if ($def) {
            "image:$def->{url}\[$alt\]";
        }
        else {
            # Unresolved: emit literal alt text
            $alt;
        }
    }eg;

   return $input;
}

#===========================================================================
# Internal helpers
#===========================================================================

sub _normalize_label
{
   my ($label) = @_;

   $label = lc($label);
   $label =~ s/\s+/ /g;
   $label =~ s/^\s+|\s+$//g;

   return $label;
}

sub _format_resolved_link
{
   my ($text, $url) = @_;

   # Anchor link
   if ($url =~ m/^#(.+)/)
   {
      my $anchor = $1;
      return "<<$anchor,$text>>";
   }

   # .md file → .adoc xref
   if ($url =~ m/^(.+)\.md$/i)
   {
      my $base = $1;
      return "xref:$base.adoc\[$text\]";
   }

   # URL-only link where text equals URL → bare URL
   if ($text eq $url)
   {
      return $url;
   }

   # Standard link
   return "$url\[$text\]";
}

1;

__END__

=head1 NAME

Text::MarkdownAdoc::Refs - Reference and cross-reference resolver

=head1 DESCRIPTION

Handles heading ID registration, reference-style link/image definition
collection, deferred resolution pass (replaces placeholders in final
output), and xref rewrite.

=head1 AUTHOR

Sandor Patocs

=head1 SEE ALSO

L<Text::MarkdownAdoc>, L<Text::MarkdownAdoc::Parser>,
L<Text::MarkdownAdoc::Inline>

=cut
