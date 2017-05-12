use Test::More 'tests' => 5;
use lib '../lib';

use_ok('UDCode');
*subtract = \*UDCode::subtract;

is(subtract("", "abb"), "abb");
is(subtract("a", "abb"), "bb");
is(subtract("ab", "abb"), "b");
is(subtract("abb", "abb"), "");

