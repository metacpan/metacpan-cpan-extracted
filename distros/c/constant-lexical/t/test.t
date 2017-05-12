#!perl -w

use Test::More tests => 18;
use constant::lexical;

{
	{
		use constant::lexical CAKE => 3.14;
		is CAKE, 3.14, 'within a constant\'s scope';
		eval '';
	}
	use constant::lexical { _foo => 1, _bar => 2 };
	use constant::lexical _baz => 3,4,5;

	is_deeply [_foo, _bar], [1,2],
		'within the scope of constants created with a hash';
	is_deeply [_baz], [3,4,5], 'within a list constant\'s scope';

	is CAKE, "CAKE", 'outside a constant\'s scope';
}
is_deeply [_foo, _bar], [_foo=>_bar=>],
	'outside the scope of constants created with a hash';
is_deeply [_baz], ["_baz"], 'outside a list constant\'s scope';

use constant thing => 34;
sub thang { 78 }
{
	use constant::lexical thing => 45;
	use constant::lexical thang => 79;
	is thing, 45, 'overridden constant';
	is thang, 79, 'overridden sub';
	BEGIN { @thing = 1 }
}
is thang, 78, 'overridden sub restored';
is thing, 34, 'overridden constant restored';
is ${'thing'}[0], 1,'and other glot slobs untouched';

SKIP: {
  skip "only works in perl 5.11.2 and higher", 5 if $] < 5.011002;
  no warnings;
  use constant::lexical "splext" => "ved";
  package Snit;
  ::is splext, "ved", "constants span package boundaries";
  ::is main::splext, "main::splext", "Fully-qualified constants fail";
  ::is eval "splext", "ved", "evals can see constants";
  use constant::lexical "sclat" => [];
  ::is eval "ref sclat", "ARRAY", "refs and what-not survive into evals";
  eval '
   sub grile { return eval{&{"splew"}} }
   {
    use constant::lexical splew => "sclor";
    BEGIN{::is grile, undef, "constants are not just sub localisations"};
   }
 ';
}

# Something I almost broke in version 2:
{package ctelp; sub dreen { "grare" } }
{
 use constant'lexical 'dreen' => 'fing';
 is eval 'dreen ctelp', 'grare',
  'constant does not override method of known package';

# And another:
 is eval { &dreen }, 'fing', '& notation';
}
