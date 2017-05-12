package Text::FormatTable;

use Carp;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.03';

=head1 NAME

Text::FormatTable - Format text tables

=head1 SYNOPSIS

 my $table = Text::FormatTable->new('r|l');
 $table->head('a', 'b');
 $table->rule('=');
 $table->row('c', 'd');
 print $table->render(20);

=head1 DESCRIPTION

Text::FormatTable renders simple tables as text. You pass to the constructor
(I<new>) a table format specification similar to LaTeX (e.g. C<r|l|5l|R|20L>) and you
call methods to fill the table data and insert rules. After the data is filled,
you call the I<render> method and the table gets formatted as text.

Methods:

=over 4

=cut

# Remove ANSI color sequences when calculating length
sub _uncolorized_length($)
{
    my $str = shift;
    $str =~ s/\e \[ [^m]* m//xmsg;
    return length $str;
}

# minimal width of $1 if word-wrapped
sub _min_width($)
{
    my $str = shift;
    my $min;
    for my $s (split(/\s+/,$str)) {
        my $l = _uncolorized_length $s;
        $min = $l if not defined $min or $l > $min;
    }
    return $min ? $min : 1;
}

# width of $1 if not word-wrapped
sub _max_width($)
{
    my $str = shift;
    my $len = _uncolorized_length $str;
    return $len ? $len : 1;
}

sub _max($$)
{
    my ($a,$b) = @_;
    return $a if defined $a and (not defined $b or $a >= $b);
    return $b;
}

# word-wrap multi-line $2 with width $1
sub _wrap($$)
{
    my ($width, $text) = @_;
    my @lines = split(/\n/, $text);
    my @w = ();
    for my $l (@lines) {
        push @w, @{_wrap_line($width, $l)};
    }
    return \@w;
}

sub _wrap_line($$)
{
    my ($width, $text) = @_;
    my $width_m1 = $width-1;
    my @t = ($text);
    while(1) {
        my $t = pop @t;
        my $l = _uncolorized_length $t;
        if($l <= $width){
            # last line is ok => done
            push @t, $t;
            return \@t;
        }
        elsif($t =~ /^(.{0,$width_m1}\S)\s+(\S.*?)$/) {
            # farest space < width
            push @t, $1;
            push @t, $2;
        }
        elsif($t =~ /(.{$width,}?\S)\s+(\S.*?)$/) {
            # nearest space > width
            if ( _uncolorized_length $1 > $width_m1  )
            {
                # hard hyphanation 
                my $left = substr($1,0,$width);
                my $right= substr($1,$width);

                push @t, $left;
                push @t, $right;
                push @t, $2;
            }
            else
            {
                push @t, $1;
                push @t, $2;
            }
        }
        else {
            # hard hyphanation 
            my $left = substr($t,0,$width);
            my $right= substr($t,$width);

            push @t, $left;
            push @t, $right;
            return \@t;
        }
    }
    return \@t;
}

# render left-box $2 with width $1
sub _l_box($$)
{
    my ($width, $text) = @_;
    my $lines = _wrap($width, $text);
    map { $_ .= ' 'x($width-_uncolorized_length($_)) } @$lines;
    return $lines;
}

# render right-box $2 with width $1
sub _r_box($$)
{
    my ($width, $text) = @_;
    my $lines = _wrap($width, $text);
    map { $_ = (' 'x($width-_uncolorized_length($_)).$_) } @$lines;
    return $lines;
}

# Algorithm of:
# http://ei5nazha.yz.yamagata-u.ac.jp/~aito/w3m/eng/STORY.html

sub _distribution_f($)
{
    my $max_width = shift;
    return log($max_width);
}

sub _calculate_widths($$)
{
    my ($self, $width) = @_;
    my @widths = ();
    # calculate min and max widths for each column
    for my $r (@{$self->{data}})
    {
        $r->[0] eq 'data' or $r->[0] eq 'head' or next;
        my $cn=0;
        my ($max, $min) = (0,0);
        
        for my $c (@{$r->[1]}) {
            
            if ( $self->{fixed_widths}[$cn] )
            {
               # fixed width
               $widths[$cn][0] = $self->{fixed_widths}[$cn]; 
               $widths[$cn][1] = $self->{fixed_widths}[$cn];
            }
            else
            {
                $widths[$cn][0] = _max($widths[$cn][0], _min_width $c);
                $widths[$cn][1] = _max($widths[$cn][1], _max_width $c);
            }
            $cn++;
        }
    }

    # calculate total min and max width
    my ($total_min, $total_max) = (0,0);
    for my $c (@widths) {
        $total_min += $c->[0];
        $total_max += $c->[1];
    }
    # extra space
    my $extra_width += scalar grep {$_->[0] eq '|' or $_->[0] eq ' '}
        (@{$self->{format}});
    $total_min += $extra_width;
    $total_max += $extra_width;

    # if total_max <= screen width => use max as width
    if($total_max <= $width) {
        my $cn = 0;
        for my $c (@widths) {
            $self->{widths}[$cn]=$c->[1];
            $cn++;
        }
        $self->{total_width} = $total_max;
    }
    else {
        my @dist_width;
        ITERATION: while(1) {
            my $total_f = 0.0;
            my $fixed_width = 0;
            my $remaining=0;
            for my $c (@widths) {
                if(defined $c->[2]) {
                    $fixed_width += $c->[2];
                }
                else {
                    $total_f += _distribution_f($c->[1]);
                    $remaining++;
                }
            }
            my $available_width = $width-$extra_width-$fixed_width;
            # enlarge width if it isn't enough
            if($available_width < $remaining*5) {
                $available_width = $remaining*5;
                $width = $extra_width+$fixed_width+$available_width;
            }
            my $cn=-1;
            COLUMN: for my $c (@widths) {
                $cn++;
                next COLUMN if defined $c->[2]; # skip fixed-widths
                my $w = _distribution_f($c->[1]) * $available_width / $total_f;
                if($c->[0] > $w) {
                    $c->[2] = $c->[0];
                    next ITERATION;
                }
                if($c->[1] < $w) {
                    $c->[2] = $c->[1];
                    next ITERATION;
                }
                $dist_width[$cn] = int($w);
            }
            last;
        }
        my $cn = 0;
        for my $c (@widths) {
            $self->{widths}[$cn]=defined $c->[2] ? $c->[2] : $dist_width[$cn];
            $cn++;
        }
    }
}

sub _render_rule($$)
{
    my ($self, $char) = @_;
    my $out = '';
    my ($col,$data_col) = (0,0);
    for my $c (@{$self->{format}}) {
        if($c->[0] eq '|') {
            if   ($char eq '-') { $out .= '+' }
            elsif($char eq ' ') { $out .= '|' }
            else                { $out .= $char }
        }
        elsif($c->[0] eq ' ') {
            $out .= $char;
        }
        elsif( $c->[0] eq 'l' 
            or $c->[0] eq 'L' 
            or $c->[0] eq 'r' 
            or $c->[0] eq 'R'
            ) {
            $out .= ($char)x($self->{widths}[$data_col]);
            $data_col++;
        }
        $col++;
    }
    return $out."\n";
}

sub _render_data($$)
{
    my ($self,$data) = @_;

    my @rdata; # rendered data

    # render every column and find out number of lines
    my ($col, $data_col) = (0,0);
    my $lines=0;
    my @rows_in_column;
    for my $c (@{$self->{format}}) {
        if( ($c->[0] eq 'l') or ($c->[0] eq 'L') ) {
            my $lb = _l_box($self->{widths}[$data_col], $data->[$data_col]);
            $rdata[$data_col] = $lb;
            my $l = scalar @$lb ;
            $lines = $l if $lines < $l;
            $rows_in_column[$data_col] = $l;
            $data_col++;
        }
        elsif( ($c->[0] eq 'r') or ($c->[0] eq 'R' ) ) {
            my $rb = _r_box($self->{widths}[$data_col], $data->[$data_col]);
            $rdata[$data_col] = $rb;
            my $l = scalar @$rb ;
            $lines = $l if $lines < $l;
            $rows_in_column[$data_col] = $l ;
            $data_col++;
        }
        $col++;
    }

    # render each line
    my $out = '';
    for my $l (0..($lines-1)) {
        my ($col, $data_col) = (0,0);
        for my $c (@{$self->{format}}) {
            if($c->[0] eq '|') {
                $out .= '|';
            }
            elsif($c->[0] eq ' ') {
                $out .= ' ';
            }
            elsif( $c->[0] eq 'L' or $c->[0] eq 'R')
            {
                # bottom align
                my $start_print = $lines - $rows_in_column[$data_col];
                
                if ( defined $rdata[$data_col][$l-$start_print] 
                     and $l >= $start_print 
                    )
                {
                    $out .= $rdata[$data_col][$l-$start_print];
                }
                else
                {
                    $out .= ' 'x($self->{widths}[$data_col]);
                }
                $data_col++;
            }
            elsif($c->[0] eq 'l' or $c->[0] eq 'r') {
                # top align
                if(defined $rdata[$data_col][$l]) {
                    $out .= $rdata[$data_col][$l];
                }
                else {
                    $out .= ' 'x($self->{widths}[$data_col]);
                }
                $data_col++;
            }
            $col++;
        }
        $out .= "\n";
    }
    return $out;
}

sub _parse_format($$)
{
    my ($self, $format) = @_;
    my @f = split(//, $format);
    my @format = ();
    my @width  = ();
    
    my ($col,$data_col) = (0,0);
    my $wid;
    for my $f (@f) {
        if ( $f =~ /(\d+)/)
        {
           $wid .= $f; 
           next;
        }
        if($f eq 'l' or $f eq 'L' or $f eq 'r' or $f eq 'R') {
            $format[$col] = [$f, $data_col];
            $width[$data_col] = $wid; 
            $wid = undef;
            $data_col++;
        }
        elsif($f eq '|' or $f eq ' ') {
            $format[$col] = [$f];
        }
        else {
            croak "unknown column format: $f";
        }
        $col++;
    }
    $self->{format}=\@format;
    $self->{fixed_widths}=\@width;
    $self->{col}=$col;
    $self->{data_col}=$data_col;
}

=item B<new>(I<$format>)

Create a Text::FormatTable object, the format of each column is specified as a
character of the $format string. The following formats are defined:

=over 4

=item l

Left-justified top aligned word-wrapped text.

=item L

Left-justified bottom aligned word-wrapped text.

=item r

Right-justified top aligned word-wrapped text.

=item R

Right-justified bottom aligned word-wrapped text.

=item 10R, 20r, 15L, 12l, 

Number is fixed width of the column.
Justified and aligned word-wrapped text (see above).

=item ' '

A space.

=item |

Column separator.

=back

=cut

sub new($$)
{
    my ($class, $format) = @_;
    croak "new() requires one argument: format" unless defined $format;
    my $self = { col => '0', row => '0', data => [] };
    bless $self, $class;
    $self->_parse_format($format);
    return $self;
}

# remove head and trail space
sub _preprocess_row_data($$)
{
    my ($self,$data) = @_;
    my $cn = 0;
    for my $c (0..($#$data)) {
        $data->[$c] =~ s/^\s+//m;
        $data->[$c] =~ s/\s+$//m;
    }
}

=item B<head>(I<$col1>, I<$col2>, ...)

Add a header row using $col1, $col2, etc. as cell contents. Note that, at the
moment, header rows are treated like normal rows.

=cut

sub head($@)
{
    my ($self, @data) = @_;
    scalar @data == $self->{data_col} or
        croak "number of columns must be $self->{data_col}";
    $self->_preprocess_row_data(\@data);
    $self->{data}[$self->{row}++] = ['head', \@data];
}

=item B<row>(I<$col1>, I<$col2>, ...)

Add a row with $col1, $col2, etc. as cell contents.

=cut

sub row($@)
{
    my ($self, @data) = @_;
    scalar @data == $self->{data_col} or
        croak "number of columns must be $self->{data_col}";
    
    $self->_preprocess_row_data(\@data);
    $self->{data}[$self->{row}++] = ['data', \@data];
}

=item B<rule>([I<$char>])

Add an horizontal rule. If $char is specified it will be used as character to
draw the rule, otherwise '-' will be used.

=cut

sub rule($$)
{
    my ($self, $char) = @_;
    $char = '-' unless defined $char;
    $self->{data}[$self->{row}++] = ['rule', $char];
}

=item B<render>([I<$screen_width>])

Return the rendered table formatted with $screen_width or 79 if it is not
specified. 

=cut

sub render($$)
{
    my ($self, $width) = @_;
    
    $width = 79 unless defined $width;
    $self->_calculate_widths($width);
    
    my $out = '';
    for my $r (@{$self->{data}}) {
        if($r->[0] eq 'rule') {
            $out .= $self->_render_rule($r->[1]);
        }
        elsif($r->[0] eq 'head') {
            $out .= $self->_render_data($r->[1]);
        }
        elsif($r->[0] eq 'data') {
            $out .= $self->_render_data($r->[1]);
        }
    }
    return $out;
}

1;

=back

=head1 SEE ALSO

Text::ASCIITable

=head1 COPYRIGHT

Copyright (c) 2001-2004 Swiss Federal Institute of Technology, Zurich.
          (c) 2009 Trey Harris
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 CODE REPOSITORY

Git - http://github.com/treyharris/Text-FormatTable/tree/master

=head1 AUTHOR

S<David Schweikert <dws@ee.ethz.ch>>

Maintained by S<Trey Harris <treyharris@gmail.com>>

Fixed column width and bottom alignment written by
S<Veselin Slavov <vslavov@creditreform.bg>>

=cut

# vi: et sw=4
