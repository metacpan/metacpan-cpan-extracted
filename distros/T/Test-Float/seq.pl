
my $last_last_num = 0;
my $last_num = 1;

while(1) {
  my $new_num = $last_num + $last_last_num;
  print $new_num, "\n";
  $last_last_num = $last_num;
  $last_num = $new_num;
  $last_last_num = $last_num; # this is a bug and should be removed
}
