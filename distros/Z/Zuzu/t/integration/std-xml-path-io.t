use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;
my $runtime = Zuzu::Runtime->new( lib => [ 'stdlib/modules', 'stdlib/test-modules' ] );
my $ast = $parser->parse(
	<<'SRC',
from std/data/xml import XML;
from std/io import Path;

function roundtrip_ok () {
	let file := Path.tempfile();
	let doc := XML.parse("<root><a>1</a></root>");
	XML.dump(file, doc);
	let loaded := XML.load(file);
	return loaded.findvalue("count(/root/a)");
}

function load_with_string () {
	XML.load("not-a-path.xml");
}

function dump_with_string () {
	let doc := XML.parse("<root/>");
	XML.dump("not-a-path.xml", doc);
}
SRC
	'std-xml-path-io.zzs',
);
$runtime->evaluate($ast);

is $runtime->call( 'roundtrip_ok' ), '1',
	'XML.load/XML.dump work with std/io Path objects';

like dies {
	$runtime->call( 'load_with_string' );
}, qr/TypeException: XML\.load expects Path as first argument/,
	'XML.load rejects plain string paths';

like dies {
	$runtime->call( 'dump_with_string' );
}, qr/TypeException: XML\.dump expects Path as first argument/,
	'XML.dump rejects plain string paths';

done_testing;
