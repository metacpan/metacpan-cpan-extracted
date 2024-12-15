 strict; use warnings FATAL => 'all';
use v5.20; # signatures
no warnings "experimental::lexical_subs";
use feature qw/say state lexical_subs/;
use utf8;
# vi:set ai expandtab ts=4:

# Based on code in the Text::Table documentation and
# https://stackoverflow.com/questions/30762521/how-can-i-print-a-table-with-multi-line-strings-using-the-texttable-module

package Text::Table::Boxed;
require Text::Table; # old versions of 'base' don't auto-require?
use base 'Text::Table';

{ no strict 'refs'; ${__PACKAGE__."::VER"."SION"} = 997.999; }
our $VERSION = '1.003'; # VERSION from Dist::Zilla::Plugin::OurPkgVersion
our $DATE = '2024-12-14'; # DATE from Dist::Zilla::Plugin::OurDate

use Carp;
use Scalar::Util qw/reftype/;
use List::Util qw/min max first all any/;
use List::MoreUtils qw/true false none firstidx/;

use overload (
    bool => sub { return 1; }, # Don't stringify just for a boolean test
    '""' => 'rendered_stringify',
);

use Data::Dumper::Interp 7.010 qw/visnew ivis dvis vis avis u/;

use warnings::register;  # creates category name same as __PACKAGE__

sub btw  { goto &Data::Dumper::Interp::btw }
sub btwN { goto &Data::Dumper::Interp::btwN }
sub oops { @_ = ("OOPS:",@_); goto &Carp::confess }

our $debug = 0;

our %builtin_pictures = (

ascii => <<'EOF',
+-------+
| c | c |
+=======+
| c | c |
+---+---+
| c | c |
+-------+
EOF

boxrule => <<'EOF',
┌───┬───┐
│ c │ c │
╞═══╪═══╡
│ c │ c │
├───┼───┤
│ c │ c │
└───┴───┘
EOF

outerbox => <<'EOF',
┌─────┐
│ c c │
│ c c │
│ c c │
└─────┘
EOF

);

sub _handle_rulepicture($) {
  my $opts = shift;
  $opts->{CONTENT_CHAR} //= 'c';

  # Get separate line strings sans final newline
  my @lines;
  if (ref($opts->{picture}) eq 'ARRAY') {
    @lines = @{ $opts->{picture} };
    foreach(@lines) { s/\R\z//; }
  } else {
    @lines = split /\R/, ($opts->{picture} // oops);
  }

  if ($debug) { btw "--- INPUT PICRURE ---\n",(map{ "$_\n" } @lines),"---(end)---\n"; }

  croak "The 'picture' contains only ",scalar(@lines)," line.\n",
        "Please provide two or more lines either as an array\n",
        "    [\"line1\", \"line2\", ... ]\n",
        "or a plain multi-line string\n",
        "    \"line1\\nline2\\n...\"\n"
    if @lines < 2;

  my sub _is_sepspec($) { $_[0] =~ /$opts->{CONTENT_CHAR}/ }
  my sub _is_rule($)    { ! _is_sepspec($_[0]) }
  my $first_rulespec;
  my sub _push_rule($$) {
    my ($aref, $spec) = @_;
    croak "Rule lines must have the same length\n"
      unless length($first_rulespec//=$spec) == length($spec);
    state $warned_once;
    if ($spec =~ /( [a-z] )/ && !$warned_once++ && warnings::enabled()) {
      carp "A rule line contains an isolated letter '$1' which is not the letter '$opts->{CONTENT_CHAR}' used as a stand-in for cell content.  Was '$opts->{CONTENT_CHAR}' intended?\n";
    }
    push @$aref, $spec;
  }

  my (@top_rule, @mid_rule, @bot_rule);

  # Collect all rule strings (will later be split into segments)
  if (_is_rule($lines[-1])) {
    _push_rule(\@bot_rule, pop @lines);
  }
  if (_is_rule($lines[0])) {
    _push_rule(\@top_rule, shift @lines);
  }
  croak "There must be at least one 'data line' in the picture\n" unless @lines;
  foreach (@lines) {
    _push_rule(\@mid_rule, $_) if _is_rule($_);
  }

  my ($sepspec_line, @sepsegs);
  foreach (@lines) {
    next if _is_rule($_);

    if (defined $sepspec_line) {
      croak "All separator-sepc lines in the picture must be identical\n",
            "(Text::Table does not support different seps in different rows)\n"
        unless $_ eq $sepspec_line;
    } else {
      $sepspec_line = $_;
      # Isolate separators and content-standin-chars
      # e.g. ("| ", 'c', " | ", 'c', " |")
      # or   ("",   'c', " | ", 'c', ""  ) if no edge-separators
      pos=undef;
      # split will provide the empty ("") segment we want where there is no
      # edge separator (that, if CONTENT_CHAR is the first or last char).
      # Note that the CONTENT_CHAR is in a (capture group) so is included
      # as an element in the resultin list.
      @sepsegs = split /($opts->{CONTENT_CHAR})/, $_, -1;
      # Split rule strings at the same positions
      foreach (@top_rule, @mid_rule, @bot_rule) {
        my @rulesegs;
        for (my $off=0, my $ix=0; $ix <= $#sepsegs; ) {
          push @rulesegs, substr($_, $off, length($sepsegs[$ix]));
          $off += length($sepsegs[$ix]);
          ++$ix;
        }
        $_ = \@rulesegs;
      }
    }
  }
  # Now rules are represented as [ list of substrings ]
  # and "data" rows (which must be identical) similarly in @sepsegs
  oops unless all{ scalar(@$_) == @sepsegs } @top_rule, @mid_rule, @bot_rule;

  my $num_cols = @{ $opts->{columns} };
  my $pic_cols = int(@sepsegs/2);
btw dvis 'BEFORE PIC-LEN-ADJ: $num_cols $pic_cols @sepsegs\n@top_rule\n@mid_rule\n@bot_rule' if $debug;
  # Replicate the last picture column if the actual data is wider
  # Delete the last picture column if the actual data is narrower
  while ($num_cols != $pic_cols) {
    # ("|-", '-', "+++", '+', "-|")  # a rule
    # ("| ", 'c', " | ", 'c', " |")  # sepsegs
    #             ^^^^^^^^^^ #replicate or delete these
    #             $#-2   $#-1  $#
    if ($pic_cols < $num_cols) {
      croak "Picture must have at least two columns\n"
        if $pic_cols < 2; # no separator to replicate
      foreach (\@sepsegs, @top_rule, @mid_rule, @bot_rule) {
        splice @$_, $#$_, 0, @$_[$#$_-2..$#$_-1];
      }
      ++$pic_cols;
    } else {
      foreach (\@sepsegs, @top_rule, @mid_rule, @bot_rule) {
        splice @$_, $#$_-2, 2
      }
      --$pic_cols;
    }
  }

btw dvis 'AFTER  PIC-LEN-ADJ: @sepsegs\n@top_rule\n@mid_rule\n@bot_rule' if $debug;

  # Insert the separators among the column titles
  # The last separator always goes on the right edge (possibly "").
  my @withseps = map{
    ( \( $sepsegs[$_*2] // oops ), $opts->{columns}->[$_] )
  } 0..$#{$opts->{columns}};
  push @withseps, \$sepsegs[-1];

  # RULE GENERATORS
  # Each rule generator uses a pair of callbacks, herein called the "field"
  # and "separator" callbacks,  Each provides characters to put into a rule
  # line which will be under/over a field or separator string, respectively.
  # The arguments to the callback are ($index, $num_chars).
  #
  # For the "field callback", $index counts *fields*.
  #
  # For the "separator callback", $index is not useful due to this bug:
  # https://github.com/shlomif/Text-Table/issues/14 .
  # However the callbacks step through all the characters in the separators
  # left-to-right (sometimes multiple characters at once), so a state variable
  # can be used to know the next horizontal position.  $index is used
  # only to recognize the initial call ($index==0) and reset the state.
  #
  for my $key (qw/top_rule mid_rule bot_rule/) {
    $opts->{$key} = [];
    foreach my $rule_segs (eval "\@$key") { die $@ if $@;
      # Rule and "data" lines in the picture have been split into arrays
      # of pieces corresponding to separators and CONTENT_CHAR characters.
      # A "field" rule segment is recognizable because the corresponding
      # element in @sepsegs is the CONTENT_CHAR.
      my $field_chars = "";
      my $sep_chars = "";
      oops unless @$rule_segs == @sepsegs;
      for my $ix (0..$#$rule_segs) {
        if ($sepsegs[$ix] eq $opts->{CONTENT_CHAR}) {
          $field_chars .= $rule_segs->[$ix];
        } else {
          $sep_chars .= $rule_segs->[$ix];
        }
      }
btw dvis 'xxxx $key $field_chars $sep_chars $rule_segs @sepsegs\n       @withseps' if $debug;
      oops unless length($field_chars) == $num_cols;
      my $field_callback = sub {
          my ($index, $len) = @_;
          my $char = substr($field_chars,$index,1);
          my $str = $char x $len;
          warn "-fld- [$index] len=$len returning '$str'\n" if $debug;
          return $str;
      };
      my $separator_callback = sub {
          my ($index, $len) = @_;
          state $char_ix;
          $char_ix = 0 if $index==0;
          my $str = substr($sep_chars, $char_ix, $len);
          $char_ix += $len;
          warn "=SEP= [$index] len=$len returning '$str'\n" if $debug;
          oops dvis '$sep_chars $index $len $str $char_ix'
            unless length($str) == $len;
          return $str;
      };
      # Save the subrefs and debug info
      push @{ $opts->{$key} }, {
        sub1 => $field_callback,
        sub2 => $separator_callback,
        sep_chars => $sep_chars,
        field_chars => $field_chars,
      };
    }
  }
  $opts->{withseps} = \@withseps;
}#_handle_rulepicture

use constant MYKEY => "_key_".__PACKAGE__;
sub new {
  my $class = shift;
  my %opts = (@_==1 && ref($_[0]) eq "HASH" && exists($_[0]->{columns}))
      ? %{ shift(@_) }       # new API
      : ( columns => [@_] ); # old API

  foreach (keys %opts) {
    croak "Invalid option key '$_'\n" unless /^(?:columns|picture|style)$/;
  }

  croak "'columns' must be provided in OPTIONS\n"
    unless defined ($opts{columns});
  croak "'columns' must be an array ref\n"
    unless reftype($opts{columns}) eq "ARRAY";

  $opts{picture} //= $builtin_pictures{ascii};  # the default

  if (defined $opts{style}) {
      $opts{picture} = $builtin_pictures{ $opts{style} }
        // croak "Invalid 'style' \"$opts{style}\"\n";
      delete $opts{CONTENT_CHAR};
  }

  # Parse the picture.
  # Creates {withseps} and {rule_generators} in %opts
  _handle_rulepicture(\%opts);

  my $self = Text::Table::new(__PACKAGE__, @{ $opts{withseps} });

  $opts{row_starts} = [ 0 ];
  $opts{next_rx} = $self->title_height;

  $self->{MYKEY()} = \%opts;
  $self
}#new

sub _TTBrule {
  my ($key, $self, $ix) = @_;
  $ix //= 0;
  return undef
    unless my $list = $self->{MYKEY()}->{"${key}_rule"};
  $list = [ $list ] unless ref($list) eq "ARRAY"; # [ {...}, ... ]
  return undef
    if $#$list == -1; # _no_ mid rules at all
  # If asking for a higher index than exists, re-use the last one.
  # This is appropriate for multiple mid_rules.
  my $h = $ix > $#$list ? $list->[-1] : $list->[$ix];
  my $r = $self->rule($h->{sub1}, $h->{sub2});
  $r
}

sub top_rule { _TTBrule("top", @_) }
sub mid_rule { _TTBrule("mid", @_) }  # takes optional index argument
sub bot_rule { _TTBrule("bot", @_) }

sub num_rows { scalar @{ $_[0]->{MYKEY()}->{row_starts} } }

sub num_body_rows { $_[0]->num_rows() - 1 }

sub rendered_table_height {
    my $self = shift;
    my $opts = $self->{MYKEY()};
    return(
        scalar(@{$opts->{top_rule}})  # 1 or 0 if no top rule

      + $self->table_height()         # data lines

      # Rules after rows.
      # All but the last row are followed by a mid_rule, iff defined.
      # The last row is followed by bot_rule, iff defined.
      + (@{$opts->{mid_rule}} ? ($self->num_rows-1) : 0)

      + scalar(@{$opts->{bot_rule}})  # 1 or 0 if no bot rule
    );
}

sub add {
    my $self = shift;
    my $opts = $self->{MYKEY()};

    # Calculate height of the row, taking into account embedded newlines
    # (which Text::Table will split, inserting multiple lines)
    my $height = 1;
    foreach (@_) {
      $height += scalar(@{[ /\R/g ]});
    }
    push @{ $opts->{row_starts} }, $self->table_height;

    $self->SUPER::add(@_);
}

sub rendered_title {
    my $self = shift;
    my @lines = grep{defined}
                  $self->top_rule(),
                  $self->title(),
                  ($self->mid_rule(0)//$self->bot_rule())
                ;
    return (wantarray ? @lines : join("", @lines));
}

sub rows {
    my ($self, $row_index, $num_rows, $_with_rules) = @_;
    $row_index //= 0;
    $num_rows //= 1;
    my $opts = $self->{MYKEY()};
    my $row_starts = $opts->{row_starts};
    croak "Negative index not supported\n" if $row_index < 0 or $num_rows < 0;
    my $max_rx = $#{ $row_starts };
    croak "Row index out of range\n"
      if $row_index+$num_rows-1 > $max_rx;

    my @results = map{
        my $first_lx = $row_starts->[$_];
        my $nextrow_first_lx =
            ($_ == $max_rx ? $self->height() : $row_starts->[$_+1]);
        my $num_lines = $nextrow_first_lx - $first_lx;

        my @lines = $self->table($first_lx, $num_lines);
        if ($_with_rules) {
          if ($_ == 0 && defined(my $str = $self->top_rule())) {
            unshift @lines, $str;
          }
          if (defined(my $str = $_==$max_rx ? $self->bot_rule()
                                            : $self->mid_rule($_))) {
            push @lines, $str;
          }
        }
        [ @lines ]
    } $row_index..$row_index+$num_rows-1;
btw dvis '##ROWS($row_index $num_rows $_with_rules) $max_rx --> @results' if $debug;

    if (wantarray) { return @results; }
    croak "Scalar context but multiple rows in results\n"
      if @results > 1;
    return $results[0];
}#rows

sub body_rows {
    my ($self, $row_index, $num_rows, $_with_rules) = @_;
    $self->rows($row_index+1, $num_rows, $_with_rules);
}
sub rendered_body_rows {
    my ($self, $row_index, $num_rows) = @_;
    return $self->body_rows($row_index, $num_rows, 1);
}

sub title_row {
    my ($self, $_with_rules) = @_;
    return $self->body_rows(0, 1, $_with_rules);
}
sub rendered_title_row {
    my $self = shift;
    return $self->title_row(1);
}

sub rendered_title_height() { $_[0]->title_height() + 2 }

sub rendered_rows {
    my ($self, $row_index, $num_rows) = @_;
    return $self->rows($row_index, $num_rows, 1);
}

sub rendered_table {
    my ($self, $start_lx, $num_lines) = @_;
    my $opts = $self->{MYKEY()};
    my $row_starts = $opts->{row_starts};
    my $max_lx = $self->rendered_table_height() - 1;

    $num_lines //= ($max_lx + 1);
    $start_lx //= 0;
    croak "Negative index not supported\n" if $start_lx < 0 or $num_lines < 0;

    my $last_lx = $start_lx + $num_lines - 1;
    croak "Line index $start_lx+$num_lines-1 is out of range (max=$max_lx)\n"
      if $last_lx > $max_lx;

    # Retrieve rows and flatten result, truncating some lines if appropraite

    my $last_rx = $last_lx >= $row_starts->[-1]
                     ? $#$row_starts
                     : first{ $last_lx >= $row_starts->[$_] }
                       reverse(0..$#$row_starts-1) ;

btw dvis 'REND($start_lx, $num_lines) $row_starts $max_lx $last_lx $last_rx' if $debug;

    my $first_rx = $start_lx >= $row_starts->[$last_rx]
                     ? $last_rx
                     #: first{ $start_lx < $row_starts->[$_+1] } 0..$last_rx-1 ;
                     : first{
  #btw '##INfirst last_rx=',vis($last_rx),' $_=',vis($_);
                          $start_lx < $row_starts->[$_+1] } 0..$last_rx-1 ;

    my @lines = (
        map{ @$_ } $self->rendered_rows($first_rx, $last_rx-$first_rx+1)
    );
btw dvis '##REND.B $last_lx $start_lx $num_lines @lines' if $debug;
    splice @lines, $last_lx-$start_lx+1; # trunc undesired lines from last row

btw dvis '##REND.C @lines' if $debug;
    return (wantarray ? @lines : join("", @lines));
}#rendered_table

sub rendered_body {
    my ($self, $start_lx, $num_lines) = @_;
    return
        $self->rendered_table( $start_lx + $self->rendered_title_height(),
                               $num_lines );
}

sub rendered_stringify {
    my $self = $_[0];
    return( scalar $self->rendered_table() );
}

=pod

=encoding UTF-8

=head1 NAME

Text::Table::Boxed - Automate separators and rules for Text::Table

=head1 SYNOPSIS

    use Text::Table::Boxed;

    my $tb = Text::Table::Boxed->new({
      columns => [ "Planet", "Radius\nkm", "Density\ng/cm^3" ],
      style   => "boxrule",
    });

    $tb->load(
        [ "Mercury", 2360, 3.7 ],
        [ "Venus", 6110, 5.1 ],
        [ "Earth", 6378, 5.52 ],
        [ "Jupiter", 71030, 1.3 ],
    );

    print $tb;  # Render table including separators and rules

    # Custom rules and separators
    my $tb = Text::Table::Boxed->new({
      columns => [ "Planet", "Radius\nkm", "Density\ng/cm^3" ],
      picture => <<'EOF',
    ┌───╥───┬───┐
    │ c ║ c │ c │
    ╞═══╬═══╪═══╡
    │ c ║ c │ c │
    ├───╫───┼───┤
    │ c ║ c │ c │
    ╘═══╩═══╧═══╛
    EOF
    });

    my @lines = $tb->rendered_title();  # including rules
    my @lines = $tb->rendered_table();  # including rules

    # Retrieve rows, each of which is an array of possibly-multiple lines,
    # the last of which is a rule line if appropriate.
    my $lineset  = $tb->rendered_title();
    my @linesets = $tb->rendered_body_rows($body_row_index, $num_rows);

=head1 DESCRIPTION

This wrapper for L<Text::Table> automates column separators
and horizontal rules.  Embedded newlines are allowed in cell data.

Support for ASCII or Unicode box-drawing characters is built in,
or you can give an "ascii art" picture showing what you want.

B<Text:Table::Boxed> is a derived class of Text::Table and supports all of
it's methods.
C<new> supports a different API where a single hashref argument supplies
column descriptors in a 'columns' element, along with possibly other options.

=head1 ROWS

The concept of "B<row>" is introduced, which represents a possibly-multiline
table row.  Rules are inserted only at row boundaries, not between lines
within a row.  Multi-line rows exist where cell values
contain embedded newlines.

Methods with "B<row>" in their name return lines segregated into rows, each
row represented by an array of the constituent lines.
In contrast, similar methods without "row" in their name return a flat
list of lines (or in scalar context, a single multiline string).

Methods with "B<rendered>" in their name include I<rule lines> in their
result.  For example B<rendered_table()> returns all lines in the table
including rule lines, whereas B<table()> omits rule lines.

I<Rules> are inserted only when B<rendered_*()> methods are called, however
I<separators>, i.e. characters between columns and at the edges of data rows,
are always present because they
are inserted among the original columns by 'new' and exist in the
underlying L<Text::Table> object.

=head1 OPTIONS

=over 4

=item B<columns> => [ column titles... ]

A list of column titles or descriptor hashrefs, as documented in L<Text::Table>.

Separators should not be included here.

=item B<style> => "ascii" | "boxrule"

Use a built-in set of separator and rule characters.

=item B<picture> => "Multi\nLine\nString";

=item B<picture> => [ lines ];

Specify separator and rule-line characters using a picture of what you want
(see example in the SYNOPSIS).

The letter 'c' is a stand-in for cell content; all other characters in
"data" rows are taken as separators including spaces
(typically included for padding).

"Rule" lines should be exactly what would be displayed for a table
the same size as the picture.  Portions are replicated as needed to fit
the actual table.

The picture must contain at least two columns; with more columns
different separators may be specified at various horizontal positions
(however the same separator must be used in every
data row in a given column).
The separator between the last two columns is re-used if the table has
more columns than the picture.

Similarly, the picture must contain at least two rows and
the rule between the last two rows is re-used if the actual table has more
rows than the picture.
Often pictures have three rows to allow a different separator
between the title row and the first body row.

See "PICTURE SPECIFICATIONS" for examples.

=back

=head1 ADDITIONAL PUBLIC METHODS

=head2 Status Information

=over 4

=item num_body_rows()

The number of possibly-multiline I<rows> in the body portion of the table.  See B<ROWS> above.

=item num_rows()

The total number of rows, including the title row.

=item rendered_table_height()

The number of lines in the entire title including rule lines.

=item rendered_title_height()

The number of lines in just the title I<row>, including rules before and after
(unlike B<title_height()> which only counts non-rule lines).

=back

=head2 Table Output

=over 4

=item rendered_stringify()

Returns the entire table as a single string including rule lines.
This is the same as B<rendered_table()> but returns a string even in
array context.

The object also stringifies to the same result using operator overloading.

    $string = $tb->rendererd_stringify()
    $string = $tb;  # same result

=item rendered_table()

Like C<table()> but includes rule lines.

    $line  = $tb->rendered_tables($line_index);  # one line
    @lines = $tb->rendered_tables;               # all lines
    @lines = $tb->rendered_tables($line_index, $num_tables);

Line index 0 is the top rule line (if there is one),
index 1 is the first "real" title line, etc.

=item body_rows()

=item rendered_body_rows()

Returns I<rows>, each of which is a ref to an array containing
possibly-multiple lines.  In scalar context, returns a single array ref
(valid only for a single row).
B<rendered_body_rows()> includes a rule line as the last line in each row
if an interior rule was defined in the I<picture> (it is possible to omit interior rules -- see PICTURE SPECIFICATIONS).

Row index 0 is the first body row.

    $lineset  = $tb->rendered_body_rows($row_index);  # one row
    @linesets = $tb->rendered_body_rows;              # all rows
    @linesets = $tb->rendered_body_rows($row_index, $num_rows);

=item title_row()

=item rendered_title_row()

Returns a row representation (i.e. array ref) for the title row.
This is the same as B<row(0)> or B<rendered_row(0)>.

=item rendered_title()

Like C<rendered_table()> but only returns lines from the title row,
ending with the rule line following the title.

=item rendered_body()

Returns lines from the body area of the table, including rule lines
after each row.  Row index 0 is the first line of the first body row.

=item top_rule()

=item mid_rule()

=item mid_rule($body_row_index)

=item bot_rule()

These return the corresponding rendered rule line.
You normally do not call these yourself because rules are
automatically included by the "rendered_xxx" methods

C<mid_rule()> accepts an optional index to retrieve
other than the first interior rule in the picture.

=back

=head1 PICTURE SPECIFICATIONS

Custom separators and rules are specified as a "picture" built from several
lines.  There are four kinds of rules.  All are optional:

=over 4

=item * Top rule

=item * Special "mid" rule(s) used only at the indicated position.

=item * Default "mid" rule, also used between subsequent body rows

=item * Bottom rule

=back

Pictures must have at least two rows and columns:

    ┌───┬───┐   /=======\  ⇦  top rule
    │ c │ c │   | c | c |
    ├───┼───┤   |---+---|  ⇦  default mid rule
    │ c │ c │   | c | c |
    ╘═══╧═══╛   \=======/  ⇦  bottom rule

The letter 'B<I<c>>' is a stand-in for real content. Everything
between 'B<I<c>>'s or at the edge is a separator string.

With more than two picture rows, special rules are used where indicated
among the upper rows in the table.
The last interior rule is the "default" rule, used between further rows
if there are any.  And analogously for columns:

              ⮦ Left-edge separator
              ⏐   ⮦ Special separator
              ⏐   ⏐   ⮦ Default separator
              ↓   ↓   ↓   ⮦ Right-edge separator
    ┌─╥─┬─┐   ┌───╥───┬───┐   ==============  ⇦  top rule
    │c║c│c│   │ c ║ c │ c │   | c || c | c |
    ╞═╬═╪═╡   ╞═══╬═══╪═══╡   |===++===+===|  ⇦  special rule after title
    │c║c│c│   │ c ║ c │ c │   | c || c | c |
    ┝━╋━┿━┥   ┝━━━╋━━━┿━━━┥   |___||___|___|  ⇦  special after 1st body row
    │c║c│c│   │ c ║ c │ c │   | c || c | c |
    ├─╫─┼─┤   ├───╫───┼───┤   |---++---+---|  ⇦  default rule
    │c║c│c│   │ c ║ c │ c │   | c || c | c |
    ╘═╩═╧═╛   ╘═══╩═══╧═══╛   ==============  ⇦  bottom rule

In the leftmost example, column separators are single characters
so there is no padding around content.  In the others the separators are
two or three characters each including spaces for padding, e.g. "|␠",
"␠|␠" or "␠|".

Outer borders can be omitted:

    c║c│c    c ║ c │ c     c | c | c
    ═╬═╪═   ═══╬═══╪═══   ===+===+===
    c║c│c    c ║ c │ c     c | c | c
    ─╫─┼─   ───╫───┼───   ---+---+---
    c║c│c    c ║ c │ c     c | c | c

To get only outer borders, omit the interior rules and use interior
separators containing only spaces (unless you want cells to touch):

    ┌───┐   ┌─────┐   =======
    │c c│   │ c c │   | c c |
    │c c│   │ c c │   | c c |
    │c c│   │ c c │   | c c |
    ╘═══╛   ╘═════╛   =======

B<RENDERING EXAMPLES>

If there are more actual rows and/or columns than in the picture,
the "default" rule and/or column separator is repeated:

    Picture    Rendered Actual Table
    ┌─╥─┬─┐    ┌──────╥─────┬──────────┬────────────┐ ⇦  top rule
    │c║c│c│    │ NAME ║ AC  │ NUMBER   │ Pet's Name │
    ╞═╬═╪═╡    ╞══════╬═════╪══════════╪════════════╡ ⇦  special rule
    │c║c│c│    │ Sam  ║ 800 │ 555-1212 │  Cutesy    │
    ├─╫─┼─┤    ├──────╫─────┼──────────┼────────────┤ ⇦  default rule
    │c║c│c│    │ Mary ║ 880 │ 123-4567 │  Killer    │
    ╘═╩═╧═╛    ├──────╫─────┼──────────┼────────────┤ ⇦  default rule
               │ Don  ║ 880 │ 123-4567 │  Tweetie   │
               ├──────╫─────┼──────────┼────────────┤ ⇦  default rule
               │ Mico ║ 880 │ 123-4567 │  Tabby     │
               ╘══════╩═════╧══════════╧════════════╛ ⇦  bottom rule

The edge separators are always used, as are the top & bottom rules (if defined),
even if there are fewer rows or columns than in the picture:

    ┌───┰───┬───┐    ┌───────┐ ⇦  top rule
    │ c ║ c │ c │    │Meaning│
    ┝━━━╋━━━┿━━━┥    │of life│
    │ c ║ c │ c │    ┝━━━━━━━┥ ⇦  special after-title rule
    ├───╫───┼───┤    │  42   │
    │ c ║ c │ c │    ╘═══════╛ ⇦  bottom rule
    ╘═══╩═══╧═══╛

If there is a title row but no body rows,
only the top and bottom rules are used:

    ┌──────╥─────┬────────────┐ ⇦  top rule
    │ NAME ║ AC  │  NUMBER    │
    ╘══════╩═════╧════════════╛ ⇦  bottom rule

If there are no titles or data, nothing is rendered
e.g. the object stringifies to "".

=head1 PAGER EXAMPLE

Please see L<Text::Table::Boxed::Pager> for an example of using B<rows> to view a table on a terminal,
keeping multi-line rows together when possible.

=head1 ACKNOWLEDGMENTS

This module was inspired the example code in the Text::Table
documentation by Anno Siegel and/or Shlomi Fish, and
a post at
L<https://stackoverflow.com/questions/30762521/how-can-i-print-a-table-with-multi-line-strings-using-the-texttable-module>
by stackoverflow user "ThisSuitIsBlackNot".

=head1 BUGS

Text::Table::Boxed is new in 2024 and actively maintained.
Please report issues!

L<https://github.com/jimav/Text-Table-Boxed/issues>

=head1 AUTHOR

Jim Avera (jim.avera at gmail)

=head1 LICENSE

CC0 or Public Domain.
However your application is likely subject to the more restrictive licenses
of Text::Table and other modules.

=for Pod::Coverage add new rendered_rows rows

=for Pod::Coverage btw btwN oops

=cut
1;
