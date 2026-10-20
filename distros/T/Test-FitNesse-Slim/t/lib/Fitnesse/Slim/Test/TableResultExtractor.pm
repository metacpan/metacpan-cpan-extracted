package Fitnesse::Slim::Test::TableResultExtractor;

sub new {
  my($class) = @_;
  bless {} => $class;
}

sub get_value_from_query_result_symbol {
  my($self,$result,$row,$col) = @_;
  die "row ($row) must be non-negative" if $row < 0;
  die "row ($row) exceeds $#{$result}" if $row > $#{$result};
  my $rowvals = $result->[$row];
  my($pair) = grep $_->[0] eq $col, @$rowvals;
  die "column ($col) not found in row $row" unless $pair;
  $pair->[1];
}

sub get_value_from_table_result_symbol {
  my($self,$result,$i,$j) = @_;
  die "row ($i) must be non-negative" if $i < 0;
  die "row ($i) exceeds $#{$result}" if $i > $#{$result};
  my $row = $result->[$i];
  die "column ($j) exceeds $#{$row}" if $j > $#{$row};
  $row->[$j];
}

1;
