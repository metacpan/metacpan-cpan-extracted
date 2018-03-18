use strict;
use warnings;
use Test::More 0.88;
use Test::Exception;

use YAML::Dump qw< Dump INDENT >;

my $obj1 = bless {what => 'ever', you => 'do'}, 'Whatever';
my $obj2 = bless [1..4], 'Some::Thing';
my $obj3 = bless {}, 'Un::Known';
my $circular = { some => {thing => undef} };
$circular->{some}{thing} = $circular;

my ($true, $false) = get_booleans();

my @ok_tests = (
   # "scalars", or empty stuff
   [string => 'ciao', "--- ciao\n"],
   [integer => 72, "--- 72\n"],
   [string_integer => '72', "--- '72'\n"],
   [null => undef, "---\n"],
   [false => \0, "--- false\n"],
   [true => \1, "--- true\n"],
   ['false (object)' => $false, "--- false\n"],
   ['true (object)' => $true, "--- true\n"],
   ['empty array' => [], "--- []\n"],
   ['empty hash' => {}, "--- {}\n"],

   # array
   [
      'complex array at root' => [
         1..3, \1, 4, $false,
         { some => 'thing', and => [qw< another array >] }
      ],
      [
      "---
- 1
- 2
- 3
- true
- 4
- false
- some: thing
  and:
    - another
    - array
",
      "---
- 1
- 2
- 3
- true
- 4
- false
- and:
    - another
    - array
  some: thing
",
      ]
   ],

   [
      'complex hash at root' => {
         ciao => 'a tutti',
         and => [ 1..3, \1, 4, $false, { some => 'thing' } ],
      },
      [
         "---
and:
  - 1
  - 2
  - 3
  - true
  - 4
  - false
  - some: thing
ciao: 'a tutti'
",
         "---
ciao: 'a tutti'
and:
  - 1
  - 2
  - 3
  - true
  - 4
  - false
  - some: thing
",
      ]
   ],

   [
      'array with array' => [[1..2], [3..5]],
      '---
-
  - 1
  - 2
-
  - 3
  - 4
  - 5
'
   ],

   [
      'array with supported objects' => [$obj1, $obj2],
      [
         '---
- you: do
  what: ever
- 1: 2
  3: 4
',
         '---
- what: ever
  you: do
- 1: 2
  3: 4
'
      ],
   ],

   [
      'Directed Acyclic Graph' => { one => $obj2, two => $obj2 },
      [
         '---
one:
  1: 2
  3: 4
two:
  1: 2
  3: 4
',
         '---
two:
  1: 2
  3: 4
one:
  1: 2
  3: 4
'
      ],
   ],
);
for my $ok_test (@ok_tests) {
   my ($name, $data, $expected) = @$ok_test;
   my $got;
   lives_ok { $got = Dump($data) } "$name lives";
   if (ref $expected) {
      my $e;
      for (@$expected) {
         $e = $_;
         last if $e eq $got;
      }
      is $got, $e, "$name result";
   }
   else {
      is $got, $expected, "$name result";
   }
}

my @ko_tests = (
   [ 'unsupported SCALAR reference' => \2, qr{SCALAR} ],
   [ 'unsupported GLOB reference' => \*STDERR, qr{GLOB} ],
   [ 'unsupported object' => $obj3, qr{Un::Known} ],
   [ 'circular reference' => $circular, qr{circular} ],
);
for my $ko_test (@ko_tests) {
   my ($name, $data, $error) = @$ko_test;
   throws_ok { Dump($data) } $error, "$name complains";
}


sub YAML::Dump::dumper_for_unknown {
   my ($self, $element, $line, $indent, $seen) = @_;
   my $type = ref $element;


   return {%$element} if $type eq 'Whatever';

   if ($type eq 'Some::Thing') {
      my $i = INDENT x $indent;
      my @e = @$element;
      my @ls;
      while (@e) {
         my ($k, $v) = splice @e, 0, 2;
         push @ls, $i . "$k: $v";
      }
      if ($line =~ m{-\s*$}mxs) {
         substr $ls[0], 0, length($line), $line;
      }
      else {
         unshift @ls, $line;
      }
      return @ls;
   }

   die \"Unknown type $type";
}


done_testing;

sub get_booleans {
#eval { require JSON::PP } and return;
   eval <<'END';
package JSON::PP::Boolean;
use overload (
   "0+"     => sub { my $x = ${$_[0]} },
   fallback => 1,
); 
package JSON::PP;
$JSON::PP::true  = do { bless \(my $dummy = 1), "JSON::PP::Boolean" };
$JSON::PP::false = do { bless \(my $dummy = 0), "JSON::PP::Boolean" };
sub true  { $JSON::PP::true  }
sub false { $JSON::PP::false }
END
   return (JSON::PP::true(), JSON::PP::false());
}
