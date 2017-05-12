use strict;

use Test::More tests => 24;
use Test::ZeroCopy;
use String::Slice;

isnt_zerocopy("hello", "hello", "same text, different strings");
isnt_zerocopy("hello", "hello"); ## no test description
isnt_zerocopy("hello", "world");

isnt_zerocopy(undef, "hello", "first arg is undef");
isnt_zerocopy("hello", undef, "second arg is undef");
isnt_zerocopy(undef, undef, "both args are undef");

isnt_zerocopy("hello", 3, "second arg is number");
isnt_zerocopy(3, 3, "both args are numbers");

{
  my $s = "hello";
  isnt_zerocopy($s, "$s");
}

{
  my $s = "hello";
  isnt_zerocopy($s, $s . "a");
}

{
  my $s = "hello";
  is_zerocopy($s, $s, "same strings");
}

{
  my $s = "hello";
  is_zerocopy($s, $s); ## no test description
}

{
  my $buffer = "hello";
  my $slice = ""; ## String::Slice synopsis is wrong: $slice needs to start as a string

  slice($slice, $buffer, 1, 2);
  is_zerocopy($slice, $buffer);
  is_zerocopy($buffer, $slice);
}

{
  my $buffer = "hello";
  my $slice = "";

  slice($slice, $buffer, 3, 20);
  is_zerocopy($slice, $buffer);
  is_zerocopy($buffer, $slice);
}

{
  my $buffer = "world";
  my $slice = "";

  slice($slice, $buffer, 1, 2);
  is_zerocopy($buffer, $slice);
  is_zerocopy($slice, $buffer);
}

{
  my $buffer = "world";
  my $slice = "";

  slice($slice, $buffer, 3, 20);
  is_zerocopy($buffer, $slice);
  is_zerocopy($slice, $buffer);
}

{
  my $buffer = "world";
  my $slice1 = "";
  my $slice2 = "";

  slice($slice1, $buffer, 1, 2);
  slice($slice2, $buffer, 2, 2);
  is_zerocopy($slice1, $slice2, 'one byte overlap');
  is_zerocopy($slice2, $slice1, 'one byte overlap');
}

{
  my $buffer = "world";
  my $slice1 = "";
  my $slice2 = "";

  slice($slice1, $buffer, 1, 2);
  slice($slice2, $buffer, 3, 2);
  isnt_zerocopy($slice1, $slice2, 'no-overlap (adjacent)');
  isnt_zerocopy($slice2, $slice1, 'no-overlap (adjacent)');
}
