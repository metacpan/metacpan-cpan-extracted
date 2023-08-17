#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Output qw(output_from);

use lib qw{lib};

use_ok 'Text::ASCIITable::EasyTable';

my @data = (
  { Col1 => 'foo', Col2 => 'bar' },
  { Col1 => 'biz', Col2 => 'buz' },
  { Col1 => 'fuz', Col2 => 'biz' },
);

########################################################################
subtest 'just data' => sub {
########################################################################
  my $t = easy_table( data => \@data );

  my ($stdout) = output_from( sub { print {*STDOUT} $t; } );

  like(
    $stdout,
    qr/\A[+\- .|\n]+\sTable\s/xsm,
    'heading has default title - "Table"'
  );

  # order of hash keys not guaranteed
  like(
    $stdout,
    qr/^[+\- .|\n]+\sCol[12][ |]+Col[12]/xsm,
    'column headings use keys'
  );

  my $row_count = () = $stdout =~ /[+\- .|\n]+\sCol[12][ |]+Col[12]/xsmg;

  is( $row_count, 1, '1 header' );
};

########################################################################
subtest 'custom header' => sub {
########################################################################
  my $t = easy_table(
    data          => \@data,
    table_options => { headingText => 'Title' },
  );

  my ($stdout) = output_from( sub { print {*STDOUT} $t; } );

  like( $stdout, qr/\A[+\- .|\n]+\sTitle\s/xsm, 'heading has custom title' )
    or diag($stdout);

};

########################################################################
subtest 'custom columns names' => sub {
########################################################################
  my $t = easy_table(
    data => \@data,
    rows => [
      Foo => 'Col1',
      Bar => 'Col2',
    ],
  );

  my ($stdout) = output_from( sub { print {*STDOUT} $t; } );

  like( $stdout, qr/^[+\- .|\n]+\sFoo[ |]+Bar/xsm, 'custom column headings' );
};

########################################################################
subtest 'custom column values' => sub {
########################################################################
  my $col_transformer = sub { "$_[0]:" . uc $_[0]; };

  my $t = easy_table(
    data => \@data,
    rows => [
      Foo => sub { $col_transformer->( shift->{Col1} ) },
      Bar => sub { $col_transformer->( shift->{Col2} ) },
    ],
  );

  my ($stdout) = output_from( sub { print {*STDOUT} $t; } );

  like(
    $stdout,
    qr/^[+\- .|\n]+\s[[:lower:]:[[:upper:]]+/xsm,
    'columns transformed'
  );

  my $row_count = () = $stdout =~ /[ |]?[[:lower:]]+:[[:upper:]]+[ |]+/xsmg;

  is( $row_count, 6, 'all rows transformed' )
    or diag($stdout);
};

########################################################################
subtest 'custom column values or default' => sub {
########################################################################
  my $col_transformer = sub { "$_[0]:" . uc $_[0]; };

  my $t = easy_table(
    data => \@data,
    rows => [
      Foo => sub { $col_transformer->( shift->{Col1} ) },
      Bar => 'Col2',
    ],
  );

  my ($stdout) = output_from( sub { print {*STDOUT} $t; } );

  like(
    $stdout,
    qr/^[+\- .|\n]+\s[[:lower:]:[[:upper:]]+/xsm,
    'columns transformed'
  );

  my $row_count = () = $stdout =~ /[ |]?[[:lower:]]+:[[:upper:]]+[ |]+/xsmg;

  is( $row_count, 3, 'just columns transformed' )
    or diag($stdout);
};

########################################################################
subtest 'horizontal line' => sub {
########################################################################
  my $t = easy_table( data => [ @data[ ( 0, 1, 1, 2 ) ], undef, $data[2] ], );

  my ($stdout) = output_from( sub { print {*STDOUT} $t; } );

  my $line_count = 0;

  while ( $stdout =~ /[+]------[+]------[+]$/gxsm ) {
    ++$line_count;
  }

  is( $line_count, 3, '3 lines' );
};

1;

__END__
