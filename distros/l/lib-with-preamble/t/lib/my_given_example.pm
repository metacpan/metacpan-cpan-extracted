package my_given_example;

sub example_sub {
  given ($_[0]) {
    when ($_ > 0) { return 'positive' }
    when ($_ < 0) { return 'negative' }
    return 'zero'
  }
}

sub my_file { __FILE__ }
sub my_line { __LINE__ }

1;
