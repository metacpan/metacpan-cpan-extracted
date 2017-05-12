#!perl -wT

use lib 't';
use Test::More tests =>
	+1  # use
	+14 # tie to obj
	+15 # is_tied
	+14 # weak_tie
	+7  # is_tied again (stale ties)
	+16 # weaken_tie
	+28 # is_weak_tie
	+1  # $@
	+1  # weak_tie retval
	+10 # tie to non-obj
	+1  # tied
	+2  # fix_tie
;
use Symbol 'geniosym';

BEGIN { use_ok 'Tie::Util' };

no warnings 'once';

{ package overloaded;
	use overload fallback => 1,
	'${}' => sub { \my $v },
	'@{}' => sub { [] },
	'%{}' => sub { +{} },
	'&{}' => sub { my $v; sub { $v } },
	'*{}' => sub { \*oeutnhnoetunhnt },
	 bool => sub{0};
	*TIESCALAR = *TIEHASH = *TIEARRAY = *TIEHANDLE =
	sub { bless $_[1] };

#	# This makes overload::Method return false:
#	bless overload::Method(__PACKAGE__, "$_\{}") for qw/ $ @ % & * /;
# But it also makes perl crash. So I suppose I don’t need to be paranoid
# about a case that can’t happen anyway.
}

$} = geniosym; $% = geniosym;
bless $_, 'overloaded'
	for \($~,@~,%~,*~,$%,@%,%%,*%,$`[0],$`{0},*${}},*{$%});
# makes it harder for the functions to get at the tied variable

*TIESCALAR = *TIEHASH = *TIEARRAY = *TIEHANDLE =
	sub { bless $_[1] };

sub UNTIE { ++$untied };

my $obj = bless[];
is tie($~, to => $obj), $obj, 'return value of tie$to';
is tie(@~, to => $obj), $obj, 'return value of tie@to';
is tie(%~, to => $obj), $obj, 'return value of tie%to';
is tie(*~, to => $obj), $obj, 'return value of tie*to';
is tie($`{0}, to => $obj), $obj, 'return value of tie${}to';
is tie($`[0], to => $obj), $obj, 'return value of tie$[]to';
is tie(*${}}, to => $obj), $obj, 'return value of tie*{IO}to';
is tied($~), $obj, 'tie$to works';
is tied(@~), $obj, 'tie@to works';
is tied(%~), $obj, 'tie%to works';
is tied(*~), $obj, 'tie*to works';
is tied($`{0}), $obj, 'tie${}to works';
is tied($`[0]), $obj, 'tie$[]to works';
is tied(*${}}), $obj, 'tie*{IO}to works';

# These lines were making is_tied return true for @% and %%, until
# I fixed it:
tie $%[0], to => $obj;
tie $%{0}, to => $obj;

is is_tied($~), 1, 'is_tied$';
is is_tied(@~), 1, 'is_tied@';
is is_tied(%~), 1, 'is_tied%';
is is_tied(*~), 1, 'is_tied*';
is is_tied($`[0]), 1, 'is_tied$[]';
is is_tied($`{0}), 1, 'is_tied${}';
is is_tied(*${}}), 1, 'is_tied*{IO}';
is is_tied($%), '', '!is_tied$';
is is_tied(@%), '', '!is_tied@';
is is_tied(%%), '', '!is_tied%';
is is_tied(*%), '', '!is_tied*';
is is_tied($@[0]), '', '!is_tied$[]';
is is_tied($@{0}), '', '!is_tied${}';
is is_tied(*{$%}), '', '!is_tied*{IO}';
tie @%, overloaded, bless[],overloaded;
ok is_tied(@%), 'is_tied @tied_to_bool_false_obj';

{	my $foo = bless[0];
	untie$~,untie@~,untie(%~),untie(*~),untie$`[0],untie$`{0},untie*${}};
	weak_tie $~, '', $foo;
	weak_tie @~, '', $foo;
	weak_tie %~, '', $foo;
	weak_tie *~, '', $foo;
	weak_tie $`[0], '', $foo;
	weak_tie $`{0}, '', $foo;
	weak_tie *${}}, '', $foo;
	is tied($~), $foo, 'weak_tie$';
	is tied(@~), $foo, 'weak_tie@';
	is tied(%~), $foo, 'weak_tie%';
	is tied(*~), $foo, 'weak_tie*';
	is tied($`[0]), $foo, 'weak_tie$[]';
	is tied($`{0}), $foo, 'weak_tie${}';
	is tied(*${}}), $foo, 'weak_tie*{IO}'; }
is tied($~), undef, 'weak_tie$ gone stale';
is tied(@~), undef, 'weak_tie@ gone stale';
is tied(%~), undef, 'weak_tie% gone stale';
is tied(*~), undef, 'weak_tie* gone stale';
is tied($`[0]), undef, 'weak_tie$[] gone stale';
is tied($`{0}), undef, 'weak_tie${} gone stale';
is tied(*${}}), undef, 'weak_tie*{IO} gone stale';

is is_tied($~), 1, 'is_tied $stale_tie';
is is_tied(@~), 1, 'is_tied @stale_tie';
is is_tied(%~), 1, 'is_tied %stale_tie';
is is_tied(*~), 1, 'is_tied *stale_tie';
is is_tied($`[0]), 1, 'is_tied $stale[tie]';
is is_tied($`{0}), 1, 'is_tied $stale{tie}';
is is_tied(*${}}), 1, 'is_tied *stale_tie{IO}';

untie($~), untie(@~), untie(%~), untie(*~), untie($`[0]), untie($`{0}), 
untie(*${}});
$untied = 0; # weaken_tie has to clobber the UNTIE method temporarily in
             # the package into which the object to which the variable is
             # tied is blessed.
{	my $foo = bless[0];
	tie $~, '', $foo;
	tie @~, '', $foo; # strong
	tie %~, '', $foo; # ties
	tie *~, '', $foo;
	tie $`[0], '', $foo;
	tie $`{0}, '', $foo;
	tie *${}}, '', $foo;
	weaken_tie $~;    # not
	weaken_tie @~;    # any
	weaken_tie %~;    # more
	weaken_tie *~;
	weaken_tie $`[0];
	weaken_tie $`{0};
	weaken_tie *${}};
	is tied($~), $foo, 'weaken_tie$ before staleness';
	is tied(@~), $foo, 'weaken_tie@ before staleness';
	is tied(%~), $foo, 'weaken_tie% before staleness';
	is tied(*~), $foo, 'weaken_tie* before staleness';
	is tied($`[0]), $foo, 'weaken_tie$[] before staleness';
	is tied($`{0}), $foo, 'weaken_tie${} before staleness';
	is tied(*${}}), $foo, 'weaken_tie*{IO} before staleness'; }
is tied($~), undef, 'weaken_tie$ gone stale and mouldy';
is tied(@~), undef, 'weaken_tie@ gone stale';
is tied(%~), undef, 'weaken_tie% gone stale';
is tied(*~), undef, 'weaken_tie* stalemate';
is tied($`[0]), undef, 'weaken_tie$[] stalemate';
is tied($`{0}), undef, 'weaken_tie${} stalemate';
is tied(*${}}), undef, 'weaken_tie*{IO} stalemate';
is $untied, 0, 'UNTIE is not called inadvertently';
ok defined &UNTIE, 'UNTIE was not inadvertently deleted';

{	my $foo = bless[0];
	untie($~), untie(@~), untie(%~), untie(*~), untie($`[0]), 
	untie($`{0}), untie(*${}});
	tie $~, '', $foo;
	tie @~, '', $foo; # strong
	tie %~, '', $foo; # ties
	tie *~, '', $foo;
	tie $`[0], '', $foo;
	tie $`{0}, '', $foo;
	tie *${}}, '', $foo;
	is is_weak_tie($~), '', 'is_weak_tie$ with strong tie';
	is is_weak_tie(@~), '', 'is_weak_tie@ with strong tie';
	is is_weak_tie(%~), '', 'is_weak_tie% with strong tie';
	is is_weak_tie(*~), '', 'is_weak_tie* with strong tie';
	is is_weak_tie($`[0]), '', 'is_weak_tie$[] with strong tie';
	is is_weak_tie($`{0}), '', 'is_weak_tie${} with strong tie';
	is is_weak_tie(*${}}), '', 'is_weak_tie*{IO} with strong tie';
	weaken_tie $~;    # not
	weaken_tie @~;    # any
	weaken_tie %~;    # more
	weaken_tie *~;
	weaken_tie $`[0];
	weaken_tie $`{0};
	weaken_tie *${}};
	is is_weak_tie($~), 1, 'is_weak_tie$ with weak tie';
	is is_weak_tie(@~), 1, 'is_weak_tie@ with weak tie';
	is is_weak_tie(%~), 1, 'is_weak_tie% with weak tie';
	is is_weak_tie(*~), 1, 'is_weak_tie* with weak tie';
	is is_weak_tie($`[0]), 1, 'is_weak_tie$[] with weak tie';
	is is_weak_tie($`{0}), 1, 'is_weak_tie${} with weak tie';
	is is_weak_tie(*${}}), 1, 'is_weak_tie*{IO} with weak tie'; }
is is_weak_tie($~), '', 'is_weak_tie$ with stale tie';
is is_weak_tie(@~), '', 'is_weak_tie@ with stale tie';
is is_weak_tie(%~), '', 'is_weak_tie% with stale tie';
is is_weak_tie(*~), '', 'is_weak_tie* with stale tie';
is is_weak_tie($`[0]), '', 'is_weak_tie$[] with stale tie';
is is_weak_tie($`{0}), '', 'is_weak_tie${} with stale tie';
is is_weak_tie(*${}}), '', 'is_weak_tie*{IO} with stale tie';
is is_weak_tie($^), undef, 'is_weak_tie$ with no tie';
is is_weak_tie(@^), undef, 'is_weak_tie@ with no tie';
is is_weak_tie(%^), undef, 'is_weak_tie% with no tie';
is is_weak_tie(*^), undef, 'is_weak_tie* with no tie';
is is_weak_tie($@[0]), undef, 'is_weak_tie$[] with no tie';
is is_weak_tie($@{0}), undef, 'is_weak_tie${} with no tie';
is is_weak_tie(*{$%}), undef, 'is_weak_tie*{IO} with no tie';

{
	local *@;
	ok eval{
		weak_tie $@, to => bless[];
		'' eq is_weak_tie $@;
	}, 'tying of $@';
}

{
	my $ref = \weak_tie my $bar, to => my $baz = bless[];
	$$ref = 27;
	is tied $bar, 27, 'retval of weak_tie';
}

untie($~), untie(@~), untie(%~), untie(*~), untie($`[0]), 
untie($`{0}), untie(*${}});
Tie::Util::tie($~, to => 37);
Tie::Util::tie(@~, to => 37);
Tie::Util::tie(%~, to => 37);
Tie::Util::tie(*~, to => 37);
Tie::Util::tie($`{0}, to => 37);
Tie::Util::tie($`[0], to => 37);
Tie::Util::tie(*${}}, to => 37);
is tied($~), 37, 'tie$ to non-obj';
is tied(@~), 37, 'tie@ to non-obj';
is tied(%~), 37, 'tie% to non-obj';
is tied(*~), 37, 'tie* to non-obj';
is tied($`{0}), 37, 'tie${} to non-obj';
is tied($`[0]), 37, 'tie$[] to non-obj';
is tied(*${}}), 37, 'tie*{IO} to non-obj';
{
	my $ref =\ Tie::Util::tie $., to => \1;
	is_deeply tied $., \1, 'tie to unblessed ref';
	$$ref = Foo;
	is tied $., Foo, 'tie retval';
	sub Foo::FETCH{ 42 }
	is $., 42, 'package tie'
}

{
	my $ref = \tie my $foo, to => bless[];
	is \Tie::Util::tied($foo), $ref, 'tied'
}

{ # based on [perl #68192]
 package dwin;
 sub TIESCALAR { bless {}, __PACKAGE__ };
 sub STORE {};
 sub FETCH { 123456 };

 my $foo;
 tie $foo, __PACKAGE__;

 my $a = [1234567];

 my $x = 0 + $foo;
 use Tie'Util 'fix_tie';
 fix_tie($foo = $a);
 my $y = 0 + $foo;
 
 ::is($x, $y, 'fix_tie');

 # Repeat the test to make sure we don’t ‘fix’ the tie.
 fix_tie($foo = $a);
 $y = 0 + $foo;
 ::is($x, $y, 'fix_tie again')
}
