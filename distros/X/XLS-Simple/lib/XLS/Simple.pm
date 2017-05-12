#ABSTRACT: read xls / write xls 读写 xls
package XLS::Simple;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(write_xls read_xls);

our $VERSION=0.02;

use Encode;
use Excel::Writer::XLSX;
use Spreadsheet::Read;

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

sub read_xls {
    my ( $xls, %opt ) = @_;

    my $workbook = ReadData($xls);

    my @data =
      $opt{only_header}
      ? Spreadsheet::Read::cellrow( $workbook->[1], 1 )
      : Spreadsheet::Read::rows( $workbook->[1] );

    shift @data if ( $opt{skip_header} );

    return \@data;
}

1;


=pod

=encoding utf8

=head1 名称

L<XLS::Simple> xls读取写入

=head1 函数

=begin html

实例参考<a href="xt/">xt子文件夹</a>

=end html

=head2 write_xls

写入xls

    write_xls([ ['测试', '写入' ] ], 
        'test.xlsx', 
        header=> ['一二', '三四'], 
        charset=>'utf8');

=head2 read_xls

读取xls

    my $header = read_xls( 'test.xlsx', only_header => 1, );

    my $data = read_xls( 'test.xlsx', skip_header => 1, );

    my $all = read_xls( 'test.xlsx', );

=cut
