package Text::MarkdownAdoc::Parser;

use 5.016;
use strict;
use warnings;

use Text::MarkdownAdoc::Inline;
use Text::MarkdownAdoc::Refs;

#===========================================================================
# Line-oriented state machine for Markdown-to-AsciiDoc block conversion
#===========================================================================

sub new
{
   my ($class, %opts) = @_;

   my $self = {
               options           => {%opts},
               inline            => Text::MarkdownAdoc::Inline->new(%opts),
               refs              => Text::MarkdownAdoc::Refs->new(%opts),
               diagram_languages => $opts{diagram_languages} || ['plantuml', 'mermaid'],
               has_math          => 0,
               };

   bless $self, $class;
   return $self;
}

sub parse
{
   my ($self, $text) = @_;

   my $input = $text // '';

   $input = _normalize_input($input);

   my @lines = split /\n/, $input;
   return "" unless @lines;

   my ($front_matter_keys, $body_start) = _extract_front_matter(\@lines);

   my @body_lines  = @lines[$body_start .. $#lines];
   my $body_output = _parse_body($self, \@body_lines);

   # Collect has_math from inline processor
   if ($self->{inline}->{has_math})
   {
      $self->{has_math} = 1;
   }

   my $body_has_h1 = _body_has_level1_heading(\@body_lines);

   my @output;

   if ($front_matter_keys && $front_matter_keys->{title} && !$body_has_h1)
   {
      push @output, '= ' . $front_matter_keys->{title};
   }

   if ($front_matter_keys)
   {
      for my $key (sort keys %$front_matter_keys)
      {
         if ($key eq 'title')
         {
            next;
         }
         push @output, ':' . $key . ': ' . $front_matter_keys->{$key};
      }
   }

   if ($self->{has_math})
   {
      push @output, ':stem: latexmath';
   }

   if (@output && $body_output ne '')
   {
      push @output, '';
   }

   if ($body_output ne '')
   {
      push @output, $body_output;
   }

   my $result = join("\n", @output);
   $result = $self->{refs}->resolve($result);
   $result = _normalize_output($result);
   $result = _apply_wrap($result, $self->{options}{wrap});

   return $result;
}

#===========================================================================
# Internal helpers
#===========================================================================

sub _normalize_input
{
   my ($text) = @_;

   $text =~ s/\r\n/\n/g;
   $text =~ s/\r/\n/g;
   $text =~ s/^(?:[ \t]*\n)+//;

   return $text;
}

sub _normalize_output
{
   my ($text) = @_;

   $text =~ s/[ \t]+$//gm;
   $text =~ s/\n{3,}/\n\n/g;
   $text =~ s/\n*$/\n/;

   if ($text =~ m/^\s*$/)
   {
      return '';
   }

   return $text;
}

sub _extract_front_matter
{
   my ($lines) = @_;

   return (undef, 0) unless @$lines && $lines->[0] =~ m/^---$/;

   my $end = -1;
   for (my $i = 1; $i < @$lines; $i++)
   {
      if ($lines->[$i] =~ m/^---$/)
      {
         $end = $i;
         last;
      }
   }

   return (undef, 0) if $end == -1;

   my %keys;
   for (my $i = 1; $i < $end; $i++)
   {
      my $line = $lines->[$i];
      if ($line =~ m/^([a-zA-Z_][a-zA-Z0-9_]*)[ \t]*:[ \t]*(.*)/)
      {
         my $key   = $1;
         my $value = $2;
         $value =~ s/[ \t]+$//;
         $keys{$key} = $value;
      }
   }

   return (\%keys, $end + 1);
}

sub _body_has_level1_heading
{
   my ($lines) = @_;

   for (my $i = 0; $i < @$lines; $i++)
   {
      my $line = $lines->[$i];

      if ($line =~ m/^[ \t]*#[ \t]/ || $line =~ m/^[ \t]*#$/)
      {
         return 1;
      }

      if ($i + 1 < @$lines)
      {
         my $next = $lines->[$i + 1];
         if ($line ne '' && $next =~ m/^=+$/)
         {
            if ($line !~ m/^[ \t]*[#=\-*_]/)
            {
               return 1;
            }
         }
      }
   }

   return 0;
}

sub _is_thematic_break
{
   my ($line, $prev_was_para) = @_;

   return 0 unless $line =~ m/^[ \t]*([-*_])[ \t]*\1[ \t]*\1[ \t]*(\1[ \t]*)*$/;

   if ($1 eq '-' && $prev_was_para)
   {
      return 0;
   }

   return 1;
}

sub _is_setext_underline
{
   my ($line) = @_;

   return 1 if $line =~ m/^=+$/;
   return 1 if $line =~ m/^-+$/;

   return 0;
}

sub _is_atx_heading
{
   my ($line) = @_;

   return 1 if $line =~ m/^[ \t]*#{1,6}[ \t]/;
   return 1 if $line =~ m/^[ \t]*#{1,6}$/;

   return 0;
}

sub _convert_atx_heading
{
   my ($self, $line) = @_;

   $line =~ m/^[ \t]*(#{1,6})[ \t]*(.*?)[ \t]*$/;

   my $hashes = $1;
   my $text   = $2 // '';

   my $level  = length($hashes);
   my $prefix = '=' x $level;

   $text =~ s/[ \t]+#+[ \t]*$//;
   $text =~ s/[ \t]+$//;

   # Extract explicit anchor: <a name="id"></a> or <a id="id"></a>
   my $explicit_anchor;
   if ($text =~ s/^<a\s+(?:name|id)\s*=\s*"([^"]+)"\s*><\/a>\s*//)
   {
      $explicit_anchor = $1;
   }

   # Strip any remaining inline HTML from heading text (handled by inline)
   $text = $self->{inline}->process($text);

   # Generate heading ID if auto_ids is enabled or if explicit anchor present
   my @heading_out;
   if ($explicit_anchor)
   {
      push @heading_out, "[[$explicit_anchor]]";
      $self->{refs}->register_heading($explicit_anchor, $text);
   }
   elsif ($self->{options}{auto_ids})
   {
      my $id = $self->{refs}->generate_id($text);
      push @heading_out, "[[$id]]";
      $self->{refs}->register_heading($id, $text);
   }

   push @heading_out, $prefix . ' ' . $text;

   return join("\n", @heading_out);
}

sub _is_ref_definition
{
   my ($line) = @_;

   return 1 if $line =~ m/^[ \t]*\[[^\]]+\]:[ \t]*\S/;

   return 0;
}

sub _parse_ref_definition
{
   my ($self, $line) = @_;

   if ($line =~ m/^[ \t]*\[([^\]]+)\]:[ \t]*(\S+)(?:[ \t]+"([^"]*)")?/)
   {
      my $label = $1;
      my $url   = $2;
      my $title = $3;
      $self->{refs}->add_link_def($label, $url, $title);
      return 1;
   }

   return 0;
}

#===========================================================================
# Footnote definition detection and parsing
#===========================================================================

# Check if a line is a footnote definition: [^label]: text
sub _is_footnote_definition
{
   my ($line) = @_;

   return 1 if $line =~ m/^[ \t]*\[\^[^\]]+\]:[ \t]/;
   return 0;
}

# Parse a footnote definition and its multi-line continuations.
# Continuation lines are indented by 4+ spaces.
# Returns { label, text, next_idx }
sub _parse_footnote_definition
{
   my ($self, $lines, $start_idx) = @_;

   my $i    = $start_idx;
   my $line = $lines->[$i];

   my ($label, $text);
   if ($line =~ m/^[ \t]*\[\^([^\]]+)\]:[ \t]+(.*)/)
   {
      $label = $1;
      $text  = $2;
   }
   else
   {
      return undef;
   }

   $text =~ s/[ \t]+$//;
   $i++;

   # Collect continuation lines (indented by 4+ spaces)
   my @continuation;
   while ($i < @$lines)
   {
      my $cl = $lines->[$i];
      if ($cl =~ m/^[ \t]{4,}(.*)/)
      {
         my $cont_text = $1;
         $cont_text =~ s/[ \t]+$//;
         push @continuation, $cont_text;
         $i++;
         next;
      }
      last;
   }

   if (@continuation)
   {
      $text .= ' ' . join(' ', @continuation);
   }

   return {
           label    => $label,
           text     => $text,
           next_idx => $i,
           };
}

sub _emit_paragraph
{
   my ($self, $para_lines) = @_;

   my @processed;
   for my $line (@$para_lines)
   {
      if ($line =~ s/[ \t]{2,}$//)
      {
         push @processed, $line . ' +';
      }
      elsif ($line =~ s/\\$//)
      {
         push @processed, $line . ' +';
      }
      else
      {
         push @processed, $line;
      }
   }

   my $text = join("\n", @processed);
   $text = $self->{inline}->process($text);

   return $text;
}

sub _is_block_image
{
   my ($para_lines) = @_;

   return 0 unless @$para_lines == 1;

   my $line = $para_lines->[0];

   return 1 if $line =~ m/^!\[.*\]\([^)]+\)$/;
   return 1 if $line =~ m/^!\[.*\]\[[^\]]*\]$/;

   return 0;
}

sub _convert_block_image
{
   my ($self, $line) = @_;

   if ($line =~ m/^!\[(.*)\]\(([^)]+)\)$/)
   {
      my $alt = $1;
      my $src = $2;
      return "image::$src\[$alt\]";
   }

   my $processed = $self->{inline}->process($line);

   if ($processed =~ m/^\x00REFIMG:([^:]+):([^\x00]*)\x00$/)
   {
      return $processed;
   }

   return $processed;
}

#===========================================================================
# Fenced code block detection
#===========================================================================

sub _is_opening_fence
{
   my ($line) = @_;

   return 1 if $line =~ m/^[ \t]*(\x60{3,})(\S*)\s*$/;
   return 1 if $line =~ m/^[ \t]*(~{3,})(\S*)\s*$/;

   return 0;
}

sub _get_fence_info
{
   my ($line) = @_;

   if ($line =~ m/^[ \t]*(\x60{3,})(\S*)\s*$/)
   {
      return ('`', length($1), $2);
   }
   if ($line =~ m/^[ \t]*(~{3,})(\S*)\s*$/)
   {
      return ('~', length($1), $2);
   }

   return (undef, 0, '');
}

sub _is_diagram_language
{
   my ($self, $lang) = @_;

   return 0 unless $lang;

   my $lc = lc($lang);
   for my $dl (@{$self->{diagram_languages}})
   {
      return 1 if lc($dl) eq $lc;
   }

   return 0;
}

#===========================================================================
# Blockquote processing
#===========================================================================

sub _count_blockquote_depth
{
   my ($line) = @_;

   my $depth = 0;
   my $pos   = 0;
   my $len   = length($line);

   while ($pos < $len)
   {
      my $ch = substr($line, $pos, 1);
      if ($ch eq '>')
      {
         $depth++;
         $pos++;
         if ($pos < $len && substr($line, $pos, 1) eq ' ')
         {
            $pos++;
         }
      }
      else
      {
         last;
      }
   }

   return $depth;
}

sub _parse_blockquote
{
   my ($self, $lines, $start_idx) = @_;

   my @content_lines;
   my $i     = $start_idx;
   my $depth = 0;
   my $first = 1;

   while ($i < @$lines)
   {
      my $line = $lines->[$i];

      if ($line eq '')
      {
         my $j = $i + 1;
         while ($j < @$lines && $lines->[$j] eq '')
         {
            $j++;
         }
         if ($j < @$lines && $lines->[$j] =~ m/^>/)
         {
            push @content_lines, '';
            $i++;
            next;
         }
         last;
      }

      if ($line =~ m/^>/)
      {
         push @content_lines, $line;
         $i++;
         next;
      }

      last;
   }

   # Determine minimum depth across all non-blank lines
   my $min_depth = undef;
   for my $rl (@content_lines)
   {
      next if $rl eq '';
      my $d = _count_blockquote_depth($rl);
      $min_depth = $d if !defined($min_depth) || $d < $min_depth;
   }
   $min_depth //= 1;

   # Strip min_depth levels of '>' from every non-blank line
   my @stripped;
   for my $rl (@content_lines)
   {
      if ($rl eq '')
      {
         push @stripped, '';
         next;
      }
      my $s = $rl;
      for (1 .. $min_depth)
      {
         $s =~ s/^>[ ]?//;
      }
      push @stripped, $s;
   }

   return {lines => \@stripped, depth => $min_depth, next_idx => $i};
}

#===========================================================================
# List processing
#===========================================================================

sub _get_list_item_info
{
   my ($line) = @_;

   # Unordered (with optional task checkbox)
   if ($line =~ m/^([ \t]*)([-*+])([ \t]+)(\[[ xX]\]\s*)?(.*)/)
   {
      my $leading = $1;
      my $info = {
                  type   => 'ul',
                  indent => length($leading),
                  marker => $2,
                  text   => $5 // '',
                  task   => '',
                  };
      if (defined $4 && $4 ne '')
      {
         my $cb = $4;
         $cb =~ s/\s+$//;
         $info->{task} = $cb;
      }
      return $info;
   }

   # Ordered
   if ($line =~ m/^([ \t]*)(\d+)([.)])([ \t]+)(.*)/)
   {
      my $leading = $1;
      return {
              type   => 'ol',
              indent => length($leading),
              marker => $2 . $3,
              text   => $5 // '',
              task   => '',
              };
   }

   return undef;
}

sub _get_list_depth
{
   my ($indent) = @_;

   return int($indent / 2);
}

#===========================================================================
# Admonition detection
#===========================================================================

sub _is_admonition_label
{
   my ($text) = @_;

   my %labels = (
                 'note'      => 'NOTE',
                 'tip'       => 'TIP',
                 'important' => 'IMPORTANT',
                 'warning'   => 'WARNING',
                 'caution'   => 'CAUTION',
                 );

   if ($text =~ m/^\*\*([Nn]ote|[Tt]ip|[Ii]mportant|[Ww]arning|[Cc]aution):\*\*\s*(.*)/)
   {
      my $label = lc($1);
      my $rest  = $2;
      return ($labels{$label}, $rest);
   }

   if ($text =~ m/^([Nn]ote|[Tt]ip|[Ii]mportant|[Ww]arning|[Cc]aution):\s*(.*)/)
   {
      my $label = lc($1);
      my $rest  = $2;
      return ($labels{$label}, $rest);
   }

   return ();
}

#===========================================================================
# Process inline text for list items — must protect [ ] from ref link parsing
#===========================================================================

sub _process_list_item_text
{
   my ($self, $info) = @_;

   my $text = $info->{text};

   # Process text content through inline formatting first
   $text = $self->{inline}->process($text);

   # Prepend task checkbox after inline processing to avoid
   # [ ] / [x] being consumed by reference link matching in Inline.pm.
   # Normalize [X] → [x] for consistency.
   if ($info->{task} ne '')
   {
      my $task = $info->{task};
      $task =~ s/\[X\]/[x]/;
      $text = $task . ' ' . $text;
   }

   return $text;
}

#===========================================================================
# Build an AsciiDoc list marker from the list stack
#===========================================================================

sub _build_list_marker
{
   my ($list_stack) = @_;

   # Build AsciiDoc marker: repeat the current type's character
   # for the total nesting depth (stack size).
   # E.g., ul at depth 2 → '**', ol at depth 2 → '..'
   my $depth = scalar @$list_stack;
   my $type  = $list_stack->[-1]{type};

   my $ch = ($type eq 'ul') ? '*' : '.';
   return $ch x $depth;
}

#===========================================================================
# GFM Table detection and conversion
#===========================================================================

# Check if a line looks like a table header (starts and ends with |)
sub _is_table_row
{
   my ($line) = @_;

   return 1 if $line =~ m/^\|.*\|$/;
   return 1 if $line =~ m/^\|/;

   return 0;
}

# Check if a line is a table delimiter row (only |, -, :, spaces)
sub _is_table_delimiter
{
   my ($line) = @_;

   return 1 if $line =~ m/^\|[-\s:|]+\|$/;

   return 0;
}

# Parse a table row into cells, stripping leading/trailing whitespace
sub _parse_table_cells
{
   my ($line) = @_;

   # Remove leading and trailing |
   my $inner = $line;
   $inner =~ s/^\|//;
   $inner =~ s/\|$//;

   # Split on | (not on escaped \|)
   my @cells = split /(?<!\\)\|/, $inner;

   # Strip leading/trailing whitespace and escape pipes
   for my $cell (@cells)
   {
      $cell =~ s/^[ \t]+|[ \t]+$//g;
      $cell =~ s/\\\|/|/g;
   }

   return @cells;
}

# Determine column alignment from delimiter cell
sub _parse_alignment
{
   my ($cell) = @_;

   my $trimmed = $cell;
   $trimmed =~ s/^[ \t]+|[ \t]+$//g;

   my $left  = ($trimmed =~ m/^:/) ? 1 : 0;
   my $right = ($trimmed =~ m/:$/) ? 1 : 0;

   if ($left && $right)
   {
      return '^';
   }
   elsif ($right)
   {
      return '>';
   }
   elsif ($left)
   {
      return '<';
   }

   # Default
   return '<';
}

# Check if a sequence of lines starting at index i forms a GFM table
# Returns { header_cells, alignments, body_rows, next_idx } or undef
sub _parse_table
{
   my ($self, $lines, $start_idx) = @_;

   my $i = $start_idx;

   # Must have at least header + delimiter rows
   return undef unless $i + 1 < @$lines;

   # First line must be a table row (potential header)
   return undef unless _is_table_row($lines->[$i]);

   my $header_line = $lines->[$i];
   $i++;

   # Second line must be a delimiter row
   return undef unless $i < @$lines && _is_table_delimiter($lines->[$i]);

   my $delimiter_line = $lines->[$i];
   $i++;

   my @header_cells = _parse_table_cells($header_line);
   my @delim_cells  = _parse_table_cells($delimiter_line);

   # Column count must match
   return undef unless @header_cells == @delim_cells;

   my @alignments;
   for my $dc (@delim_cells)
   {
      push @alignments, _parse_alignment($dc);
   }

   # Collect body rows
   my @body_rows;
   while ($i < @$lines)
   {
      my $row_line = $lines->[$i];

      if ($row_line eq '')
      {
         $i++;
         last;
      }

      return undef unless _is_table_row($row_line);

      my @cells = _parse_table_cells($row_line);

      # Allow rows with fewer cells than header (pad with empty)
      while (@cells < @header_cells)
      {
         push @cells, '';
      }

      push @body_rows, \@cells;
      $i++;
   }

   return {
           header_cells => \@header_cells,
           alignments   => \@alignments,
           body_rows    => \@body_rows,
           next_idx     => $i,
           };
}

# Convert parsed table to AsciiDoc
sub _convert_table
{
   my ($self, $table) = @_;

   my $header_cells = $table->{header_cells};
   my $alignments   = $table->{alignments};
   my $body_rows    = $table->{body_rows};
   my $num_cols     = scalar @$header_cells;

   my @out;

   # Determine if we need [cols=...]
   my $all_default = 1;
   for my $a (@$alignments)
   {
      if ($a ne '<')
      {
         $all_default = 0;
         last;
      }
   }

   # Only emit [cols=...] when not all default AND more than 1 column
   if (!$all_default && $num_cols > 1)
   {
      my $cols = '"' . join(',', @$alignments) . '"';
      push @out, "[cols=$cols]";
   }

   push @out, '|===';

   # Header row (compact: all cells on one line)
   my @header_processed;
   for my $cell (@$header_cells)
   {
      my $processed = $self->{inline}->process($cell);
      push @header_processed, $processed;
   }
   push @out, '| ' . join(' | ', @header_processed);

   # Blank line between header and first body row (required by Asciidoctor)
   push @out, '';

   # Body rows (compact format)
   for my $row (@$body_rows)
   {
      my @row_processed;
      for my $cell (@$row)
      {
         my $processed = $self->{inline}->process($cell);
         $processed =~ s/\|/\\\|/g;
         push @row_processed, $processed;
      }
      push @out, '| ' . join(' | ', @row_processed);
   }

   push @out, '|===';

   return join("\n", @out);
}

#===========================================================================
# Block-level HTML detection and conversion
#===========================================================================

# Check if a line starts a block-level HTML element or comment
sub _is_block_html_start
{
   my ($line) = @_;

   # HTML comment
   return 1 if $line =~ m/^<!--/;

   # Only treat actual block-level tags as block HTML
   # Inline tags (even if at line start) go through paragraph/inline processing
   my %block_tags = map { $_ => 1 } qw(
     div details table script iframe embed
     pre nav section article header footer main aside
     form fieldset figure figcaption ol ul dl
     );

   # Must be a real HTML tag: after the tag name, next char must be
   # space, >, /, or /; — not a character that would make it a URL or text.
   if ($line =~ m/^<(\/?)([a-zA-Z][a-zA-Z0-9]*)(?:\s|>|\/>|$)/)
   {
      my $closing = $1;
      my $tag     = lc($2);

      return 1 if $block_tags{$tag};

      # Also treat unknown/not-inline tags as block HTML
      # Inline tags: known inline elements or tags already handled by Inline.pm
      my %inline_tags = map { $_ => 1 } qw(
        br strong b em i code del s mark sup sub
        a span small abbr cite dfn kbd q samp var
        img input select textarea button label
        );

      return 0 if $inline_tags{$tag};
      return 0 if $tag =~ m/^h[1-6]$/;

      # Closing tags of block elements
      return 1 if $closing;
      return 1;
   }

   return 0;
}

# Parse a block HTML element or comment, consuming lines
# Returns { type, content, next_idx }
sub _parse_block_html
{
   my ($self, $lines, $start_idx) = @_;

   my $i    = $start_idx;
   my $line = $lines->[$i];

   # HTML comment
   if ($line =~ m/^<!--/)
   {
      # Check if it's a single-line comment
      if ($line =~ m/^<!--\s*(.*?)\s*-->$/)
      {
         my $content = $1;

         # Check for ! prefix (directive)
         if ($content =~ s/^!\s*//)
         {
            return {type => 'comment_directive', content => $content, next_idx => $i + 1};
         }

         return {type => 'comment_single', content => $content, next_idx => $i + 1};
      }

      # Multi-line comment: content between <!-- and -->
      my @comment_lines;

      # Extract content after <!--
      my $stripped = $line;
      $stripped =~ s/^<!--\s*//;
      if ($stripped =~ s/\s*-->$//)
      {
         # Comment ends on same line
         return {type => 'comment_single', content => $stripped, next_idx => $i + 1};
      }
      push @comment_lines, $stripped if $stripped ne '';
      $i++;

      while ($i < @$lines)
      {
         my $cl = $lines->[$i];
         if ($cl =~ m/^(.*?)\s*-->$/)
         {
            my $last = $1;
            push @comment_lines, $last if $last ne '';
            $i++;
            last;
         }
         push @comment_lines, $cl;
         $i++;
      }

      my $content = join("\n", @comment_lines);

      # Check for ! prefix on first line (directive)
      if (@comment_lines && $comment_lines[0] =~ s/^!\s*//)
      {
         $comment_lines[0] = $comment_lines[0];
         $content = join("\n", @comment_lines);

         # Single-line after all: if only one line, use // ; otherwise ////
         if (@comment_lines == 1)
         {
            return {type => 'comment_directive', content => $content, next_idx => $i};
         }
         return {type => 'comment_directive', content => $content, next_idx => $i};
      }

      if (@comment_lines == 1)
      {
         return {type => 'comment_single', content => $content, next_idx => $i};
      }

      return {type => 'comment_multi', content => $content, next_idx => $i};
   }

   # Block HTML element (div, script, table, etc.)
   my @html_lines;
   push @html_lines, $line;
   $i++;

   # Collect until blank line or matching closing tag
   # Simple heuristic: collect lines until we see a blank line
   # or a closing tag on its own line that matches depth
   my $tag_name;
   if ($line =~ m/^<([a-zA-Z][a-zA-Z0-9]*)/)
   {
      $tag_name = $1;
   }

   while ($i < @$lines)
   {
      my $hl = $lines->[$i];

      if ($hl eq '')
      {
         last;
      }

      # Check for closing tag
      if ($tag_name && $hl =~ m/^<\/$tag_name>/)
      {
         push @html_lines, $hl;
         $i++;
         last;
      }

      push @html_lines, $hl;
      $i++;
   }

   return {
           type     => 'html_block',
           content  => join("\n", @html_lines),
           next_idx => $i,
           };
}

#===========================================================================
# Definition list detection and conversion
#===========================================================================

# Check if a line is a definition list bold term with colons form
# Returns { term, level } or undef
sub _is_def_list_bold_term
{
   my ($line) = @_;

   # Match **term** with 2+ colons and optional space before definition
   if ($line =~ m/^\*\*(.+?)\*\*(:{2,})\s*(.*)/)
   {
      my $term   = $1;
      my $colons = $2;
      my $def    = $3;
      return {
              term  => $term,
              level => length($colons),
              def   => $def,
              };
   }

   return undef;
}

# Check if the next line(s) start with ': ' (definition list continuation)
sub _is_def_list_standard
{
   my ($lines, $start_idx) = @_;

   return 0 if $start_idx >= @$lines;

   # Next line must start with ': '
   my $next = $lines->[$start_idx];
   return 1 if $next =~ m/^:[ \t]/;

   return 0;
}

# Parse a standard definition list entry
# Returns { term, definitions, next_idx }
sub _parse_def_list_standard
{
   my ($self, $lines, $start_idx) = @_;

   my $i = $start_idx;

   # First line is the term
   my $term = $lines->[$i];
   $i++;

   # Collect definition lines (starting with ': ')
   my @defs;
   while ($i < @$lines)
   {
      my $dl = $lines->[$i];

      if ($dl =~ m/^:[ \t]+(.*)/)
      {
         push @defs, $1;
         $i++;
         next;
      }

      last;
   }

   return {
           term        => $term,
           definitions => \@defs,
           next_idx    => $i,
           };
}

#===========================================================================
# Main body parser
#===========================================================================

sub _parse_body
{
   my ($self, $lines) = @_;

   my @out;
   my @para;
   my $prev_was_para = 0;
   my $in_list       = 0;
   my @list_stack;           # {type, depth}
   my @list_items;           # Collected list item strings
   my $list_is_loose = 0;    # Whether current list has blank lines between items

   my $flush_para = sub {
      if (@para)
      {
         if (_is_block_image(\@para))
         {
            push @out, $self->_convert_block_image($para[0]);
         }
         else
         {
            push @out, $self->_emit_paragraph(\@para);
         }
         @para = ();
      }
   };

   my $flush_list = sub {
      if (@list_items)
      {
         my $sep = $list_is_loose ? "\n\n" : "\n";
         push @out, join($sep, @list_items);
         @list_items    = ();
         $list_is_loose = 0;
      }
   };

   my $i = 0;
   while ($i < @$lines)
   {
      my $line = $lines->[$i];

      # --- Blank line ---
      if ($line eq '')
      {
         if ($in_list)
         {
            my $j = $i + 1;
            while ($j < @$lines && $lines->[$j] eq '')
            {
               $j++;
            }
            if ($j < @$lines)
            {
               my $next_line = $lines->[$j];
               my $next_info = _get_list_item_info($next_line);

               # Check if this blank line precedes a definition list
               if (!$next_info && !$in_list)
               {
                  # Not in list context, let default blank-line handling run
               }

               if ($next_info)
               {
                  # Loose list: mark as loose, skip blank
                  $list_is_loose = 1;
                  $i++;
                  next;
               }

               # Check for definition list continuation after blank line
               # (definition lists can have blank lines between term and def)
               if (_is_def_list_standard($lines, $j))
               {
                  # Blank line before a definition list entry — it's a new entry
                  # handled by the def list detection below (when processing term)
                  $flush_para->();
                  $prev_was_para = 0;
                  $i++;
                  next;
               }
            }

            # End of list
            $flush_list->();
            $in_list       = 0;
            @list_stack    = ();
            $prev_was_para = 0;
            $i++;
            next;
         }

         $flush_para->();
         $prev_was_para = 0;
         $i++;
         next;
      }

      # --- HTML block (comment or block-level element) ---
      if (_is_block_html_start($line))
      {
         $flush_para->();
         $flush_list->();
         $in_list    = 0;
         @list_stack = ();

         my $html = $self->_parse_block_html($lines, $i);
         $i = $html->{next_idx};

         if ($html->{type} eq 'comment_single')
         {
            push @out, '// ' . $html->{content};
         }
         elsif ($html->{type} eq 'comment_multi')
         {
            push @out, "////\n" . $html->{content} . "\n////";
         }
         elsif ($html->{type} eq 'comment_directive')
         {
            my $content = $html->{content};

            # Single-line directive
            if ($content !~ m/\n/)
            {
               push @out, '// ' . $content;
            }
            else
            {
               # Multi-line: strip ! prefix from first line
               my @dlines = split /\n/, $content;
               $dlines[0] =~ s/^!\s*//;

               # After stripping, if only one non-empty line, use //
               my @non_empty = grep { $_ ne '' } @dlines;
               if (@non_empty <= 1)
               {
                  push @out, '// ' . join(' ', @dlines);
               }
               else
               {
                  push @out, "////\n" . join("\n", @dlines) . "\n////";
               }
            }
         }
         elsif ($html->{type} eq 'html_block')
         {
            push @out, "++++\n" . $html->{content} . "\n++++";
         }

         $prev_was_para = 0;
         next;
      }

      # --- GFM Table ---
      if (_is_table_row($line))
      {
         my $table = $self->_parse_table($lines, $i);
         if ($table)
         {
            $flush_para->();
            $flush_list->();
            $in_list    = 0;
            @list_stack = ();

            push @out, $self->_convert_table($table);
            $i             = $table->{next_idx};
            $prev_was_para = 0;
            next;
         }

         # Not a valid table, treat as paragraph
         push @para, $line;
         $prev_was_para = 1;
         $i++;
         next;
      }

      # --- Block math ($$...$$) ---
      if ($line =~ m/^\$\$$/)
      {
         $flush_para->();
         $flush_list->();
         $in_list          = 0;
         @list_stack       = ();
         $self->{has_math} = 1;

         $i++;
         my @math_lines;
         while ($i < @$lines)
         {
            my $ml = $lines->[$i];
            if ($ml =~ m/^\$\$$/)
            {
               $i++;
               last;
            }
            push @math_lines, $ml;
            $i++;
         }

         if (@math_lines && $math_lines[-1] eq '')
         {
            pop @math_lines;
         }

         my $math_text = join("\n", @math_lines);
         push @out, "[stem]\n++++\n" . ($math_text ne '' ? "$math_text\n" : '') . "++++";

         $prev_was_para = 0;
         next;
      }

      # --- Fenced code block ---
      if (_is_opening_fence($line))
      {
         $flush_para->();
         $flush_list->();
         $in_list    = 0;
         @list_stack = ();

         my ($fence_char, $fence_len, $lang) = _get_fence_info($line);
         $i++;

         my @code_lines;
         while ($i < @$lines)
         {
            my $cl = $lines->[$i];
            if ($cl =~ m/^[ \t]*(\Q$fence_char\E{$fence_len,})\s*$/)
            {
               $i++;
               last;
            }
            push @code_lines, $cl;
            $i++;
         }

         if (@code_lines && $code_lines[-1] eq '')
         {
            pop @code_lines;
         }

         my $code_text = join("\n", @code_lines);

         # Fenced math block: ```math → [stem] ++++
         if ($lang && lc($lang) eq 'math')
         {
            $self->{has_math} = 1;
            push @out, "[stem]\n++++\n" . ($code_text ne '' ? "$code_text\n" : '') . "++++";
         }
         elsif ($lang && $self->_is_diagram_language($lang))
         {
            push @out, "[$lang]\n....\n" . ($code_text ne '' ? "$code_text\n" : '') . "....";
         }
         elsif ($lang)
         {
            push @out, "[source,$lang]\n----\n" . ($code_text ne '' ? "$code_text\n" : '') . "----";
         }
         else
         {
            push @out, "----\n" . ($code_text ne '' ? "$code_text\n" : '') . "----";
         }

         $prev_was_para = 0;
         next;
      }

      # --- Indented code block (outside list context only) ---
      if (!$in_list && $line =~ m/^[ \t]{4,}/ && $line !~ m/^[ \t]*[-*+]\s/ && $line !~ m/^[ \t]*\d+[.)]\s/)
      {
         $flush_para->();

         my @code_lines;
         while ($i < @$lines)
         {
            my $cl = $lines->[$i];
            if ($cl eq '')
            {
               push @code_lines, '';
               $i++;
               next;
            }
            if ($cl =~ m/^[ \t]{4,}(.*)/)
            {
               push @code_lines, $1;
               $i++;
               next;
            }
            last;
         }

         while (@code_lines && $code_lines[-1] eq '')
         {
            pop @code_lines;
         }

         my $code_text = join("\n", @code_lines);
         push @out, "....\n" . ($code_text ne '' ? "$code_text\n" : '') . "....";

         $prev_was_para = 0;
         next;
      }

      # --- Blockquote ---
      if ($line =~ m/^>/)
      {
         $flush_para->();
         $flush_list->();
         $in_list    = 0;
         @list_stack = ();

         my $bq = $self->_parse_blockquote($lines, $i);
         $i = $bq->{next_idx};
         my $bq_lines = $bq->{lines};
         my $depth    = $bq->{depth};

         # Check for admonition
         my $is_admonition    = 0;
         my $admonition_label = '';
         my $admonition_text  = '';

         if (@$bq_lines)
         {
            my $first = $bq_lines->[0];
            my ($label, $rest) = _is_admonition_label($first);
            if ($label)
            {
               $is_admonition    = 1;
               $admonition_label = $label;
               $admonition_text  = $rest;
            }
         }

         if ($is_admonition)
         {
            if (@$bq_lines > 1)
            {
               my $block = "[$admonition_label]\n====\n";
               $block .= $admonition_text . "\n";
               for (my $k = 1; $k < @$bq_lines; $k++)
               {
                  my $pl = $bq_lines->[$k];
                  if ($pl eq '')
                  {
                     $block .= "\n";
                  }
                  else
                  {
                     $block .= $self->{inline}->process($pl) . "\n";
                  }
               }
               $block .= "====";
               push @out, $block;
            }
            else
            {
               push @out, "$admonition_label: $admonition_text";
            }
         }
         else
         {
            my $bq_content = _parse_body($self, $bq_lines);
            my $delim      = '_' x (4 + ($depth - 1) * 2);
            push @out, "$delim\n" . ($bq_content ne '' ? "$bq_content\n" : '') . $delim;
         }

         $prev_was_para = 0;
         next;
      }

      # --- Thematic break (before list check) ---
      if (_is_thematic_break($line, $prev_was_para))
      {
         $flush_para->();
         $flush_list->();
         $in_list    = 0;
         @list_stack = ();
         push @out, "'''";
         $prev_was_para = 0;
         $i++;
         next;
      }

      # --- Definition list (bold term :: form) ---
      if (!$in_list)
      {
         my $bold_term = _is_def_list_bold_term($line);
         if ($bold_term)
         {
            $flush_para->();
            $flush_list->();
            $in_list    = 0;
            @list_stack = ();

            my $level  = $bold_term->{level};
            my $prefix = ':' x $level;

            my $term_processed = $self->{inline}->process($bold_term->{term});
            my $def_processed  = $self->{inline}->process($bold_term->{def});

            my @dl_out;
            push @dl_out, "${term_processed}${prefix}";
            push @dl_out, $def_processed;
            push @out,    join("\n", @dl_out);

            $prev_was_para = 0;
            $i++;
            next;
         }
      }

      # --- Definition list (standard form: Term\n: Definition) ---
      # Check if this is a term followed by definition(s)
      if (!$in_list && !@para && $i + 1 < @$lines)
      {
         my $next_line = $lines->[$i + 1];
         if ($next_line =~ m/^:[ \t]/)
         {
            my $prev_blank = ($i == 0 || $lines->[$i - 1] eq '');

            # Don't treat a line starting with '> ' as a def list term
            if ($line !~ m/^>/ &&
                $line !~ m/^[ \t]*[-*+#]/    &&
                !_is_atx_heading($line)      &&
                !_is_setext_underline($line) &&
                !_is_block_html_start($line))
            {

               $flush_para->();
               $flush_list->();
               $in_list    = 0;
               @list_stack = ();

               my $def = $self->_parse_def_list_standard($lines, $i);
               $i = $def->{next_idx};

               my $term_processed = $self->{inline}->process($def->{term});

               my @dl_out;
               push @dl_out, "${term_processed}::";

               my @defs = @{$def->{definitions}};
               for (my $d = 0; $d < @defs; $d++)
               {
                  my $def_text = $self->{inline}->process($defs[$d]);
                  if ($d == 0)
                  {
                     push @dl_out, $def_text;
                  }
                  else
                  {
                     # Multiple definitions: use list continuation
                     push @dl_out, '+';
                     push @dl_out, $def_text;
                  }
               }
               push @out, join("\n", @dl_out);

               $prev_was_para = 0;
               next;
            }
         }
      }

      # --- List item ---
      my $item_info = _get_list_item_info($line);
      if ($item_info)
      {
         $flush_para->();

         my $depth = _get_list_depth($item_info->{indent});

         # Pop from stack if depth decreased
         while (@list_stack && $list_stack[-1]{depth} > $depth)
         {
            pop @list_stack;
         }

         # Update or push stack entry
         if (!@list_stack)
         {
            push @list_stack, {type => $item_info->{type}, depth => $depth};
         }
         elsif ($list_stack[-1]{depth} < $depth)
         {
            push @list_stack, {type => $item_info->{type}, depth => $depth};
         }
         else
         {
            # Same depth — update type if switching (ul→ol or ol→ul)
            $list_stack[-1]{type} = $item_info->{type};
         }

         my $marker    = _build_list_marker(\@list_stack);
         my $item_text = $self->_process_list_item_text($item_info);

         # Collect continuation lines
         $i++;
         my @continuation;
         while ($i < @$lines)
         {
            my $cl = $lines->[$i];
            if ($cl eq '')
            {
               last;
            }

            # Continuation: indented at least 2 spaces, not a new list item,
            # not a block-level construct
            if ($cl =~ m/^[ \t]{2,}/ &&
                !_get_list_item_info($cl) &&
                !_is_atx_heading($cl)     &&
                $cl !~ m/^>/              &&
                !_is_opening_fence($cl))
            {
               # Strip minimal indentation (the list indent + 2 spaces)
               push @continuation, $cl;
               $i++;
               next;
            }
            last;
         }

         if (@continuation)
         {
            # Append continuation lines to the item text
            my $cont_text = join("\n", @continuation);
            $item_text .= "\n" . $cont_text;
         }

         # Check for a block attachment after a blank line:
         # If the next non-blank line is an indented fenced code block or
         # an indented code block (4+ spaces), attach it to this item with '+'.
         if ($i < @$lines && $lines->[$i] eq '')
         {
            my $j = $i + 1;
            while ($j < @$lines && $lines->[$j] eq '')
            {
               $j++;
            }
            if ($j < @$lines)
            {
               my $peek = $lines->[$j];
               # Only attach indented fenced code blocks (2+ spaces then ``` or ~~~)
               # Plain 4-space indented code after a list blank line is treated as
               # a detached code block (existing behavior, per t/03 test 24).
               if ($peek =~ m/^[ \t]{2,}```/ || $peek =~ m/^[ \t]{2,}~~~/)
               {
                  # Determine the continuation indent (2 spaces for top-level items)
                  my $cont_indent = ($item_info->{indent} || 0) + 2;

                  # Fenced code block: collect until closing fence
                  $i = $j;
                  my $fence_line = $lines->[$i];
                  $fence_line =~ m/^[ \t]*((`{3,})|(~{3,}))(\S*)/;
                  my $fence_char = substr($1, 0, 1);
                  my $fence_len  = length($1);
                  my $lang       = $4 // '';

                  $i++;
                  my @code_lines;
                  while ($i < @$lines)
                  {
                     my $cl = $lines->[$i];
                     if ($cl =~ m/^[ \t]*\Q$fence_char\E{$fence_len,}\s*$/)
                     {
                        $i++;
                        last;
                     }
                     # Dedent by cont_indent
                     $cl =~ s/^[ \t]{1,$cont_indent}//;
                     push @code_lines, $cl;
                     $i++;
                  }
                  while (@code_lines && $code_lines[-1] eq '') { pop @code_lines }
                  my $code_text = join("\n", @code_lines);
                  my $block_str;
                  if ($lang && $self->_is_diagram_language($lang))
                  {
                     $block_str = "[$lang]\n....\n" . ($code_text ne '' ? "$code_text\n" : '') . "....";
                  }
                  elsif ($lang)
                  {
                     $block_str = "[source,$lang]\n----\n" . ($code_text ne '' ? "$code_text\n" : '') . "----";
                  }
                  else
                  {
                     $block_str = "----\n" . ($code_text ne '' ? "$code_text\n" : '') . "----";
                  }
                  push @list_items, "$marker $item_text";
                  push @list_items, "+\n$block_str";
                  $in_list       = 1;
                  $prev_was_para = 0;
                  next;
               }
            }
         }

         push @list_items, "$marker $item_text";
         $in_list       = 1;
         $prev_was_para = 0;
         next;
      }

      # --- Admonition paragraph ---
      if (!@para && !$in_list)
      {
         my ($label, $rest) = _is_admonition_label($line);
         if ($label)
         {
            $flush_para->();
            push @out, "$label: $rest";
            $prev_was_para = 0;
            $i++;
            next;
         }
      }

      # --- Footnote definition ---
      if (_is_footnote_definition($line))
      {
         $flush_para->();
         $flush_list->();
         $in_list    = 0;
         @list_stack = ();

         my $fn = $self->_parse_footnote_definition($lines, $i);
         if ($fn)
         {
            $self->{refs}->add_footnote_def($fn->{label}, $fn->{text}, $self->{inline});
            $i = $fn->{next_idx};
         }
         else
         {
            $i++;
         }
         $prev_was_para = 0;
         next;
      }

      # --- Reference definition ---
      if (_is_ref_definition($line))
      {
         $flush_para->();
         $flush_list->();
         $in_list    = 0;
         @list_stack = ();
         $self->_parse_ref_definition($line);
         $prev_was_para = 0;
         $i++;
         next;
      }

      # --- ATX heading ---
      if (_is_atx_heading($line))
      {
         $flush_para->();
         $flush_list->();
         $in_list    = 0;
         @list_stack = ();
         push @out, $self->_convert_atx_heading($line);
         $prev_was_para = 0;
         $i++;
         next;
      }

      # --- Setext underline ---
      if (_is_setext_underline($line))
      {
         if (@para == 1)
         {
            my $heading_text = $para[0];
            @para = ();
            $flush_list->();
            $in_list    = 0;
            @list_stack = ();

            my $level  = ($line =~ m/^=+$/) ? 1 : 2;
            my $prefix = '=' x $level;

            # Extract explicit anchor
            my $explicit_anchor;
            if ($heading_text =~ s/^<a\s+(?:name|id)\s*=\s*"([^"]+)"\s*><\/a>\s*//)
            {
               $explicit_anchor = $1;
            }

            $heading_text = $self->{inline}->process($heading_text);

            if ($explicit_anchor)
            {
               push @out, "[[$explicit_anchor]]";
               $self->{refs}->register_heading($explicit_anchor, $heading_text);
            }
            elsif ($self->{options}{auto_ids})
            {
               my $id = $self->{refs}->generate_id($heading_text);
               push @out, "[[$id]]";
               $self->{refs}->register_heading($id, $heading_text);
            }

            push @out, $prefix . ' ' . $heading_text;
            $prev_was_para = 0;
            $i++;
            next;
         }
      }

      # --- Paragraph line ---
      push @para, $line;
      $prev_was_para = 1;
      $i++;
   }

   $flush_para->();
   $flush_list->();

   return join("\n\n", @out);
}

#===========================================================================
# Wrap mode
#===========================================================================

sub _apply_wrap
{
   my ($text, $mode) = @_;

   return $text if (!$mode || $mode eq 'preserve');

   # Split the output into blocks separated by blank lines, then process
   # each block.  Blocks that are inside a verbatim delimiter (----, ....,
   # ++++, ////) are passed through unchanged.  All other blocks have their
   # lines joined and optionally re-broken according to $mode.

   my @lines  = split /\n/, $text, -1;
   my @result;

   # Delimiters that open/close verbatim regions (exact-match on trimmed line)
   my %verbatim_open = map { $_ => 1 } qw(---- .... ++++ ////);

   my $in_verbatim   = 0;
   my $verbatim_delim = '';

   my @para_buf;    # accumulates lines of the current paragraph block

   my $flush_para = sub {
      return unless @para_buf;

      # Check whether this "paragraph" is actually a non-wrappable structural
      # line (heading, list marker, attribute list, block title, admonition,
      # thematic break, table row, etc.).  We only wrap plain prose paragraphs.
      my $first = $para_buf[0];
      my $is_structural =
           $first =~ m/^=+ /          # heading
        || $first =~ m/^\[/           # attribute list / admonition label
        || $first =~ m/^[*.]+ /       # list item
        || $first =~ m/^\|/           # table row
        || $first =~ m/^'{3}/         # thematic break
        || $first =~ m/^:[\w]/        # document attribute
        || $first =~ m/^[A-Z]+: /     # admonition paragraph (NOTE: ...)
        || $first =~ m/^\+$/          # list continuation marker
        || $first =~ m/^={4}/         # admonition block delimiter
        || $first =~ m/^_{4}/         # quote block delimiter
        || $first =~ m/^\/\/ /        # single-line comment
        ;

      if ($is_structural || @para_buf == 1 && $para_buf[0] eq '')
      {
         push @result, @para_buf;
      }
      else
      {
         # Wrap the paragraph lines
         # First, split on hard-break markers (' +') to preserve them
         my @segments;
         my @cur_seg;
         for my $pl (@para_buf)
         {
            if ($pl =~ m/ \+$/)
            {
               push @cur_seg, $pl;
               push @segments, [@cur_seg];
               @cur_seg = ();
            }
            else
            {
               push @cur_seg, $pl;
            }
         }
         push @segments, [@cur_seg] if @cur_seg;

         my @wrapped_lines;
         for my $seg (@segments)
         {
            # Join segment lines into one string
            my $joined = join(' ', @$seg);
            $joined =~ s/ \+$//;    # remove trailing hard-break marker before join

            if ($mode eq 'none')
            {
               push @wrapped_lines, $joined;
            }
            elsif ($mode eq 'ventilate')
            {
               # Re-break after sentence-ending punctuation followed by space
               $joined =~ s/([.?!;]) +(?=\S)/$1\n/g;
               push @wrapped_lines, split(/\n/, $joined);
            }
            else
            {
               push @wrapped_lines, split(/\n/, $joined);
            }

            # Re-attach hard-break marker to last line of segment if original had one
            if ($seg->[-1] =~ m/ \+$/ && @wrapped_lines)
            {
               $wrapped_lines[-1] .= ' +' unless $wrapped_lines[-1] =~ m/ \+$/;
            }
         }

         push @result, @wrapped_lines;
      }

      @para_buf = ();
   };

   for my $line (@lines)
   {
      # Track verbatim block delimiters
      my $trimmed = $line;
      $trimmed =~ s/\s+$//;

      if (!$in_verbatim && $verbatim_open{$trimmed})
      {
         $flush_para->();
         $in_verbatim    = 1;
         $verbatim_delim = $trimmed;
         push @result, $line;
         next;
      }

      if ($in_verbatim)
      {
         push @result, $line;
         if ($trimmed eq $verbatim_delim)
         {
            $in_verbatim    = 0;
            $verbatim_delim = '';
         }
         next;
      }

      # Blank line: flush current paragraph, emit blank
      if ($trimmed eq '')
      {
         $flush_para->();
         push @result, '';
         next;
      }

      push @para_buf, $line;
   }

   $flush_para->();

   return join("\n", @result);
}

1;

__END__

=head1 NAME

Text::MarkdownAdoc::Parser - Markdown-to-AsciiDoc block-level parser

=head1 DESCRIPTION

Line-oriented state machine that performs block-level conversion of
Markdown to AsciiDoc.  Delegates inline processing to
L<Text::MarkdownAdoc::Inline> and ID/xref tracking to
L<Text::MarkdownAdoc::Refs>.

=head1 AUTHOR

Sandor Patocs

=head1 SEE ALSO

L<Text::MarkdownAdoc>, L<Text::MarkdownAdoc::Inline>,
L<Text::MarkdownAdoc::Refs>

=cut
