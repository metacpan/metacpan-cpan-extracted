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
	my $ast = $parser->parse( $src, 'runtime-path-operators-phase4.zzs' );
	return $runtime->evaluate($ast);
}

is(
	eval_src('let src := { users: [ { name: "Ada" }, { name: "Bob" } ] }; src @ "/users/#1/name" := "Bea"; src @ "/users/#1/name";'),
	'Bea',
	'@ assignment writes to first matched location',
);

is(
	eval_src('let src := { users: [ { name: "Ada" }, { name: "Bob" } ] }; src @@ "/users/*/name" := "User"; src @@ "/users/*/name";'),
	object {
		call items => array {
			item 'User';
			item 'User';
			end;
		};
	},
	'@@ assignment writes to all matched locations',
);

my $no_match_error = dies {
	eval_src('let src := { users: [ { name: "Ada" } ] }; src @ "/users/#9/name" := "Nope";');
};
ok $no_match_error, '@ assignment throws when selector has no matches';

done_testing;
