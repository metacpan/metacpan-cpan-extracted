use strict;
use utf8;
use warnings;
use common::sense;
use Test::More tests => 6;

use Unicode::NoFancyPants qw(dropFancyPants);
my ($input,@inputs,$result,@results);

$input = "Hello, “world”!";
$result = dropFancyPants($input);
is ($result, 'Hello, "world"!');

# Test 1: Single string conversion
$input="This is a test—with “fancy” quotes! 😊";
$result = dropFancyPants($input);
is($result, "This is a test-with \"fancy\" quotes! :-)", 
  "Single string conversion");

# Test 2: Array of strings conversion
@inputs=("String 1: 😃", "String 2: 😞");
@results = dropFancyPants(@inputs);
is_deeply(\@results, ["String 1: :-D", "String 2: :-("], "Array of strings conversion");

#Test 3: Testing the recursive aspect of the sub.
@inputs=("String 1: 😃", "String 2: 😞");
@results = dropFancyPants(@inputs);
is_deeply(\@results, ["String 1: :-D", "String 2: :-("], "Array of strings conversion (recursive array)");

#Test 4: Add a level of indirection
@inputs=([@inputs]);
@results = dropFancyPants(@inputs);
is_deeply(\@results, [["String 1: :-D", "String 2: :-("]], "Add a level of indirection");

#Test 5: Add another level of indirection
@inputs=([@inputs]);
@results = dropFancyPants(@inputs);
is_deeply(\@results, [[["String 1: :-D", "String 2: :-("]]], "Add another level of indirection");
