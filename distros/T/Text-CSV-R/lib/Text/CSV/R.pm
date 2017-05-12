package Text::CSV::R;

require 5.005;

use strict;
use warnings;

require Exporter;
use Text::CSV;
use Text::CSV::R::Matrix;
use Carp;
use Scalar::Util qw(reftype looks_like_number openhandle);
use List::Util qw(min max);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(read_csv read_csv2 read_table read_delim write_table write_csv rownames colnames)
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.3';

# A mapping of the R options to the Text:CSV options. False if there is no
# Text::CSV equivalent (specified because R options are not passed to
# Text::CSV, so we need to know all of them).
our $R_OPT_MAP = {
    sep         => 'sep_char',
    strip_white => 'allow_whitespace',
    quote       => 'quote_char',
    map { $_ => 0 }
        qw(dec skip nrow header encoding row_names col_names
        blank_lines_skip append hr fill),
};

# merge the global default options, function defaults and user options
sub _merge_options {
    my ( $t_opt, $u_opt ) = @_;
    my %ret = (
        skip             => 0,
        nrow             => -1,
        sep_char         => "\t",
        binary           => 1,
        blank_lines_skip => 1,
    );
    @ret{ keys %{$t_opt} } = values %{$t_opt};
    @ret{ keys %{$u_opt} } = values %{$u_opt};
    for my $k ( keys %{$R_OPT_MAP} ) {
        if ( defined $ret{$k} && $R_OPT_MAP->{$k} ) {
            $ret{ $R_OPT_MAP->{$k} } = $ret{$k};
        }
    }
    return \%ret;
}

sub read_table {
    my ( $file, %u_opt ) = @_;
    return _read( $file, _merge_options( {}, \%u_opt ) );
}

sub read_csv {
    my ( $file, %u_opt ) = @_;
    my $t_opt = { sep_char => q{,}, header => 1, };
    return _read( $file, _merge_options( $t_opt, \%u_opt ) );
}

sub read_csv2 {
    my ( $file, %u_opt ) = @_;
    my $t_opt = { sep_char => q{;}, dec => q{,}, header => 1, };
    return _read( $file, _merge_options( $t_opt, \%u_opt ) );
}

sub read_delim {
    my ( $file, %u_opt ) = @_;
    my $t_opt = { sep_char => "\t", header => 1, };
    return _read( $file, _merge_options( $t_opt, \%u_opt ) );
}

sub write_table {
    my ( $data_ref, $file, %u_opt ) = @_;
    return _write( $data_ref, $file,
        _merge_options( { eol => "\n", fill => 1 }, \%u_opt ) );
}

sub write_csv {
    my ( $data_ref, $file, %u_opt ) = @_;
    my $t_opt = { eol => "\n", fill => 1, hr => 1, sep_char => q{,} };
    return _write( $data_ref, $file, _merge_options( $t_opt, \%u_opt ) );
}

sub rownames {
    my ( $tied_ref, $values ) = @_;
    return Text::CSV::R::Matrix::ROWNAMES( tied @{$tied_ref}, $values );
}

sub colnames {
    my ( $tied_ref, $values ) = @_;
    return Text::CSV::R::Matrix::COLNAMES( tied @{$tied_ref}, $values );
}

# check if $file is an open filehandle, if not open file with correct
# encoding.  return also whether to close the filehandle or not
sub _get_fh {
    my ( $file, $read, $opts ) = @_;
    if ( openhandle($file) ) {
        return ( $file, 0 );
    }
    my $encoding = q{};
    if ( defined $opts->{encoding} && length $opts->{encoding} > 0 ) {
        $encoding = ':encoding(' . $opts->{encoding} . ')';
    }
    my $mode
        = $read ? '<'
        : ( defined $opts->{append} && $opts->{append} ) ? '>>'
        :                                                  '>';
    open my $IN, $mode . $encoding, $file
        or croak "Cannot open $file for reading: $!";
    return ( $IN, 1 );
}

# replace decimal point if necessary
sub _replace_dec {
    my ( $data_ref, $opts, $read ) = @_;
    if ( defined $opts->{dec} && $opts->{dec} ne q{.} ) {
        for my $row ( @{$data_ref} ) {
            $row = [ map { _replace_dec_col( $_, $opts, $read ) } @{$row} ];
        }
    }
    return;
}

sub _replace_dec_col {
    my ( $col, $opts, $read ) = @_;
    if ($read) {
        ( my $tmp = $col ) =~ s{$opts->{dec}}{.}xms;
        $col = looks_like_number($tmp) ? $tmp : $col;
    }
    elsif ( looks_like_number($col) ) {
        $col =~ s{\.}{$opts->{dec}}xms;
    }
    return $col;
}

sub _fill {
    my ($data) = @_;
    my @l = map { scalar @{$_} } @{$data};
    my $max = max @l;
    if ($max == min @l) { return; } 
    for my $row_id ( 0 .. $#l ) {
        for my $i ( 1 .. ( $max - $l[$row_id] ) ) {
            push @{ $data->[$row_id] }, q{};
        }
    }
    return;
}

sub _read {
    my ( $file, $opts ) = @_;

    my ( $fh, $toclose ) = _get_fh( $file, 1, $opts );
    my $data_ref = _parse_fh( $fh, $opts );
    if ($toclose) {
        close $fh or croak "Cannot close $file: $!";
    }
    _replace_dec( $data_ref, $opts, 1 );

    if ( defined $opts->{fill} && $opts->{fill} ) {
        _fill($data_ref);
    }

    return $data_ref;
}

sub _write {
    my ( $data_ref, $file, $opts ) = @_;

    my ( $fh, $toclose ) = _get_fh( $file, 0, $opts );
    _replace_dec( $data_ref, $opts, 0 );
    if ( defined $opts->{fill} && $opts->{fill} ) {
        _fill($data_ref);
    }
    _write_to_fh( $data_ref, $fh, $opts );
    if ($toclose) {
        close $fh or croak "Cannot close $file: $!";
    }
    return;
}

sub _create_csv_obj {
    my %text_csv_opts = @_;
    delete @text_csv_opts{ keys %{$R_OPT_MAP} };
    my $csv = Text::CSV->new( \%text_csv_opts )
        or croak q{Cannot use CSV: } . Text::CSV->error_diag();
    return $csv;
}

sub _write_to_fh {
    my ( $data_ref, $IN, $opts ) = @_;

    my $tied_obj = tied @{$data_ref};
    my $csv      = _create_csv_obj( %{$opts} );

    # do we have and want col/rownames?
    my %meta = map {
              $_ => defined $opts->{$_} ? $opts->{$_}
            : defined $tied_obj ? 1
            : 0
    } qw(row_names col_names);

    my @data = @{$data_ref};

    if ( $meta{row_names} ) {
        $meta{row_names}
            = reftype \$meta{row_names} eq 'SCALAR'
            ? rownames($data_ref)
            : $meta{row_names};
        @data
            = map { [ $meta{row_names}->[$_], @{ $data[$_] } ] } 0 .. $#data;
    }

    if ( $meta{col_names} ) {
        $meta{col_names}
            = reftype \$meta{col_names} eq 'SCALAR'
            ? colnames($data_ref)
            : $meta{col_names};
        unshift @data, $meta{col_names};
        if ( defined $opts->{hr} && $opts->{hr} ) {
            unshift @{ $data[0] }, q{};
        }
    }

    $csv->print( $IN, $_ ) for @data;

    return;
}

# parsing of the file in a 2d array, store column and row names.
sub _parse_fh {
    my ( $IN, $opts ) = @_;
    my @data;

    my $obj = tie @data, 'Text::CSV::R::Matrix';

    my $csv = _create_csv_obj( %{$opts} );

    # skip the first lines if option is set
    {
        local $. = 0;
        do { } while ( $. < $opts->{skip} && <$IN> );
    }

    my $max_cols = 0;
LINE:
    while ( my $line = <$IN> ) {
        chomp $line;

        # blank_lines_skip option
        next LINE if !length($line) && $opts->{'blank_lines_skip'};

        $csv->parse($line)
            or croak q{Cannot parse CSV: } . $csv->error_input();
        push @data, [ $csv->fields() ];
        if ( scalar( @{ $data[-1] } ) > $max_cols ) {
            $max_cols = scalar @{ $data[-1] };
        }

        # nrow option. Store one more because file might contain header.
        last LINE if ( $opts->{nrow} >= 0 && $. > $opts->{nrow} );
    }

   # If first line contains exactly one column less than the one with the
   # max. number of columns, we expect that first line contains the header and
   # first column the rownames (like read.tables does)
    my $auto_col_row = scalar @{ $data[0] || [] } == $max_cols - 1 ? 1 : 0;

    if ( defined $opts->{header} && !$opts->{header} ) {
        $auto_col_row = 0;
    }

    # in which column are rownames?
    my $rowname_id
        = ( defined $opts->{row_names}
            && reftype \$opts->{row_names} eq 'SCALAR' ) ? $opts->{row_names}
        : $auto_col_row ? 0
        :                 -1;

    # re-add the column name if it is omitted. use the same default name as R
    if ($auto_col_row) {
        unshift @{ $data[0] }, 'row.names';
    }

    if ( $auto_col_row || $opts->{header} ) {

        # first line contains header
        colnames( \@data, shift @data );
    }
    else {

        # no column names specified, then use the same default as R
        colnames( \@data, [ map { 'V' . $_ } 1 .. $max_cols ] );

        # we might have parsed one line more than needed with the nrow option,
        # so fix that if necessary
        if ( $opts->{nrow} >= 0 && $. > $opts->{nrow} ) {
            pop @data;
        }
    }

    my @rownames;
    if ( $rowname_id >= 0 ) {
        for my $row (@data) {
            push @rownames, splice @{$row}, $rowname_id, 1;
        }

        # remove the column from the colnames array
        my @colnames = @{ colnames( \@data ) };
        splice @colnames, $rowname_id, 1;
        colnames( \@data, \@colnames );
    }
    else {
        @rownames = 1 .. scalar @data;
    }
    rownames( \@data, \@rownames );

    return \@data;
}

1;

__END__

=head1 NAME

Text::CSV::R - Text::CSV wrapper similar to R's read.table and write.table

=head1 SYNOPSIS

  #use Text::CSV::R qw(:all);
  use Text::CSV::R qw(read_table write_csv colnames rownames);

  my $M = read_table($filename, %options);

  print join(q{,}, @{ colnames($M) });
  print join(q{,}, @{ rownames($M) });

  print $M->[0][0];

  for my $row (@{$M}) {
    for my $col (@{$row}) {
        # do someting with $col
    }
  }

  write_csv($M, $newfilename);

=head1 DESCRIPTION

This is just a convenient wrapper around L<Text::CSV>. It behaves mostly
like R's read.table and write.table functions. This module has a very simple
API and uses the simplest possible data structure for a table: a reference to a
two-dimensional array. It is very lightweight and has L<Text::CSV> as only
dependency.

=head1 EXPORT_OK

By default Text::CSV::R does not export any subroutines. The subroutines
defined are

=over

=item read_table($file, %options)

Parses C<$file> with the specified options (see L</OPTIONS>). Returns the
data as reference to a two-dimensional array. Internally, it is an array tied
to L<Text::CSV::R::Matrix>, which allows optional storing of column and row names.
The C<$file> can be a filename or a filehandle.

=item read_csv($file, %options)

Alias for

    read_table($file, sep_char => q{,}, header => 1 );

=item read_csv2($file, %options)

Alias for

    read_table($file, sep_char => q{;}, header => 1, dec => q{,} );

=item read_delim($file, %options)

Alias for

    read_table($file, sep_char => "\t", header => 1 );

=item write_table($array_ref, $file, %options)

Writes the two-dimensional C<$array_ref> to C<$file> with the specified options (see L</OPTIONS>). 
If array is tied to L<Text::CSV::R::Matrix>, then col and rownames are
written (see L</OPTIONS>).  The C<$file> can be a filename or a filehandle.

  my $M = read_table($file);
  write_table($M, $newfile, row_names => 0); # print only colnames

  # write a normal 2D array, there are no column and rownames, so just print
  # the fields 
  write_table(\@array, $newfile); 

Headers include no column for the row names, i.e. the number of columns in the
header is the number of data columns - 1 if row names are provided.

=item write_csv($array_ref, $file, %options)

Similar to 

    write_table($file, sep_char => q{,} );

The only difference is that headers include a column for the row names.

=item colnames($M, $array_ref)

Get and set (if C<$array_ref> defined) the colnames.

=item rownames($M, $array_ref)

Get and set (if C<$array_ref> defined) the rownames.

=back

=head1 OPTIONS

All non-R options are passed to L<Text::CSV>. Listed are now the supported R
options. If there is a L<Text::CSV> equivalent, you can either use the
L<Text::CSV> or the R option name. There might be subtle differences to the R
implementation. 

=over

=item Read and Write Options

=over 

=item sep

  Text::CSV  : sep_char 
  R          : sep
  Default    : \t 
  Description: the field separator character

=item dec

  Text::CSV   :  
  R           : dec
  Default     : .
  Description : the character used in the file for decimal points.

=item fill

  Text::CSV   : 
  R           : fill
  Default     : 0 for read, 1 for write
  Description : if true then in case the rows have unequal length, blank
                fields are implicitly added. 

=item quote

  Text::CSV   : quote_char 
  R           : quote
  Default     : "
  Description : the quoting character

=item encoding

  Text::CSV   : 
  R           : encoding
  Default     : 
  Description : if specified, the file is opened with ':encoding(value)' 

=back

=item Read Options

=over

=item header

  Text::CSV   :  
  R           : header
  Default     : 0
  Description : a logical value indicating whether the file contains the
                column names as its first line. If not specified, set to
                1 if and only if the first row contains one fewer field 
                than the row with the maximal number of fields.

=item blank_lines_skip

  Text::CSV   :  
  R           : blank.lines.skip
  Default     : 1
  Description : a logical value indicating whether blank lines in the 
                input are ignored.

=item nrows

  Text::CSV   :  
  R           : nrows
  Default     : -1
  Description : the maximum number of rows to read in.  Negative values 
                are ignored.

=item skip

  Text::CSV   :  
  R           : skip
  Default     : 0
  Description : the number of lines of the data file to skip before
                beginning to read data

=item strip_white

  Text::CSV   : allow_whitespace 
  R           : strip.white
  Default     : 0
  Description : allows the stripping of leading and trailing white space

=item row_names

  Text::CSV   : 
  R           : row.names
  Default     : 
  Description : if specified, it defines the column with the row names. If
                not, set to 0 if and only if the first row contains one 
                fewer field than the row with the maximal number of fields.  
                Otherwise, rownames will be 1 .. #rows.

=back

=item Write Options

=over

=item eol

  Text::CSV   : eol
  R           : eol
  Default     : \n
  Description : the character(s) to print at the end of each line (row).

=item append

  Text::CSV   : 
  R           : append
  Default     : 
  Description : Only relevant if 'file' is a character string.  If true,
                the output is appended to the file.  Otherwise, any
                existing file of the name is destroyed.

=item col_names, row_names

  Text::CSV   : 
  R           : col.names, row.names
  Default     : 1 if array is tied to Text::CSV::R::Matrix, 0 otherwise
  Description : if scalar, then specifies whether col and rownames should be 
                printed.  Requires that array is tied to Text::CSV::R::Matrix.
                It is also possible to provide the col and rownames by array
                reference.
                   
=back

=back

=head1 SEE ALSO

L<Text::CSV>, L<Text::CSV::Slurp>, L<Spreadsheet::Read>

=head1 DIFFERENCES TO R

=over

=item Due to the language differences: Dots in function and option names are
replaced with underscores and indexing starts with 0, not 1.

=item The C<sep> and C<quote> options in R support multiple characters, the
L<Text::CSV> counterparts do not.

=back

=head1 BUGS AND LIMITATIONS

The encode option requires Perl 5.8 or newer.

Please report any bugs or feature requests to
C<bug-text-csv-r@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 E<lt>limaone@cpan.orgE<gt>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
