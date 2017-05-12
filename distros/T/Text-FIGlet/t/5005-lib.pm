sub eq_or_diff{
  ok( ($_[0] eq $_[1]), $_[2]);
}

sub ok{
  printf( "%sok %i $_[1]\n", ($_[0] ? '': 'not '), , ++$main::TESTS);
}

sub like{
  ok( ($_[0] =~ $_[1]), $_[2]);
}
1;
