package Text::AsciidocDown::Parser;

use strict;
use warnings;

our $VERSION = '0.1.0';

use Text::AsciidocDown::Subs ();
use Text::AsciidocDown::Refs ();

my %THEMATIC_BREAKS = map { $_ => 1 } (q{'''}, '***', '---');
my %DELIMITERS = map { $_ => 1 } qw(---- .... ++++ ____ ==== **** --);
my %ADMON_TYPES = map { $_ => 1 } qw(NOTE TIP IMPORTANT WARNING CAUTION);

my $ATTR_ENTRY_RX = qr/^:([^:-][^:]*):(?:\s(.*))?$/;
my $AUTHOR_LINE_RX = qr/^(?:[[:alnum:]_]+(?: +[[:alnum:]_]+){0,2}(?: +<[^>]+>)?(?:; |$))+$/;
my $REVISION_LINE_RX = qr/^v(\d+(?:[-.]\w+)*)(?:, (\d+-\d+-\d+))?$|^(\d+-\d+-\d+)$/;

sub convert {
  my ($text, $opts) = @_;

  $text = '' unless defined $text;
  $opts ||= {};

  my $attributes = $opts->{attributes};
  $attributes = {} unless ref($attributes) eq 'HASH';

  my $ctx = {
    attributes => Text::AsciidocDown::Subs::build_attributes($attributes),
    refs => Text::AsciidocDown::Refs::new_index(),
  };

  return _convert_text($text, $ctx);
}

sub _convert_text {
  my ($text, $ctx) = @_;

  $text = _normalize_input($text);
  return '' unless length $text;

  my @lines = split /\n/, $text, -1;
  pop @lines if @lines && $lines[-1] eq '';
  @lines = _preprocess_conditionals(\@lines, $ctx->{attributes});

  my @out;
  my $attrs = $ctx->{attributes};
  my $list_indent = int($attrs->{'markdown-list-indent'} || 2) || 2;

  my $in_header = (@lines && $lines[0] =~ /^=\s+/) ? 1 : 0;
  my $had_doctitle = 0;

  my ($pending_title, $pending_attr);
  my @list_stack;
  my ($qanda_mode, $qanda_counter) = (0, 0);
  my $continuation_prefix;

  LINE:
  for (my $i = 0; $i <= $#lines; $i++) {
    my $line = $lines[$i];

    if (!$had_doctitle && $line =~ /^=\s+(\S.*)$/) {
      my $title = _apply_normal_subs($1, $attrs);
      push @out, '# ' . $title;
      $attrs->{doctitle} = $title;
      Text::AsciidocDown::Refs::register_heading($ctx->{refs}, $attrs, $title, $pending_attr->{id}, $pending_attr->{reftext});
      $had_doctitle = 1;
      $pending_attr = undef;
      next LINE;
    }

    if ($in_header) {
      if ($line =~ /^\s*$/) {
        $in_header = 0;
        push @out, '';
        next LINE;
      }

      if (_consume_header_line($line, $attrs)) {
        next LINE;
      }

      $in_header = 0;
      # fall through to normal body processing for this line
    }

    if (defined $continuation_prefix) {
      if ($line =~ /^\s*$/) {
        push @out, '';
        $continuation_prefix = undef;
        next LINE;
      }
      if (_list_item_info($line, $list_indent)) {
        $continuation_prefix = undef;
      } elsif (exists $DELIMITERS{$line} || ($line =~ /^\s/)) {
        # allow block handlers below to consume with current continuation context
      } else {
        push @out, $continuation_prefix . _apply_normal_subs($line, $attrs);
        next LINE;
      }
    }

    if ($line =~ $ATTR_ENTRY_RX) {
      my ($name, $value) = ($1, defined($2) ? $2 : '');
      $attrs->{$name} = Text::AsciidocDown::Subs::substitute_attributes($value, $attrs);
      next LINE;
    }

    if ($line =~ /^\\(ifn?def::[^[]+\[.*\]|include::[^[]+\[.*\]|endif::\[\])$/) {
      push @out, $1;
      next LINE;
    }

    if ($line =~ /^\[(.+)\]$/) {
      $pending_attr = _parse_attrlist($1, $attrs);
      next LINE;
    }

    if ($line =~ /^\.(?!\.)(\S.*)$/) {
      $pending_title = $1;
      next LINE;
    }

    if (_in_list_context(\@list_stack) && $line eq '+') {
      my $depth = scalar @list_stack;
      $continuation_prefix = ' ' x ($depth * $list_indent);
      next LINE;
    }

    if ($line =~ /^include::[^[]+\[.*\]$/) {
      next LINE;
    }

    if (exists $THEMATIC_BREAKS{$line}) {
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      push @out, '---';
      @list_stack = ();
      $qanda_mode = 0;
      next LINE;
    }

    if ($line eq 'toc::[]' || $line eq '<<<') {
      next LINE;
    }

    if (my $block_img = Text::AsciidocDown::Subs::block_image_to_markdown($line, $attrs)) {
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      push @out, $block_img;
      next LINE;
    }

    if (exists $DELIMITERS{$line}) {
      my $delim = $line;
      my @content;
      my $j = $i + 1;
      while ($j <= $#lines && $lines[$j] ne $delim) {
        push @content, $lines[$j];
        $j++;
      }
      $i = $j <= $#lines ? $j : $#lines;
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      _emit_delimited_block(\@out, $delim, \@content, $pending_attr, $attrs, $continuation_prefix);
      $pending_attr = undef;
      next LINE;
    }

    if ($line eq '|===') {
      my @content;
      my $j = $i + 1;
      while ($j <= $#lines && $lines[$j] ne '|===') {
        push @content, $lines[$j];
        $j++;
      }
      $i = $j <= $#lines ? $j : $#lines;
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      _emit_table(\@out, \@content, $pending_attr, $attrs, $continuation_prefix);
      $pending_attr = undef;
      next LINE;
    }

    if ($line =~ /^\s/ && $line !~ /^\s*$/) {
      my @content = ($line);
      my $j = $i + 1;
      while ($j <= $#lines && $lines[$j] =~ /^\s/ && $lines[$j] !~ /^\s*$/) {
        push @content, $lines[$j];
        $j++;
      }
      $i = $j - 1;
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      _emit_literal_paragraph(\@out, \@content, $pending_attr, $attrs, $continuation_prefix);
      $pending_attr = undef;
      next LINE;
    }

    if (my $item = _list_item_info($line, $list_indent)) {
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      if ($item->{type} ne 'dl') {
        $qanda_mode = 0;
      } elsif (($pending_attr && (($pending_attr->{style} || '') eq 'qanda')) || $qanda_mode) {
        $qanda_mode = 1;
      }

      _update_list_stack(\@list_stack, $item->{depth}, $item->{type});
      my $indent = ' ' x (($item->{depth} - 1) * $list_indent);
      my $text = _apply_normal_subs($item->{text}, $attrs);

      if ($item->{type} eq 'ul') {
        if ($text =~ /^\[(x|\*| )\]\s*(.*)$/i) {
          my $mark = (lc($1) eq ' ') ? ' ' : 'x';
          push @out, $indent . '* [' . $mark . '] ' . $2;
        } else {
          push @out, $indent . '* ' . $text;
        }
      } elsif ($item->{type} eq 'ol') {
        push @out, $indent . '1. ' . $text;
      } elsif ($item->{type} eq 'dl') {
        my $term = _apply_normal_subs($item->{term}, $attrs);
        if ($qanda_mode) {
          $qanda_counter++;
          push @out, $indent . '1. _' . $term . '_';
        } else {
          push @out, $indent . '* **' . $term . '**';
        }
        if (defined $item->{desc} && $item->{desc} ne '') {
          my $desc = _apply_normal_subs($item->{desc}, $attrs);
          push @out, $indent . '  ' . $desc;
        }
      }
      $pending_attr = undef;
      next LINE;
    } else {
      @list_stack = () if @list_stack && $line =~ /^\s*$/;
    }

    if ($line =~ /^(={2,6})\s+(\S.*)$/) {
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      my $level = length($1);
      my $title = _apply_normal_subs($2, $attrs);
      push @out, ('#' x $level) . ' ' . $title;
      Text::AsciidocDown::Refs::register_heading($ctx->{refs}, $attrs, $title, $pending_attr->{id}, $pending_attr->{reftext});
      $pending_attr = undef;
      next LINE;
    }

    if ($line =~ /^(.*) \+$/) {
      _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
      my $mark = exists $attrs->{'markdown-line-break'} ? $attrs->{'markdown-line-break'} : q{\\};
      my $base = _apply_normal_subs($1, $attrs);
      push @out, $base . $mark;
      $pending_attr = undef;
      next LINE;
    }

    _emit_pending_title(\@out, \$pending_title, \$pending_attr, $attrs);
    push @out, _apply_normal_subs($line, $attrs);
  }

  my $output = _normalize_output(join("\n", @out), $ctx);
  return Text::AsciidocDown::Refs::rewrite_links($ctx->{refs}, $output);
}

sub _preprocess_conditionals {
  my ($lines, $attrs) = @_;
  my @out;
  my @stack;

  for my $line (@{$lines}) {
    if (!_stack_blocks(\@stack) && $line =~ $ATTR_ENTRY_RX) {
      my ($name, $value) = ($1, defined($2) ? $2 : '');
      $attrs->{$name} = Text::AsciidocDown::Subs::substitute_attributes($value, $attrs);
    }

    if ($line =~ /^\\(ifn?def::[^[]+\[.*\]|include::[^[]+\[.*\]|endif::\[\])$/) {
      push @out, $line;
      next;
    }

    if ($line =~ /^if(n)?def::([^[]+)\[(.*)\]$/) {
      my ($neg, $name, $body) = ($1, $2, $3);
      my $is_set = exists $attrs->{$name};
      my $take = $neg ? !$is_set : $is_set;
      if ($body ne '') {
        push @out, $body if $take && !_stack_blocks(\@stack);
      } else {
        push @stack, $take ? 1 : 0;
      }
      next;
    }

    if ($line eq 'endif::[]') {
      if (@stack) {
        pop @stack;
      } else {
        push @out, $line;
      }
      next;
    }

    next if _stack_blocks(\@stack);
    push @out, $line;
  }

  return @out;
}

sub _stack_blocks {
  my ($stack) = @_;
  for my $flag (@{$stack}) {
    return 1 unless $flag;
  }
  return 0;
}

sub _emit_delimited_block {
  my ($out, $delim, $content, $meta, $attrs, $prefix) = @_;
  $meta ||= {};

  if ($delim eq '++++') {
    for my $line (@{$content}) {
      push @{$out}, defined($prefix) ? ($prefix . $line) : $line;
    }
    return;
  }

  if ($delim eq '____') {
    for my $line (@{$content}) {
      my $txt = $line eq '' ? '' : _apply_normal_subs($line, $attrs);
      push @{$out}, (defined($prefix) ? $prefix : '') . '> ' . $txt;
    }
    return;
  }

  if ($delim eq '====' && exists $ADMON_TYPES{uc($meta->{style} || '')}) {
    my $kind = uc($meta->{style});
    if (@{$content}) {
      my $first = _apply_normal_subs($content->[0], $attrs);
      push @{$out}, (defined($prefix) ? $prefix : '') . '**' . $kind . ':** ' . $first;
      for my $i (1 .. $#{$content}) {
        push @{$out}, (defined($prefix) ? $prefix : '') . _apply_normal_subs($content->[$i], $attrs);
      }
    } else {
      push @{$out}, (defined($prefix) ? $prefix : '') . '**' . $kind . ':**';
    }
    return;
  }

  if ($delim eq '----' || $delim eq '....' || (($meta->{style} || '') eq 'source') || (($meta->{style} || '') eq 'listing') || (($meta->{style} || '') eq 'literal')) {
    my $lang = '';
    if (($meta->{style} || '') eq 'source') {
      $lang = $meta->{lang} || ($attrs->{'source-language'} || '');
    }
    my $seq = 1;
    my @lines = @{$content};
    @lines = _outdent_lines(\@lines) if (($meta->{indent} || '') eq '0');
    push @{$out}, (defined($prefix) ? $prefix : '') . '```' . $lang;
    for my $line (@lines) {
      my $txt = _apply_verbatim_subs($line, $meta, $attrs, \$seq);
      push @{$out}, (defined($prefix) ? $prefix : '') . $txt;
    }
    push @{$out}, (defined($prefix) ? $prefix : '') . '```';
    return;
  }

  # Open/example/sidebar and unknown container: unwrap delimiters and keep content.
  for my $line (@{$content}) {
    push @{$out}, (defined($prefix) ? $prefix : '') . _apply_normal_subs($line, $attrs);
  }
}

sub _emit_literal_paragraph {
  my ($out, $content, $meta, $attrs, $prefix) = @_;
  $meta ||= {};
  my @lines = map { my $x = $_; $x =~ s/^\s//; $x } @{$content};
  @lines = _outdent_lines(\@lines) if (($meta->{indent} || '') eq '0');
  my $lang = ($lines[0] // '') =~ /^\$\s/ ? 'console' : '';
  my $seq = 1;

  push @{$out}, (defined($prefix) ? $prefix : '') . '```' . $lang;
  for my $line (@lines) {
    my $txt = _apply_verbatim_subs($line, $meta, $attrs, \$seq);
    push @{$out}, (defined($prefix) ? $prefix : '') . $txt;
  }
  push @{$out}, (defined($prefix) ? $prefix : '') . '```';
}

sub _apply_verbatim_subs {
  my ($line, $meta, $attrs, $seq_ref) = @_;
  $line = Text::AsciidocDown::Subs::substitute_attributes($line, $attrs)
    if $meta->{subs_attributes};
  $line =~ s/<([.]|1?\d)>/_render_conum($1, $seq_ref)/ge;
  return $line;
}

sub _render_conum {
  my ($token, $seq_ref) = @_;
  my $n = $token eq '.' ? $$seq_ref++ : int($token);
  return _circled_num($n);
}

sub _circled_num {
  my ($n) = @_;
  return '(' . $n . ')' if $n < 1 || $n > 20;
  return chr(0x2460 + ($n - 1));
}

sub _outdent_lines {
  my ($lines) = @_;
  my $min = undef;
  for my $line (@{$lines}) {
    next if $line =~ /^\s*$/;
    my ($lead) = $line =~ /^(\s*)/;
    my $len = length($lead || '');
    $min = $len if !defined($min) || $len < $min;
  }
  return @{$lines} unless defined $min && $min > 0;
  return map { my $x = $_; $x =~ s/^\s{0,$min}//; $x } @{$lines};
}

sub _emit_pending_title {
  my ($out, $title_ref, $meta_ref, $attrs) = @_;
  return unless defined $$title_ref;
  my $meta = $$meta_ref || {};
  my $title = _apply_normal_subs($$title_ref, $attrs);
  my $anchor = defined($meta->{id}) ? '<a name="' . $meta->{id} . '"></a>' : '';
  push @{$out}, $anchor . '**' . $title . '**';
  push @{$out}, '' if @{$out} && $out->[-1] ne '';
  $$title_ref = undef;
}

sub _emit_table {
  my ($out, $content, $meta, $attrs, $prefix) = @_;
  $meta ||= {};
  my ($cols, $aligns) = _parse_cols_spec($meta->{cols});

  my @rows;
  my @pending_cells;
  for my $line (@{$content}) {
    next if $line =~ /^\s*$/;
    if ($line =~ /^\|/) {
      my @cells = split /\|/, $line;
      shift @cells;
      @cells = map { _normalize_cell($_) } @cells;
      if ($cols) {
        push @pending_cells, @cells;
        while (@pending_cells >= $cols) {
          my @row = splice @pending_cells, 0, $cols;
          push @rows, \@row;
        }
      } else {
        push @rows, \@cells;
      }
    } elsif (@rows) {
      $rows[-1][-1] .= ' ' . _normalize_cell($line);
    }
  }

  if ($cols && @pending_cells) {
    push @pending_cells, ('') x ($cols - @pending_cells) if @pending_cells < $cols;
    push @rows, [ splice @pending_cells, 0, $cols ];
  }
  return unless @rows;

  $cols ||= _max_cols(\@rows);
  for my $r (@rows) {
    push @{$r}, ('') x ($cols - @{$r}) if @{$r} < $cols;
    $#$r = $cols - 1 if @{$r} > $cols;
  }

  my $header = $meta->{'header-option'} ? 1 : ($meta->{'noheader-option'} ? 0 : 1);
  my @body = @rows;
  my @head = $header ? @{shift @body} : (('') x $cols);

  my @div;
  for my $i (0 .. $cols - 1) {
    my $al = ($aligns->[$i] // '');
    push @div, $al eq '<' ? ':--' : $al eq '^' ? ':-:' : $al eq '>' ? '--:' : '---';
  }

  my $p = defined($prefix) ? $prefix : '';
  push @{$out}, $p . '| ' . join(' | ', map { _apply_normal_subs($_, $attrs) } @head) . ' |';
  push @{$out}, $p . '| ' . join(' | ', @div) . ' |';
  for my $r (@body) {
    push @{$out}, $p . '| ' . join(' | ', map { _apply_normal_subs($_, $attrs) } @{$r}) . ' |';
  }
}

sub _normalize_cell {
  my ($cell) = @_;
  $cell //= '';
  $cell =~ s/^\s+|\s+$//g;
  $cell =~ s/^[<>^.]?[a-z]?\|?\s*//;
  return $cell;
}

sub _max_cols {
  my ($rows) = @_;
  my $max = 0;
  for my $r (@{$rows}) {
    $max = @{$r} if @{$r} > $max;
  }
  return $max || 1;
}

sub _parse_cols_spec {
  my ($raw) = @_;
  return (0, []) unless defined $raw && $raw ne '';

  my @tokens = split /[,;]/, $raw;
  my @aligns;
  for my $tok (@tokens) {
    $tok =~ s/^\s+|\s+$//g;
    next if $tok eq '';
    my $rep = 1;
    if ($tok =~ /^(\d+)\*(.*)$/) {
      $rep = int($1);
      $tok = $2;
    }
    my ($al) = $tok =~ /([<>^])/;
    $al ||= '';
    push @aligns, (($al) x $rep);
  }

  return (scalar(@aligns), \@aligns);
}

sub _parse_attrlist {
  my ($raw, $attrs) = @_;
  my %meta;

  if ($raw =~ /cols="([^"]+)"/) {
    $meta{cols} = Text::AsciidocDown::Subs::substitute_attributes($1, $attrs);
  }
  if ($raw =~ /reftext="([^"]+)"/) {
    $meta{reftext} = Text::AsciidocDown::Subs::substitute_attributes($1, $attrs);
  }

  my @parts = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /,/, $raw;
  my @pos;

  for my $p (@parts) {
    next unless length $p;
    if ($p =~ /^#([A-Za-z_][A-Za-z0-9_\-:.]*)$/) {
      $meta{id} = $1;
    } elsif ($p =~ /^([A-Za-z0-9_-]+)=(.*)$/) {
      my ($k, $v) = ($1, $2);
      next if $k eq 'cols' && exists $meta{cols};
      $v =~ s/^"|"$//g;
      $v = Text::AsciidocDown::Subs::substitute_attributes($v, $attrs);
      $meta{$k} = $v;
      $meta{subs_attributes} = 1 if $k eq 'subs' && $v =~ /attributes/;
      $meta{indent} = $v if $k eq 'indent';
    } else {
      if ($p =~ /^%([A-Za-z0-9_-]+)$/) {
        $meta{$1 . '-option'} = 1;
        next;
      }
      push @pos, $p;
      $meta{id} = $1 if $p =~ /^#([A-Za-z_][A-Za-z0-9_\-:.]*)$/;
    }
  }

  $meta{style} = $pos[0] if @pos;
  $meta{lang} = $pos[1] if ($meta{style} || '') eq 'source' && defined $pos[1] && $pos[1] ne '';
  return \%meta;
}

sub _list_item_info {
  my ($line, $list_indent) = @_;
  my ($spaces, $rest) = $line =~ /^(\s*)(.*)$/;
  my $extra = int((length($spaces || '')) / ($list_indent || 2));

  if ($rest =~ /^(\*+|-+)\s+(.+)$/) {
    return { type => 'ul', depth => length($1) + $extra, text => $2 };
  }
  if ($rest =~ /^(\.+)\s+(.+)$/) {
    return { type => 'ol', depth => length($1) + $extra, text => $2 };
  }
  if ($rest =~ /^(\d+\.)\s+(.+)$/) {
    return { type => 'ol', depth => 1 + $extra, text => $2 };
  }
  if ($rest =~ /^<(?:[1-9]|1\d|\.)>\s+(.+)$/) {
    return { type => 'ol', depth => 1 + $extra, text => $1 };
  }
  if ($rest =~ /^(?!:\s)(\S.*?)::(?:\s+(.*))?$/) {
    return { type => 'dl', depth => 1 + $extra, term => $1, desc => (defined($2) ? $2 : ''), text => $1 };
  }
  return undef;
}

sub _update_list_stack {
  my ($stack, $depth, $type) = @_;
  $depth = 1 if $depth < 1;
  $#$stack = $depth - 1 if @{$stack} > $depth;
  $stack->[$depth - 1] = $type;
}

sub _in_list_context {
  my ($stack) = @_;
  return scalar @{$stack} > 0;
}

sub _consume_header_line {
  my ($line, $attrs) = @_;

  if ($line =~ $ATTR_ENTRY_RX) {
    my ($name, $value) = ($1, defined($2) ? $2 : '');
    $attrs->{$name} = Text::AsciidocDown::Subs::substitute_attributes($value, $attrs);
    return 1;
  }

  if (!exists $attrs->{author} && $line =~ $AUTHOR_LINE_RX) {
    my @authors = map { s/\s*<[^>]+>\s*\z//r } split /;\s*/, $line;
    $attrs->{author} = $authors[0] if @authors;
    $attrs->{authors} = join(', ', @authors) if @authors;
    return 1;
  }

  if (!exists $attrs->{revnumber} && !exists $attrs->{revdate} && $line =~ $REVISION_LINE_RX) {
    my ($revnumber, $revdate1, $revdate2) = ($1, $2, $3);
    $attrs->{revnumber} = $revnumber if defined $revnumber;
    $attrs->{revdate} = defined($revdate1) ? $revdate1 : $revdate2 if defined($revdate1) || defined($revdate2);
    return 1;
  }

  return 0;
}

sub _apply_normal_subs {
  my ($line, $attrs) = @_;
  return Text::AsciidocDown::Subs::apply_normal_subs($line, $attrs);
}

sub _normalize_input {
  my ($text) = @_;
  $text = '' unless defined $text;
  $text =~ s/\r\n?/\n/g;
  return $text;
}

sub _normalize_output {
  my ($text, undef) = @_;

  $text =~ s/\r\n?/\n/g;
  $text =~ s/[ \t]+$//mg;
  $text =~ s/\n{3,}/\n\n/g;
  $text =~ s/\A(?:\n)+//;
  $text =~ s/(?:\n)+\z//;

  return $text;
}

1;

__END__

=head1 NAME

Text::AsciidocDown::Parser - AsciiDoc-to-Markdown parser engine

=head1 SYNOPSIS

  use Text::AsciidocDown::Parser;

  my $markdown = Text::AsciidocDown::Parser::convert($asciidoc, \%opts);

=head1 DESCRIPTION

This module implements the core AsciiDoc-to-Markdown conversion logic for
Text::AsciidocDown. It is not intended for direct use; callers should use
the OO interface provided by L<Text::AsciidocDown>.

=head1 INTERFACE

=head2 convert

  my $markdown = Text::AsciidocDown::Parser::convert($asciidoc, \%opts);

Converts AsciiDoc text to Markdown.

B<Options:>

=over 4

=item C<attributes> - HashRef of AsciiDoc attributes for substitution

=back

Returns the converted Markdown string.

=head1 SUPPORTED FEATURES

=over 4

=item * Document title (C<= Level 0 Heading>)

=item * Section headings (C<==> through C<======>)

=item * Attribute entries (C<:name: value>)

=item * Header lines (author, revision)

=item * Conditional preprocessing (C<ifdef::[]>, C<ifndef::[]>, C<endif::[]>)

=item * Unordered lists (C<*>, C<->)

=item * Ordered lists (C<.>, C<1.>)

=item * Description lists (C<term:: description>)

=item * Q&A lists (qanda style)

=item * Code blocks (C<---->, C<....>)

=item * Literal paragraphs (indented)

=item * Quote blocks (C<____>)

=item * Admonition blocks (NOTE, TIP, IMPORTANT, WARNING, CAUTION)

=item * Passthrough blocks (C<++++>)

=item * Tables (C<|===>)

=item * Thematic breaks (C<'''>, C<***>, C<--->)

=item * Block images (C<image::[]>)

=item * TOC and page break directives

=back

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

Same terms as Perl itself.

=cut