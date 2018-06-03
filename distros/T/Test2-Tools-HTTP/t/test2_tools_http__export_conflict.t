use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP;

my %v0 = map { $_ => 1 } @Test2::V0::EXPORT;

subtest 'default' => sub {

  foreach my $export (sort @Test2::Tools::HTTP::EXPORT)
  {
    is( $v0{$export}, U(), "Test2::V0 does not export $export" );
  }
};

subtest ':short' => sub {

  foreach my $export (sort @{ $Test2::Tools::HTTP::EXPORT_TAGS{'short'} })
  {
    is( $v0{$export}, U(), "Test2::V0 does not export $export" );
  }
};

done_testing;
