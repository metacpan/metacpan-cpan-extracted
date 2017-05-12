package App::Tables::Excel;
BEGIN { die "Your perl version is old, see README for instructions" if $] < 5.005; }

use strict;
use Data::Table;
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use Excel::Writer::XLSX;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

use Exporter 'import';

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = ();
@EXPORT_OK = qw(
  tables2xls xls2tables tables2xlsx xlsx2tables 
  tables_from_file
);

sub xls2tables {
  my ($fileName, $sheetNames, $sheetIndices) = @_;
  return excelFileToTable($fileName, $sheetNames, $sheetIndices, '2003');
}

sub xlsx2tables {
  my ($fileName, $sheetNames, $sheetIndices) = @_;
  return excelFileToTable($fileName, $sheetNames, $sheetIndices, '2007');
}

sub H_BUILT { 1 }
sub H_READ  { 2 }
sub H_GUESS { 3 }

sub excelFileToTable {
  my ($fileName, $sheetNames, $sheetIndices, $excelFormat, $headers_are ) = @_;
  for my $h ($headers_are) {
      $h = 
      $h eq 'built'  ? H_BUILT :
      $h eq 'read'   ? H_READ  :
      $h eq 'guess'  ? H_GUESS :
      $h;
      ($h > 0) && ($h < 4) or die;
  }

  my %sheetsName = ();
  my %sheetsIndex = ();
  if (defined($sheetNames) && ref($sheetNames) eq 'ARRAY') {
    foreach my $name (@$sheetNames) {
      $sheetsName{$name} = 1;
    }
  } elsif (defined($sheetIndices) && ref($sheetIndices) eq 'ARRAY') {
    foreach my $idx (@$sheetIndices) {
      $sheetsIndex{$idx} = 1;
    }
  }
  my $excel = undef;
  if ($excelFormat eq '2003') {
    $excel = Spreadsheet::ParseExcel::Workbook->Parse($fileName);
  } elsif ($excelFormat eq '2007') {
    $excel = Spreadsheet::XLSX->new($fileName);
  } else {
    croak "Unrecognized Excel format, must be either 2003 or 2007!";
  }
  my @tables = ();
  my @sheets = ();
  my $num = 0;
  foreach my $sheet (@{$excel->{Worksheet}}) {
    $num++;
    next if ((scalar keys %sheetsName) && !defined($sheetsName{$sheet->{Name}}));
    next if ((scalar keys %sheetsIndex) && !defined($sheetsIndex{$num}));
    next unless defined($sheet->{MinRow}) && defined($sheet->{MaxRow}) && defined($sheet->{MinCol}) && defined($sheet->{MaxRow});
    push @sheets, $sheet->{Name};
    #printf("Sheet: %s\n", $sheet->{Name});
    $sheet->{MaxRow} ||= $sheet->{MinRow};
    $sheet->{MaxCol} ||= $sheet->{MinCol};
    my @header = ();
    foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
      my $cel=$sheet->{Cells}[$sheet->{MinRow}][$col];
      push @header, defined($cel)?$cel->{Val}:undef;
    }

    my $t = do {
        my $h = $headers_are;
        $h == H_GUESS and $h = do {
            my $d =  $Data::Table::DEFAULTS{CSV_DELIMITER};
            my $s = join $d, map {Data::Table::csvEscape($_)} @header;
            (Data::Table::fromFileIsHeader $s, $d)
            ? H_READ : H_BUILT
        };
        if    ( $h == H_READ  ) { Data::Table->new( [], \@header, 0) }
        elsif ( $h == H_BUILT ) {
          Data::Table->new
          ( [\@header]
          , [ map "col$_", 1..($sheet->{MaxCol}-$sheet->{MinCol}+1) ]
          , 0 );
        }
        else { die }
    };

    foreach my $row (($sheet->{MinRow}+1) .. $sheet->{MaxRow}) {
      my @one = ();
      foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
        my $cel=$sheet->{Cells}[$row][$col];
        push @one, defined($cel)?$cel->{Val}:undef;
      }
      $t->addRow(\@one);
    }
    push @tables, $t;
  }
  return (\@tables, \@sheets);
}

sub tables_from_file {
    my ( $file, %with ) = @_;
    $with{headers_are} ||= 'built';
    $with{format} ||= do {
        $file =~ /[.]((xls)x)$/;
        $1 ? 2007 :
        $2 ? 2003 : die "can't guess the excel version";
    };
    for (qw( names indices )) { $with{$_} ||= undef }
    excelFileToTable $file
    , @with{qw( names indices format headers_are )};
}

# color palette is defined in
# http://search.cpan.org/src/JMCNAMARA/Spreadsheet-WriteExcel-2.20/doc/palette.html
sub oneTable2Worksheet {
  my ($workbook, $t, $name, $colors, $portrait) = @_;
  # Add a worksheet
  my $worksheet = $workbook->add_worksheet($name);
  $portrait=1 unless defined($portrait);
  #my @BG_COLOR=(26,47,44);
  my @BG_COLOR=(44, 9, 30);
  @BG_COLOR=@$colors if ((ref($colors) eq "ARRAY") && (scalar @$colors==3));
  my $fmt_header= $workbook->add_format();
  $fmt_header->set_bg_color($BG_COLOR[2]);
  $fmt_header->set_bold();
  $fmt_header->set_color('white');
  my $fmt_odd= $workbook->add_format();
  $fmt_odd->set_bg_color($BG_COLOR[0]);
  my $fmt_even= $workbook->add_format();
  $fmt_even->set_bg_color($BG_COLOR[1]);
  my @FORMAT = ($fmt_odd, $fmt_even);

  my @header=$t->header;
  if ($portrait) {
    for (my $i=0; $i<@header; $i++) {
      $worksheet->write(0, $i, $header[$i], $fmt_header);
    }
    for (my $i=0; $i<$t->nofRow; $i++) {
      for (my $j=0; $j<$t->nofCol; $j++) {
        $worksheet->write($i+1, $j, $t->elm($i,$j), $FORMAT[$i%2]);
      }
    }
  } else {
    for (my $i=0; $i<@header; $i++) {
      $worksheet->write($i, 0, $header[$i], $fmt_header);
    }
    for (my $i=0; $i<$t->nofRow; $i++) {
      for (my $j=0; $j<$t->nofCol; $j++) {
        $worksheet->write($j, $i+1, $t->elm($i,$j), $FORMAT[$i%2]);
      }
    }
  }
}

sub tables2excelFile {
  my ($fileName, $tables, $names, $colors, $portrait, $excelFormat) = @_;
  confess("No table is specified!\n") unless (defined($tables)&&(scalar @$tables));
  $names =[] unless defined($names);
  $colors=[] unless defined($colors);
  $portrait=[] unless defined($portrait);
  my $workbook = undef;
  if ($excelFormat eq '2003') {
    $workbook = Spreadsheet::WriteExcel->new($fileName);
  } elsif ($excelFormat eq '2007') {
    $workbook = Excel::Writer::XLSX->new($fileName);
  } else {
    croak "Unrecognized Excel format, must be either 2003 or 2007!";
  }
  $portrait=[] unless defined($portrait);
  my ($prevColors, $prevPortrait) = (undef, undef);
  for (my $i=0; $i<@$tables; $i++) {
    my $myColor=$colors->[$i];
    $myColor=$prevColors if (!defined($myColor) && defined($prevColors));
    $prevColors=$myColor;
    my $myPortrait=$portrait->[$i];
    $myPortrait=$prevPortrait if (!defined($myPortrait) && defined($prevPortrait));
    $prevPortrait=$myPortrait;
	my $mySheet = $names->[$i] ? $names->[$i]:"Sheet".($i+1);
    oneTable2Worksheet($workbook, $tables->[$i], $mySheet, $myColor, $myPortrait);
  }
}

sub tables2xls {
  my ($fileName, $tables, $names, $colors, $portrait) = @_;
  tables2excelFile($fileName, $tables, $names, $colors, $portrait, '2003');
}

sub tables2xlsx {
  my ($fileName, $tables, $names, $colors, $portrait) = @_;
  tables2excelFile($fileName, $tables, $names, $colors, $portrait, '2007');
}

1;

__END__


=head1 NAME

Data::Table::Excel - Convert between Data::Table objects and Excel (xls/xlsx) files.

=head1 SYNOPSIS
  
  News: The package now includes "Perl Data::Table Cookbook" (PDF), which may serve as a better learning material.
  To download the free Cookbook, visit https://sites.google.com/site/easydatabase/

  use Data::Table::Excel qw (tables2xls xls2tables tables2xlsx xlsx2tables);

  # read in two CSV tables and generate an Excel .xls binary file with two spreadsheets
  my $t_category = Data::Table::fromFile("Category.csv");
  my $t_product = Data::Table::fromFile("Product.csv");
  # the workbook will contain two sheets, named Category and Product
  # parameters: output file name, an array of tables to write, and their corresponding names
  tables2xls("NorthWind.xls", [$t_category, $t_product], ["Category","Product"]);

  # read in NorthWind.xls file as two Data::Table objects
  my ($tableObjects, $tableNames)=xls2tables("NorthWind.xls");
  for (my $i=0; $i<@$tableNames; $i++) {
    print "*** ". $tableNames->[$i], " ***\n";
    print $tableObjects->[$i]->csv;
  }

  Outputs:
  *** Category ***
  CategoryID,CategoryName,Description
  1,Beverages,"Soft drinks, coffees, teas, beers, and ales"
  2,Condiments,"Sweet and savory sauces, relishes, spreads, and seasonings"
  3,Confections,"Desserts, candies, and sweet breads"
  ...
  
  *** Product ***
  ProductID,ProductName,CategoryID,UnitPrice,UnitsInStock,Discontinued
  1,Chai,1,18,39,FALSE
  2,Chang,1,19,17,FALSE
  3,Aniseed Syrup,2,10,13,FALSE
  ...

  # to deal with Excel 2007 format (.xlsx), use xlsx2tables instead.
  # since no table name is supplied, they will be named Sheet1 and Sheet2.
  # here we also provide custom colors for each sheet, color array is for [OddRow, EvenRow, HeaderRow]

  tables2xlsx("NorthWind.xlsx", [$t_category, $t_product], undef, [['silver','white','black'], [45,'white',37]]);
  # read in NorthWind.xlsx file as two Data::Table objects
  my ($tableObjects, $tableNames)=xlsx2tables("NorthWind.xlsx");
  # note: Spreadsheet::XLSX module is used to parse .xlsx file. Please make sure it is updated.

=head1 ABSTRACT

This perl package provide utility methods to convert between an Excel file and Data::Table objects. It then enables you to take advantage of the Data::Table methods to further manipulate the data and/or export it into other formats such as CSV/TSV/HTML, etc.

=head1 DESCRIPTION

=over 4

To read and write Excel .xls (2003 and prior) format, we use Spreadsheet::WriteExcel and Spreadsheet::ParseExcel; to read and write Excel .xlsx (2007 format),
we use Spreadsheet::XLSX and Excel::Writer::XLSX.  If this module gives incorrect results, please check if the corresponding Perl modules are updated.

=item xls2tables ($fileName, $sheetNames, $sheetIndices) 

=item xlsx2tables ($fileName, $sheetNames, $sheetIndices)

xls2tables is for reading Excel .xls files (binary, 2003 and prior), xlsx2table is for reading .xlsx file (2007, compressed XML format).

$fileName is the input Excel file.
$sheetNames is a reference to an array of sheet names.
$sheetIndices is a reference to an array of sheet indices.
If neither $sheetNames or $sheetIndices is provides, all sheets are converted into table objects, one table per sheet.
If $sheetNames is provided, only sheets found in the @$sheetNames array is converted.
If $sheetIndices is provided, only sheets match the index in the @$sheetIndices array is converted (notice the first spreadsheet has an index of 1).

The method returns an array ($tableObjects, $tableNames).
$tableObjects is a reference to an array of Data::Table objects.
$tableNames is a reference to an array of sheet names, corresponding to $tableObjects.

  # print each of spreadsheet into an HTML table on the web
  ($tableObjects, $tableNames)=xls2tables("Tables.xls");
  foreach my $t (@$tableObjects) {
    print "<h1>", shift @$tableNames, "</h1><br>";
    print $t->html;
  }

  ($tableObjects, $tableNames)=xlsx2tables("Tables.xlsx", undef, [1]);

This will only read the first sheet. By providing sheet names or sheet indicies, you save time if you are not interested in all the sheets.

=item tables2xls ($fileName, $tables, $names, $colors, $portrait) 

=item tables2xlsx ($fileName, $tables, $names, $colors, $portrait) 

table2xls is for writing Excel .xls files (binary, 2003 and prior), xlsx2table is for writing .xlsx file (2007, compressed XML format).

$fileName is used to name the output Excel file.
$tables is a reference to an array of Data::Table objects to be write into the file, one sheet per table.
$names is a reference to an array of names used to name Spreadsheets, if not provided, it uses "Sheet1", "Sheet2", etc.
$colors is a reference to an array of reference to a color array.
Each color array has to contains three elements, defining Excel color index for odd rows, even rows and header row. 
Acceptable color index (or name) is defined by the docs\palette.html file in the CPAN Spreadsheet::WriteExcel package.

$portrait is a reference to an array of orientation flag (0 or 1), 1 is for Portrait (the default), where each row represents a table row.  In landscape (0) mode, each row represents a column.  (Similar to Data::Table::html and Data::Table::html2).

The arrays pointed by $names, $colors and $portraits should be the same length as that of $tables. these customization values are applied to each table objects sequentially.
If a value is missing for a table, the method will use the setting from the previous table.

  tables2xls("TwoTables.xls", [$t_A, $t_B], ["Table_A","Table_B"], [["white","silver","gray"], undef], [1, 0]);

This will produce two spreadsheets named Table_A and Table_B for table $t_A and $t_B, respectively.  The first table is colored in a black-white style, the second is colored by the default style.
The first table is the default portrait oritentation, the second is in the transposed orientation.

=back

=head1 AUTHOR

Copyright 2008, Yingyao Zhou. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
  
Please send bug reports and comments to: easydatabase at gmail dot com. When sending
bug reports, please provide the version of Data::Table::Excel.pm, the version of
Perl.

=head1 SEE ALSO

  Data::Table.

=cut


