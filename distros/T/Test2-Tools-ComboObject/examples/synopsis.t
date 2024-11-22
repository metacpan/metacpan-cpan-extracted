use Test2::V0;
use Test2::Tools::ComboObject;
use feature qw( signatures );

sub my_test_tool ($test_name //='my test tool', @numbers) {
  my $combo = combo $test_name;
  foreach my $number (@numbers) {
    if($number % 2) {
      $combo->fail("$number is not even");
    } else {
      $combo->pass;
    }
  }
  return $combo->finish;
}

my_test_tool undef, 4, 6, 8, 9, 100, 200, 300, 9999, 2859452842;
my_test_tool 'try again', 2, 4, 6, 8;

done_testing;