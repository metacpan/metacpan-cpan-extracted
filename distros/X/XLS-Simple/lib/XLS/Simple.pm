#ABSTRACT: read xls / write xls
package XLS::Simple;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(write_xls read_xls read_xlsx);

our $VERSION=0.021;

use Encode;
use Excel::Writer::XLSX;
use Spreadsheet::Read;
use Spreadsheet::XLSX;

use strict;
use warnings;

our %XLS_FORMAT_DATA = (
    align  => 'right',
    size   => 13.5,
    border => 1,
);

our %XLS_FORMAT_HEADER = (
    %XLS_FORMAT_DATA,
    color => 'blue',
    bold  => 1,
);

sub write_xls {
    my ( $data, $fname, %opt ) = @_;
    format_xls_data( $data, %opt );

    my $workbook  = Excel::Writer::XLSX->new($fname);
    my $worksheet = $workbook->add_worksheet();

    my $fmt_data =
      $workbook->add_format(
        $opt{format_data} ? %{ $opt{format_data} } : %XLS_FORMAT_DATA );
    if ( $opt{header} ) {
        my $fmt_head =
          $workbook->add_format( $opt{format_header}
            ? %{ $opt{format_header} }
            : %XLS_FORMAT_HEADER );
        $worksheet->write_row( 0, 0, $opt{header}, $fmt_head );

        $worksheet->write_col( 1, 0, $data, $fmt_data );
    }
    else {
        $worksheet->write_col( 0, 0, $data, $fmt_data );
    }

    $workbook->close();
    return $fname;
}

sub format_xls_data {
    my ( $data, %opt ) = @_;
    return $data unless ( exists $opt{charset} );

    for my $d ( $opt{header}, @$data ) {
        for my $x (@$d) {
            $x =~ s/^\s+|\s+$//;
            $x = decode( $opt{charset}, $x );
        }
    } ## end for my $d (@$sheet_data)

    return $data;
}

sub read_xlsx {
    my ($xlsx, %opt) = @_;
    my $excel = Spreadsheet::XLSX->new($xlsx);
    my @res;
    for my $sheet (@{$excel->{Worksheet}}){
        my $max_row = $sheet->{MaxRow} || $sheet->{MinRow};
        for my $row ($sheet->{MinRow} .. $max_row){
            my $max_col = $sheet->{MaxCol} || $sheet->{MinCol};
            my @data = map { $sheet->{Cells}[$row][$_]{Val} } 
            ($sheet->{MinCol} .. $max_col);
            push @res, \@data;
            return \@data if($opt{only_header});
        }
    }
    shift @res if ( $opt{skip_header} );
    return \@res;
}

sub read_xls {
    my ( $xls, %opt ) = @_;
    return read_xlsx($xls, %opt) if($xls=~/\.xlsx$/i);

    my $workbook = ReadData($xls);

    my @data =
      $opt{only_header}
      ? Spreadsheet::Read::cellrow( $workbook->[1], 1 )
      : Spreadsheet::Read::rows( $workbook->[1] );

    shift @data if ( $opt{skip_header} );

    return \@data;
}

1;
