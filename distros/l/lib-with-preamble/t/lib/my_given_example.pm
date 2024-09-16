package my_given_example;

sub example_sub {
  state $foo = $_[0];
}

sub my_file { __FILE__ }
sub my_line { __LINE__ }

1;
