use strict;
use Test;
BEGIN { plan tests => 24 }

use vars qw( $loaded $test %hash $eq @keys );

#### use

use Tie::AliasHash qw( allkeys );
ok ('1', '1', "use");

#### construction
tie %hash, 'Tie::AliasHash',
        [ 1 => qw( one ein un uno unos ) ],
        [ 2 => qw( two zwei dois due dos ) ],
        [ I => 'me' ];

ok(
	ref(tied %hash), qr/Tie::AliasHash/,
	"construction",
);	

#### simple alias
$hash{I} = "dada";
ok(
	"$hash{I}, $hash{me}", "dada, dada",
	"simple alias (forward)",
);

$hash{me} = 'dada@perl.it';
ok (
	"$hash{me}, $hash{I}", 'dada@perl.it, dada@perl.it',
	"simple alias (reverse)",
);

#### multiple aliases
$hash{1} = 7;
$eq = $hash{1} + $hash{one} + $hash{ein} + $hash{un} + $hash{uno} + $hash{unos};
ok(
	$eq, 42,
	"multiple aliases",
);

#### keys
$hash{2} = 2;
@keys = sort keys %hash;
ok(
	join( ", ", @keys ), "1, 2, I",
	"keys",
);

#### exists
ok(
	exists($hash{1}), 1,
	"exists (on key)",
);
ok(
	exists($hash{one}), 1,
	"exists (on alias)",
);

#### allkeys method
@keys = sort @{[ (tied %hash)->allkeys ]};
ok(
	join( ", ", @keys ),
	"1, 2, I, dois, dos, due, ein, me, one, two, un, uno, unos, zwei",
	"allkeys (as a method)",
);

@keys = sort @{[ allkeys(%hash) ]};
ok(
	join( ", ", @keys ),
	"1, 2, I, dois, dos, due, ein, me, one, two, un, uno, unos, zwei",
	"allkeys (as a function)",
);

#### aliases method
@keys = sort @{[ tied(%hash)->aliases('1') ]};
ok(
	join( ", ", @keys ),
	"ein, one, un, uno, unos",
	"aliases",
);

#### add_alias method
(tied %hash)->add_alias( 'foo', 'bar' );
$hash{foo} = 42;
ok(
	$hash{bar}, 42,
	"add_alias",
);

#### remove_alias method
(tied %hash)->remove_alias( 'bar' );
$hash{bar} = 0;
ok(
	"$hash{foo}, $hash{bar}", "42, 0",
	"remove_alias",
);

#### is_alias method
ok(
	(tied %hash)->is_alias( 'me' ), '1',
	"is_alias (on an alias)",
);
ok(
	(tied %hash)->is_alias( 'I' ), '',
	"is_alias (on a key)",
);

#### is_key method
ok(
	(tied %hash)->is_key( 'me' ), '', 
	"is_key (on an alias)",
);
ok(
	(tied %hash)->is_key( 'I' ), '1',
	"is_key (on a key)"
);

#### $; and [] constructs

$hash{ qw( foo bar baz ) } = 42;
ok(
	join( ", ", $hash{foo}, $hash{bar}, $hash{baz} ), "42, 42, 42", 
	"multiple assignement (\$; construct)",
);

$hash{ [qw( foo bar baz )] } = 42;
ok( 
	join( ", ", $hash{foo}, $hash{bar}, $hash{baz} ), "42, 42, 42",
	"multiple assignement ([] construct)",
);

(tied %hash)->remove( 'foo', 'bar', 'baz' );

#### alias transitivity

$hash{ 'foo', 'bar' } = 'nothing';
$hash{ 'bar', 'baz' } = 42;
ok( 
	$hash{foo}, 42, 
	"alias transitivity (with assignement)",
);

$hash{ 'FOO' } = 42;
tied(%hash)->add_alias( 'FOO', 'BAR' );
tied(%hash)->add_alias( 'BAR', 'BAZ' );
ok(
	$hash{BAZ}, 42, 
	"alias transitivity (with add_alias)",
);

#### 'jolly'

delete $hash{'foo'};
delete $hash{'bar'};
delete $hash{'baz'};

tied(%hash)->set_jolly( 'foo' );

$hash{foo} = 1;

$hash{bar} += 1;

ok(
	$hash{foo}, 2,
	"set_jolly (1)",
);

ok(
	$hash{baz}, 2,
	"set_jolly (2)",
);

tied(%hash)->remove_jolly();

ok(
	defined($hash{baz}), '',
	"remove_jolly",
);

#### the end

untie %hash;
