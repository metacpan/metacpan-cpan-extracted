use strict;
use warnings;
use Test::More;

my @imports;
BEGIN {
  @imports = qw(
    true
    false
    is_bool
    weaken
    unweaken
    is_weak
    blessed
    refaddr
    reftype
    created_as_string
    created_as_number
    ceil
    floor
    trim
    indexed
  );

}

BEGIN {
  use builtin::compat @imports;

  BEGIN {
    for my $import (@imports) {
      no strict 'refs';
      my $ref = eval "\\&$import";
      ok defined &$ref, "$import imported from builtin::compat";
    }
  }
}

BEGIN {
  for my $import (@imports) {
    no strict 'refs';
    ok !defined &$import, "$import doesn't exist after end of scope";
  }
}

BEGIN {
  for my $import (@imports) {
    no strict 'refs';
    ok defined &{"builtin::compat::$import"}, "builtin::compat::$import exists";
    ok defined &{"builtin::$import"}, "builtin::$import exists";
  }
}

BEGIN {
  use builtin @imports;

  BEGIN {
    for my $import (@imports) {
      no strict 'refs';
      my $ref = eval "\\&$import";
      ok defined &$ref, "$import imported from builtin";
    }
  }
}

BEGIN {
  for my $import (@imports) {
    no strict 'refs';
    ok !defined &$import, "$import doesn't exist after end of scope";
  }
}

use builtin::compat @imports;

ok true, 'true';
ok !false, 'false';

ok is_bool(true), 'is_bool(true)';
ok is_bool(false), 'is_bool(false)';
ok !is_bool(1), '!is_bool(1)';
ok !is_bool("1"), '!is_bool("1")';
ok !is_bool(0), '!is_bool(0)';
ok !is_bool(''), '!is_bool("")';

{
  my $ref;
  {
    my $var = 5;
    $ref = \$var;
    weaken($ref);
  }
  is $ref, undef, 'weaken';
}

{
  my $ref;
  {
    my $var = 5;
    $ref = \$var;
    weaken($ref);
    unweaken($ref);
  }
  ok ref $ref, 'unweaken';
}

{
  my $ref;
  {
    my $var = 5;
    $ref = \$var;
    ok !is_weak($ref), 'is_weak($normal_ref)';

    weaken($ref);

    ok is_weak($ref), 'is_weak($weak_ref)';
  }
}

my $o = bless {}, 'MyPackage';

is blessed $o, 'MyPackage', 'blessed';
is refaddr $o, 0+$o, 'refaddr';
is reftype $o, 'HASH', 'reftype';

ok created_as_string(""), 'created_as_string("")';
ok !created_as_string(0), '!created_as_string(0)';
ok !created_as_string(true), '!created_as_string(true)';
my $number = 5;
my $used_as_string = "$number";
ok !created_as_string($number), '!created_as_string($number_used_as_string)';
my $string = "01234";
my $used_as_number = 0+$string;
ok created_as_string($string), 'created_as_string($string_used_as_number)';

ok !created_as_number(""), '!created_as_number("")';
ok created_as_number(0), 'created_as_number(0)';
ok !created_as_number(true), '!created_as_number(true)';
ok created_as_number($number), 'created_as_number($number_used_as_string)';
ok !created_as_number($string), 'created_as_number($string_used_as_number)';

is ceil(1.2), 2, 'ceil(1.2)';
is floor(1.2), 1, 'floor(1.2)';

is trim("  \t  hi   \t   ho   \n\n\n   "), "hi   \t   ho", 'trim';
is_deeply [indexed 13..16], [0, 13, 1, 14, 2, 15, 3, 16], 'indexed';

done_testing;
