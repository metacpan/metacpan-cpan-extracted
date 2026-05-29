use Test2::V0;
use File::Spec;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new(
		lib => [ File::Spec->catdir( '.', 'stdlib', 'modules' ) ],
	);
	my $ast = $parser->parse( $src, 'runtime-path-lvalues-phase3.zzs' );
	return $runtime->evaluate($ast);
}

is(
	eval_src(<<'SRC'),
let src := { users: [ { age: 1 }, { age: 2 } ] };
src @ "/users/#1/age" += 5;
[ src{users}[0]{age}, src{users}[1]{age} ];
SRC
	object {
		call items => array {
			item 1;
			item 7;
			end;
		};
	},
	'@ compound assignment mutates one selected target',
);

is(
	eval_src(<<'SRC'),
let src := { users: [ { role: "a" }, { role: "b" } ] };
let result := src @@ "/users/*/role" _= "!";
[ result, src{users}[0]{role}, src{users}[1]{role} ];
SRC
	object {
		call items => array {
			item '!';
			item 'a!';
			item 'b!';
			end;
		};
	},
	'@@ compound assignment returns RHS contract and mutates all targets',
);

is(
	eval_src(<<'SRC'),
let src := { users: [ { age: 1 } ] };
[ src @? "/users/#0/age" += 2, src @? "/users/#9/age" += 2, src{users}[0]{age} ];
SRC
	object {
		call items => array {
			item object { call value => 1; end; };
			item object { call value => 0; end; };
			item 3;
			end;
		};
	},
	'@? compound assignment follows maybe-single-target contract',
);

is(
	eval_src(<<'SRC'),
let src := { meta: { title: "Read 2026" } };
let result := src @ "/meta/title" ~= /[0-9]+/ -> "world";
[ result, src{meta}{title} ];
SRC
	object {
		call items => array {
			item 'Read world';
			item 'Read world';
			end;
		};
	},
	'path ~= assignment packages regexp and replacement callback',
);

is(
	eval_src(<<'SRC'),
let src := { users: [ { age: 1 }, { age: 2 } ] };
let old := ( src @@ "/users/*/age" )++;
[ old, src @@ "/users/*/age" ];
SRC
	object {
		call items => array {
			item object {
				call items => array {
					item 1;
					item 2;
					end;
				};
			};
			item object {
				call items => array {
					item 2;
					item 3;
					end;
				};
			};
			end;
		};
	},
	'@@ postfix update returns old values array and mutates all targets',
);

is(
	eval_src(<<'SRC'),
let src := { users: [ { age: 4 } ] };
[ ++( src @ "/users/#0/age" ), ++( src @? "/users/#0/age" ), ++( src @? "/users/#9/age" ), src{users}[0]{age} ];
SRC
	object {
		call items => array {
			item 5;
			item object { call value => 1; end; };
			item object { call value => 0; end; };
			item 6;
			end;
		};
	},
	'@ and @? prefix update follow frozen scalar vs boolean result contract',
);

is(
	eval_src(<<'SRC'),
let src := {
	meta: { title: "Before" },
	users: [ { name: "Ada" }, { name: "Bob" } ],
};
let focused := \( src @ "/meta/title" );
let many := \( src @@ "/users/*/name" );
let maybe := \( src @? "/meta/missing" );
[
	focused(),
	focused("After"),
	src{meta}{title},
	many.length(),
	many[0](),
	many[1]("Bert"),
	src{users}[1]{name},
	maybe,
];
SRC
	object {
		call items => array {
			item 'Before';
			item 'After';
			item 'After';
			item 2;
			item 'Ada';
			item 'Bert';
			item 'Bert';
			item undef;
			end;
		};
	},
	'path reference operator returns single refs, arrays of refs, and null for @? miss',
);

is(
	eval_src(<<'SRC'),
from std/path/simple import SimplePath;
from std/internals import setprop;
setprop( "paths", SimplePath );
let src := { store: { books: [ { price: 2 }, { price: 4 } ] } };
let before := ( src @@ "store.books[*].price" )++;
[ before, src @@ "store.books[*].price" ];
SRC
	object {
		call items => array {
			item object {
				call items => array {
					item 2;
					item 4;
					end;
				};
			};
			item object {
				call items => array {
					item 3;
					item 5;
					end;
				};
			};
			end;
		};
	},
	'path update runtime works with SimplePath-selected refs too',
);

done_testing;
