use strict;
my $tests_run = 0;

my @tests = (
  sub {eval("require Tie::Static;") ? "" : "not "},
  setup_tests(\&test_array, [], [1..3], [4..6], [7..9]),
  setup_tests(\&test_hash, [], [1,2], [3,4], [5,6]),
  setup_tests(\&test_scalar, [undef], ["hello"], ["world"], ["done"]),
);

print "1..", scalar @tests, "\n";
foreach my $test (@tests) {
  run_test($test);
}

sub ret_test {
  my $test_func = shift;
  my $mode = shift;
  my $expect = shift;
  my $args = shift;
  return sub {
    my @result = $test_func->($mode, @$args);
    return "@result" eq "@$expect"
      ? ""
      : "not ";
  };
}

sub run_test {
  my $test = shift;
  print $test->(@_);
  $tests_run++;
  print "ok $tests_run\n";
}

sub setup_tests {
  my $test_func = shift;
  my $init_val = shift;
  my $args_1 = shift;
  my $args_2 = shift;
  my $final_args = shift;
  return (
    ret_test($test_func, 1, $init_val, $args_1),
    ret_test($test_func, 2, $init_val, $args_2),
    ret_test($test_func, 1, $args_1, $final_args),
    ret_test($test_func, 2, $args_2, $final_args),
  );
}

sub test_array {
  tie (my @ary, 'Tie::Static', shift);
  my @ret = @ary;
  @ary = @_;
  return @ret;
}

sub test_hash {
  tie (my %hash, 'Tie::Static', shift);
  my @ret = %hash;
  %hash = @_;
  return @ret;
}

sub test_scalar {
  tie (my $scalar, 'Tie::Static', shift);
  my $ret = $scalar;
  $scalar = shift;
  return $ret;
}
