package Text::FixedLengthMultiline;

use utf8;
use strict;
use warnings;

use Carp;

BEGIN {
    our $VERSION = '0.071';
}

use constant FIRST => 1;
use constant LAST => 2;
use constant ANY => 3; # FIRST | LAST

my %continue_styles = (
    'first' => FIRST,
    'last' => LAST,
    'any' => ANY
);


=encoding utf8

=head1 NAME

Text::FixedLengthMultiline - Parse text data formatted in space separated columns optionnaly on multiple lines

=head1 SYNOPSIS

  use Text::FixedLengthMultiline;

  #234567890 12345678901234567890 12
  my $text = <<EOT;
  Alice      Pretty girl!
  Bob        Good old uncle Bob,
             very old.            92
  Charlie    Best known as Waldo  14
             or Wally. Where's
             he?
  EOT

  my $fmt = Text::FixedLengthMultiline->new(format => ['!name' => 10, 1, 'comment~' => 20, 1, 'age' => -2 ]);

  # Compute the RegExp that matches the first line
  my $first_line_re = $fmt->get_first_line_re();
  # Compute the RegExp that matches a continuation line
  my $continue_line_re = $fmt->get_continue_line_re();

  my @data;
  my $err;
  while ($text =~ /^([^\n]+)$/gm) {
      my $line = $1;
      push @data, {} if $line =~ $first_line_re;
      if (($err = $fmt->parse_line($line, $data[$#data])) > 0) {
          warn "Parse error at column $err";
      }
  }

=head1 DESCRIPTION

A row of data can be splitted on multiple lines of text with cell content
flowing in the same column space.

=head1 FORMAT SPECIFICATION

The format is given at the contruction time as an array ref. Modifying the
array content after the construction call is done at your own risks.

The array contains the ordered sequence of columns. Each colmun can either be:

=over

=item *

a positive integer representing the size of a separating column which is
expected to always be filled with spaces.

=item *

a string that matches this regexp: /^(?#mandatory)!?(?#name)[:alnum:]\w*(?:(?#multi)~(?#cont).?)?$/

=over

=item *

C<!> means the column is mandatory

=item *

C<name> is the column name. This will be the key for the hash after parsing.

=item *

C<~> means the column data can be on multiple lines.

=back

=back

=head1 METHODS

=head2 new()

Arguments:

=over

=item *

C<format>: an array reference following the L<FORMAT SPECIFICATION>.

=item *

C<debug>

=back

Example:

  my $format = Text::FixedLengthMultiline->new(format => [ 2, col1 => 4, 1, '!col2' => 4 ]);

=cut

# TODO add 'continue-style': first/last/any
sub new
{
    my $class = shift;
    my %params = @_;
    (%params && exists $params{'format'}) or croak('['.__PACKAGE__."] Missing format");
    ref $params{'format'} eq 'ARRAY' or croak('['.__PACKAGE__."] Invalid format: array ref expected");
    my $continue_style = ANY;
    if (exists $params{'continue_style'}) {
	my $style = $params{'continue_style'};
	croak('['.__PACKAGE__."] Invalid continue_style: first/last/any expected") unless exists $continue_styles{$style};
	$continue_style = $continue_styles{$style};
    }
    # TODO Check the format, and report errors
    my $self = {
        FORMAT => $params{'format'},
                           # Maybe doing a copy would be a good idea...
                           # But we trust the user even if we all know
                           # he's a crazy programmer
        DEBUG => exists $params{'debug'} && $params{'debug'},
	CONTINUE_STYLE => $continue_style
    };
    bless $self, $class;
    return $self;
}


=head2 C<parse_table($text)>

Parse a table.

  my @table = $fmt->parse_table($text);

Returns an array of hashes. Each hash is a row of data.

=cut

sub parse_table
{
    my ($self, $text) = @_;
    my $first_re = $self->get_first_line_re();
    my @table;
    my $err;
    my $linenum = 1;
    (pos $text) = 0;
    while ($text =~ /^([^\n]+)$/gm) {
        my $line = $1;
        push @table, {} if $line =~ $first_re;
        if (($err = $self->parse_line($line, $table[$#table])) > 0) {
            croak "Parse error at line $linenum, column $err";
        }
    }
    return @table;
}




=head2 C<parse_line($line, $hashref)>

Parse a line of text and add parsed data to the hash.

  my $error = $fmt->parse_line($line, \%row_data);

Multiple calls to C<parse_line()> with the same hashref may be needed to fully
read a "logical line" in case some columns are multiline.

Returns:

=over

=item *

C<-col>: Parse error. The value is a negative integer indicating the
character position in the line where the parse error occured.

=item *

C<0>: OK

=item *

C<col>: Missing data: need to feed next line to fill remining columns.
The value is the character position of the column where data is expected.

=back

=cut

# TODO: return a RE in case of missing data
sub parse_line
{
    my ($self, $line, $data) = @_;
    my @fmt = @{$self->{FORMAT}};
    my $col = 1;
    my $ret = 0;
    $line = '' unless defined $line;
    while ($#fmt >= 0) {
	my $f = shift @fmt;
	my $data_len;
	if ($f =~ /^\d+$/) {
	    # Spaces to skip
	    next if $f == 0;
	    $line =~ /^( {0,$f})/;
	    $data_len = length $1;
	    return -($col+$data_len) if $data_len < $f;
	} elsif ($f =~ /^(!?)([A-Za-z_]\w*)(?:(~)(.?))?$/) {
	    my ($mandatory, $field, $multi, $cont) = ($1, $2, $3, $4);
	    $multi = 0 unless defined $multi;
	    $cont = ' ' unless defined $cont && $cont ne '';
	    my $len = shift @fmt;
	    next if $len == 0;
	    my $d = substr($line, 0, abs $len);
	    $data_len = length $d;
	    if ($len > 0) {
		$d =~ s/ +$//;
	    } else {
		$d .= ' ' x -($data_len+$len);
		$d =~ s/^ +//;
	    }
	    if ($d ne '') {
	        return -$col if !$multi && exists $data->{$field};
		if ($multi && exists $data->{$field}) {
		    # Multilines => concat
		    $data->{$field} .= "\n" . $d;
		    $ret = $col if $ret == 0 && $d =~ /\Q$cont\E$/;
		} else {
		    $data->{$field} = $d;
		}
	    }
	    $ret = $col if $mandatory && !exists $data->{$field} && $ret == 0;
	} else {
	    warn "Bad format!\n";
	    return -$col;
	}
	$col += $data_len;
	$line = substr($line, $data_len);
	last if $ret != 0 && $line eq '';
    }
    return -$col unless $line =~ /^ *$/;
    return $ret;
}




sub _dump_line_re()
{
    while ($#_ >= 0) {
	print "> [" . (shift @_) ."]\n";
	print '  [' . join('] :: [', @{ (shift @_) }) . "]\n";
    }
}

sub _serialize_line_re()
{
    #&_dump_line_re(@_);
    my $re = '';
    while ($#_ > -1) {
	# Pop the alternatives for the end of the line
    	my @b = grep(!/^$/, @{ (pop @_) });
	# TODO remove duplicates
	push @b, $re if $re ne '';
    	if ($#b > 0) {
	    $re = "(?:" . join('|', @b) . ")";
	} elsif ($#b > -1) {
	    $re = $b[0];
        } else {
	    $re = '';
	}
	# Pop
    	$re = (pop @_) . $re;
	#print "$re\n";
    }
    return $re;
}

sub _parse_column_format($;$)
{
    my ($format, $width) = @_;
    if ($format =~ /^(!?)([A-Za-z_]\w*)(?:(~)(.?))?$/) {
	my %def = (
	    mandatory => $1,
	    name => $2,
	    multi => $3,
	    cont => $4,
	    width => abs $width
	);
	$def{multi} = '' unless defined $def{multi};
	$def{align} = $width > 0 ? 'L' : 'R';
	return %def;
    } else {
	return undef;
    }
}

sub _build_repetition_re($;$;$)
{
    my ($c, $min, $max) = @_;
    return '' if $max <= 0;
    if ($max == 1) {
	$c .= '?' if $min <= 0;
    } else {
	if ($min < $max) {
	    $c .= "{$min,$max}";
	} else {
	    $c .= "{$max}";
	}
    }
    return $c;
}

sub _build_column_re
{
    my $self = shift;
    my %def = @_;
    my $branch_multi = $def{multi} && exists $def{branch_multi} && $def{branch_multi};
    my $re_label = $self->{DEBUG} ? "(?#_$def{mandatory}$def{name}$def{multi}_)" : '';
    my $re_spaces = $def{spaces} > 0 ? ' '.($def{spaces} > 1 ? "{$def{spaces}}":'') : '';
    my $width = $def{width};
    my ($re_col_mand, $re_col_end, $re_col);
    if ($def{mandatory} || $branch_multi) {
	$re_col_mand = $re_spaces . $re_label;
	if ($def{align} eq 'L') { # Left aligned
	    $re_col_end =   &_build_repetition_re('.', 0,        $width-1);
	    unless ($branch_multi) {
		$re_col_mand .= '\S';
		$re_col =   &_build_repetition_re('.', $width-1, $width-1);
	    } else {
		$re_col =   &_build_repetition_re('.', $width, $width);
		$re_col_end = '\S' . $re_col_end;
	    }
	} else {
	    $re_col_mand .= &_build_repetition_re('.', $width-1, $width-1);
	    unless ($branch_multi) {
		$re_col_end = $re_col = '';
		$re_col_mand .= '\S';
	    } else {
		$re_col_end = '\S';
		$re_col = '.';
	    }
	}
    } else {
	$re_col_mand = '';
	$re_col_end = $re_spaces . $re_label . '.' . ($width > 1 ? "{0,$width}" : '?');
	$re_col_end = "(?:$re_col_end)?" if $def{spaces};
	$re_col =     $re_spaces . $re_label . '.' . ($width > 1 ? "{$width}"   : '' );
    }
    #print "$def{name} => /$re_col_mand/  /$re_col_end/  /$re_col/  (spaces = $def{spaces})\n";
    return ($re_col_mand, $re_col_end, $re_col);
}

sub _has_multi(@)
{
    foreach (@_) {
	return 1 if /!?[_[:alpha:]]\w+~/;
    }
    return 0;
}


# @_ is the format
# TODO handle the case where all columns are optionnal
# The RE is then the union of the cases where one of the colmuns, up to the first multi, is mandatory
sub _build_first_line_re
{
    my $self = shift;
    my $branch_multi = shift;
    my $spaces = 0;
    my @re = ();
    my $re_acc = ''; # Accumulator
    my $multi = '~'; # Force the initialisation of @re
    while ($#_ >= 0) {
	my $f = shift;
	if ($f =~ /^\d+$/) {
	    $spaces += $f;
	} else {
	    my %def = &_parse_column_format($f, shift);
	    if ($multi && ($branch_multi || $#re == -1)) {
		# The previous column was a multi. The following fields may not be
		# on this line but on one of the next ones.
		# So the end of the line is optionnal.
		# We are starting a new altenative in the RE.
		push @re, $re_acc, [ ];
		$re_acc = '';
	    }
	    my ($re_col_mand, $re_col_end, $re_col) = $self->_build_column_re(%def, spaces => $spaces);
	    if ($def{mandatory}) {
		# Flush optional columns and append this column
		$re[$#re-1] .= $re_acc . $re_col_mand;
		if ($re_col_end eq '') {
		    $re[$#re] = [ ];
		} else {
		    $re[$#re] = [ $re_col_end ];
		}
		$re_acc = $re_col;
	    } else {
		# Save column format for later
		push @{$re[$#re]}, $re_acc . $re_col_mand . $re_col_end;
		$re_acc .=                   $re_col_mand . $re_col;
	    }
	    $spaces = 0;
	    $multi = $def{multi};
	}
    }
    return @re;
}

sub _build_continue_line_re
{
    my $self = shift;
    my $spaces = 0;
    my $multi = '~'; # Force the initialisation of @re
    while ($#_ >= 0) {
	my $f = shift;
	if ($f =~ /^\d+$/) {
	    $spaces += $f;
	} else {
	    my %def = &_parse_column_format($f, shift);
	    unless ($def{multi}) {
		$spaces += $def{width};
		next;
	    }
	    my @re;
	    my ($re_col_end, $re_col);
	    ($re[0], $re_col_end, $re_col) = $self->_build_column_re(%def, spaces => $spaces, branch_multi => &_has_multi(@_));
	    push @re, [ $re_col_end ];
	    my @re_end;
	    push @re_end, &_serialize_line_re($self->_build_continue_line_re(@_)) if $self->{CONTINUE_STYLE} & FIRST;
	    push @re_end, &_serialize_line_re($self->_build_first_line_re(1, @_)) if $self->{CONTINUE_STYLE} & LAST;
	    @re_end = grep !/^$/, @re_end;
	    #pop @re_end if $#re_end == 1 && $re_end[1] eq $re_end[0];
	    push @re, $re_col, [ @re_end ] if (@re_end);
	    return @re;
	}
    }
    return ();
}

=head2 C<get_first_line_re()>

Returns a regular expression that matches the first line of a "logical line"
of data.

  my $re = $fmt->get_first_line_re();

=cut

sub get_first_line_re
{
    my $self = shift;
    if (!exists $self->{FIRST_LINE_RE}) {
	my @re;
	if ($self->{CONTINUE_STYLE} == FIRST) {
	    @re = $self->_build_first_line_re(0, @{$self->{FORMAT}});
	} else {
	    @re = $self->_build_first_line_re(1, @{$self->{FORMAT}});
	}
	my $re = &_serialize_line_re(@re);
	$self->{FIRST_LINE_RE} = ($re eq '' ? undef : qr/^$re *$/);
    }
    return $self->{FIRST_LINE_RE};
}

=head2 C<get_continue_line_re()>

Returns a regular expression that matches the 2nd line and the following
lines of a "logical line".

  my $re = $fmt->get_continue_line_re();

Returns undef if the format specification does not contains any column that
can be splitted on multiples lines.

=cut

# continue-style: first (only cont columns can appear on a continue line)
sub get_continue_line_re
{
    my $self = shift;
    if (!exists $self->{CONTINUE_LINE_RE}) {
	my @re = $self->_build_continue_line_re(@{$self->{FORMAT}});
	#&_dump_line_re(@re);
	my $re = &_serialize_line_re(@re);
	$self->{CONTINUE_LINE_RE} = ($re eq '' ? undef : qr/^$re *$/);
    }
    return $self->{CONTINUE_LINE_RE};
}

1; # Magic for module end

__END__

=head1 TODO

=over

=item *

C<format()>

=item *

C<to_sprintf()>

=item *

See TODO sections in tests bundled with the distribution.

=back

=head1 BUGS

=over

=item *

This module should have been named Text::FixedLengthMultilineFormat, but the
current name is already long enough!

=back


=head1 SUPPORT

You can look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-FixedLengthMultiline>:
post bug report there.

=item * CPAN Ratings

L<http://cpanratings.perl.org/p/Text-FixedLengthMultline>:
if you use this distibution, please add comments on your experience for other
users.

=item * Search CPAN

L<http://search.cpan.org/dist/Text-FixedLengthMultiline/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-FixedLengthMultiline>

=back


=head1 LICENSE

Copyright (c) 2005-2010 Olivier MenguE<eacute>. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Olivier MenguE<eacute>, <dolmen@cpan.org>

=head1 SEE ALSO

Related modules I found on CPAN:

=over

=item *

L<Text::FormatTable>

=item *

L<Text::Table>

=item *

L<Text::FixedLength>

=item *

L<Text::FixedLength::Extra>

=item *

L<Text::Column>

=back
