package Vote::Count::TextTableTiny;
$Vote::Count::TextTableTiny::VERSION = '2.05';
use 5.024;
use strict;
use warnings;
use utf8;
use parent 'Exporter';
use Carp                    qw/ croak /;
use Ref::Util         0.202 qw/ is_arrayref /;
use String::TtyLength 0.02  qw/ tty_width /;

our @EXPORT_OK = qw/ generate_table /;

# Legacy package globals, that can be used to customise the look.
# These are only used in the "classic" style.
# I wish I could drop them, but I don't want to break anyone's code.
our $COLUMN_SEPARATOR     = '|';
our $ROW_SEPARATOR        = '-';
our $CORNER_MARKER        = '+';
our $HEADER_ROW_SEPARATOR = '=';
our $HEADER_CORNER_MARKER = 'O';

my %arguments = (
    rows => "the rows, including a possible header row, of the table",
    header_row => "if true, indicates that the first row is a header row",
    separate_rows => "if true, a separate rule will be drawn between each row",
    top_and_tail => "if true, miss out top and bottom edges of table",
    align => "either single alignment, or an array per of alignments per col",
    style => "styling of table, one of classic, boxrule, or norule",
    indent => "indent every row of the table a certain number of spaces",
    compact => "narrow columns (no space either side of content)",
);

my %charsets = (
    classic => { TLC => '+', TT => '+', TRC => '+', HR => '-', VR => '|', FHR => '=', LT => '+', RT => '+', FLT => 'O', FRT => 'O', HC => '+', FHC => 'O', BLC => '+', BT => '+', BRC => '+' },
    boxrule => { TLC => '┌', TT => '┬', TRC => '┐', HR => '─', VR => '│', FHR => '═', LT => '├', RT => '┤', FLT => '╞', FRT => '╡', HC => '┼', FHC => '╪', BLC => '└', BT => '┴', BRC => '┘' },
    norule  => { TLC => ' ', TT => ' ', TRC => ' ', HR => ' ', VR => ' ', FHR => ' ', LT => ' ', RT => ' ', FLT => ' ', FRT => ' ', HC => ' ', FHC => ' ', BLC => ' ', BT => ' ', BRC => ' ' },
    markdown => {
      TLC => '|', TT => ' ', TRC => '|', HR => '-',
      VR => '|', FHR => ' ', LT => '|', RT => '|',
      FLT => ' ', FRT => ' ', HC => '|', FHC => ' ',
      BLC => '|', BT => ' ', BRC => '|',
    },
);

sub generate_table
{
    my %param   = @_;

    foreach my $arg (keys %param) {
        croak "unknown argument '$arg'" if not exists $arguments{$arg};
    }

    my $rows    = $param{rows} or croak "you must pass the 'rows' argument!";
    my @rows    = @$rows;
    my @widths  = _calculate_widths($rows);

    $param{style}  //= 'classic';

    $param{indent} //= '';
    $param{indent} = ' ' x $param{indent} if $param{indent} =~ /^[0-9]+$/;

    my $style   = $param{style};
    croak "unknown style '$style'" if not exists($charsets{ $style });
    my $char    = $charsets{$style};

    if ($style eq 'classic') {
        $char->{TLC} = $char->{TRC} = $char->{TT} = $char->{LT} = $char->{RT} = $char->{HC} = $char->{BLC} = $char->{BT} = $char->{BRC} = $CORNER_MARKER;
        $char->{HR}  = $ROW_SEPARATOR;
        $char->{VR}  = $COLUMN_SEPARATOR;
        $char->{FLT} = $char->{FRT} = $char->{FHC} = $HEADER_CORNER_MARKER;
        $char->{FHR} = $HEADER_ROW_SEPARATOR;
    } elsif ( $style eq 'markdown') {
      _md_validate_data( $rows );
      $param{'header_row'} = 1;
      $param{'top_and_tail'} = 1;
      $param{'separate_rows'} = 0;
      $param{'indent'} = '';
    }

    my $header;
    my @align;
    if (defined $param{align}) {
        @align = is_arrayref($param{align})
               ? @{ $param{align} }
               : ($param{align}) x int(@widths)
               ;
    }
    else {
        @align = ('l') x int(@widths);
    }

    $header = shift @rows if $param{header_row};

    my $table = _top_border(\%param, \@widths, $char)
                ._header_row(\%param, $header, \@widths, \@align, $char)
                ._header_rule(\%param, \@widths, $char, \@align)
                ._body(\%param, \@rows, \@widths, \@align, $char)
                ._bottom_border(\%param, \@widths, $char);
    chop($table);

    return $table;
}

sub _top_border
{
    my ($param, $widths, $char) = @_;

    return '' if $param->{top_and_tail};
    return _rule_row($param, $widths, $char->{TLC}, $char->{HR}, $char->{TT}, $char->{TRC});
}

sub _bottom_border
{
    my ($param, $widths, $char) = @_;

    return '' if $param->{top_and_tail};
    return _rule_row($param, $widths, $char->{BLC}, $char->{HR}, $char->{BT}, $char->{BRC});
}

sub _rule_row
{
    my ($param, $widths, $le, $hr, $cross, $re) = @_;
    my $pad = $param->{compact} ? '' : $hr;

    return $param->{indent}
           .$le
           .join($cross, map { $pad.($hr x $_).$pad } @$widths)
           .$re
           ."\n"
           ;
}

sub _header_row
{
    my ($param, $row, $widths, $align, $char) = @_;
    return '' unless $param->{header_row};

    return _text_row($param, $row, $widths, $align, $char);
}

sub _md_validate_data {
  my $rows = shift @_;
  for my $row ( @{$rows}) {
    if ("@{$row}" =~ m/[^\\]\|/ ){
      die "Unescaped | will produce invalid Markdown!\n@{$row}";
    }
  }
}

sub _md_header_rule {
  my ($param, $widthref, $alignref ) = @_;
  my $coladj = $param->{'compact'} ? -2 : 0;
  my @align = @{$alignref};
  my @width = @{$widthref};
  my $rule = '|';
  while ( @width) {
    my $colwidth = $coladj + shift( @width);
    my $colalign = shift( @align);
    my $DASHES = '-' x ($colwidth ) ;
    $rule .= ":$DASHES-|" if ( $colalign eq 'l') ;
    $rule .= "-$DASHES:|" if ( $colalign eq 'r') ;
    $rule .= ":$DASHES:|" if ( $colalign eq 'c') ;
  }
return "$rule\n" ;
}

sub _header_rule
{
    my ($param, $widths, $char, $align) = @_;
    if ( $param->{'style'} eq 'markdown' ) {
      # the default unaligned markdown header_rule
      # is similar to other styles. the aligned
      # header_rule is unique.
      return _md_header_rule($param, $widths, $align) if $param->{'align'};
    }
    return '' unless $param->{header_row};
    my $fancy = $param->{separate_rows} ? 'F' : '';

    return _rule_row($param, $widths, $char->{"${fancy}LT"}, $char->{"${fancy}HR"}, $char->{"${fancy}HC"}, $char->{"${fancy}RT"});
}

sub _body
{
    my ($param, $rows, $widths, $align, $char) = @_;
    my $divider = $param->{separate_rows} ? _rule_row($param, $widths, $char->{LT}, $char->{HR}, $char->{HC}, $char->{RT}) : '';

    return join($divider, map { _text_row($param, $_, $widths, $align, $char) } @$rows);
}

sub _text_row
{
    my ($param, $row, $widths, $align, $char) = @_;
    my @columns = @$row;
    my $text = $param->{indent}.$char->{VR};

    for (my $i = 0; $i < @$widths; $i++) {
        $text .= _format_column($columns[$i] // '', $widths->[$i], $align->[$i] // 'l', $param, $char);
        $text .= $char->{VR};
    }
    $text .= "\n";

    return $text;
}

sub _format_column
{
    my ($text, $width, $align, $param, $char) = @_;
    my $pad = $param->{compact} ? '' : ' ';

    if ($align eq 'r' || $align eq 'right') {
        return $pad.' ' x ($width - tty_width($text)).$text.$pad;
    }
    elsif ($align eq 'c' || $align eq 'center' || $align eq 'centre') {
        my $total_spaces = $width - tty_width($text);
        my $left_spaces  = int($total_spaces / 2);
        my $right_spaces = $left_spaces;
        $right_spaces++ if $total_spaces % 2 == 1;
        return $pad.(' ' x $left_spaces).$text.(' ' x $right_spaces).$pad;
    }
    else {
        return $pad.$text.' ' x ($width - tty_width($text)).$pad;
    }
}

sub _calculate_widths
{
    my $rows = shift;
    my @widths;
    foreach my $row (@$rows) {
        my @columns = @$row;
        for (my $i = 0; $i < @columns; $i++) {
            next unless defined($columns[$i]);

            my $width = tty_width($columns[$i]);

            $widths[$i] = $width if !defined($widths[$i])
                                 || $width > $widths[$i];
        }
    }
    return @widths;
}

# Back-compat: 'table' is an alias for 'generate_table', but isn't exported
*table = \&generate_table;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Vote::Count::TextTableTiny

=head1 SYNOPSIS

Don't use this module. It is a fork from a pending Pull Request, and will be withdrawn when the PR merges.

=head1 REPOSITORY

L<https://github.com/neilb/Text-Table-Tiny>

=head1 AUTHOR

Neil Bowers <neilb@cpan.org>

The original version was written by Creighton Higgins <chiggins@chiggins.com>,
but the module was entirely rewritten for 0.05_01.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Neil Bowers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#FOOTER

=pod

BUG TRACKER

L<https://github.com/brainbuz/Vote-Count/issues>

AUTHOR

John Karr (BRAINBUZ) brainbuz@cpan.org

CONTRIBUTORS

Copyright 2019-2021 by John Karr (BRAINBUZ) brainbuz@cpan.org.

LICENSE

This module is released under the GNU Public License Version 3. See license file for details. For more information on this license visit L<http://fsf.org>.

SUPPORT

This software is provided as is, per the terms of the GNU Public License. Professional support and customisation services are available from the author.

=cut

