use Test2::V0;

use Zuzu::Runtime;

my $fixture_dir = 't/fixtures/marshal/golden';

my @fixtures = (
	[
		'scalar-null',
		q{let fixture_value := null;},
	],
	[
		'array-cycle',
		q{let fixture_value := []; fixture_value.push(fixture_value);},
	],
	[
		'dict-pairlist',
		q{
			let fixture_value := [
				{ beta: 2, alpha: 1 },
				{{ foo: 1, bar: 2, foo: 3 }},
			];
		},
	],
	[
		'time-path',
		q{
			from std/time import Time;
			from std/io import Path;
			let fixture_value := [
				new Time(12345),
				new Path("tmp/../file.txt"),
			];
		},
	],
	[
		'function',
		q{
			function add_one (x) {
				return x + 1;
			}
			let fixture_value := add_one;
		},
	],
	[
		'class',
		q{
			const offset := 40;
			class GoldenPoint {
				let Number x := 1;

				method total (Number y) -> Number {
					return x + y + offset;
				}
			}
			let fixture_value := GoldenPoint;
		},
	],
	[
		'trait',
		q{
			const prefix := "label:";
			trait GoldenLabelled {
				method label () -> String {
					return prefix _ self.get_name();
				}
			}
			let fixture_value := GoldenLabelled;
		},
	],
	[
		'object-instance',
		q{
			class GoldenBox {
				let String name with get, set := "unset";
				const kind := "box";

				method label () {
					return name _ ":" _ kind;
				}
			}
			let fixture_value := new GoldenBox( name: "Ada" );
		},
	],
);

for my $fixture (@fixtures) {
	my ( $name, $body ) = @{ $fixture };
	my $runtime = Zuzu::Runtime->new;
	my $source = <<~"ZUZU";
		from std/marshal import dump, load;
		from std/string/base64 import encode;
		$body
		let blob := dump(fixture_value);
		load(blob);
		encode(blob);
		ZUZU

	my $actual = $runtime->eval_with_current_scope(
		$source,
		"<marshal-golden-$name>",
	);
	my $path = "$fixture_dir/$name.b64";
	open my $fh, '<', $path or die "Cannot read $path: $!";
	my $expected = do { local $/; <$fh> };
	chomp $expected;

	is $actual, $expected, "$name golden fixture is stable";
}

done_testing;
