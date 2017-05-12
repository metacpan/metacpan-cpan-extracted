use strict;
use warnings;
use JSON;
use Text::TNetstrings qw(:all);
use Benchmark qw(cmpthese);
my $structure = {
	'resources' => {
		'license' => [
			'http://opensource.org/licenses/mit-license.php'
		]
	},
	'meta-spec' => {
		'version' => '2',
		'url' => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec'
	},
	'generated_by' => 'Module::Build version 0.38, CPAN::Meta::Converter version 2.110440',
	'version' => 'v1.1.0',
	'name' => 'Text-TNetstrings',
	'dynamic_config' => 0,
	'author' => [
		'unknown'
	],
	'license' => [
		'mit'
	],
	'prereqs' => {
		'build' => {
			'requires' => {
				'ExtUtils::CBuilder' => 0
			}
		}
	},
	'abstract' => 'Data serialization using typed netstrings.',
	'release_status' => 'stable'
};

my $tn = encode_tnetstrings($structure);
my $json = encode_json($structure);
print "TNetstrings (" . length($tn) . ")
$tn

JSON (" . length($json) . ")
$json
";

cmpthese(-10, {
	'TNetstrings' => sub{decode_tnetstrings(encode_tnetstrings($structure))},
	'JSON' => sub{decode_json(encode_json($structure))},
});

