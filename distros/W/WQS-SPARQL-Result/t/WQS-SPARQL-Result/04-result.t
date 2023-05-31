use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use JSON::XS;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use WQS::SPARQL::Result;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = WQS::SPARQL::Result->new;
my $result1_json = slurp($data_dir->file('result1.json')->s);
my $result1_hr = decode_json($result1_json);
my @ret = $obj->result($result1_hr);
is_deeply(\@ret, [{'item' => 'Q104381358'}], 'Get one item result.');

# Test.
$obj = WQS::SPARQL::Result->new;
my $result2_json = slurp($data_dir->file('result2.json')->s);
my $result2_hr = decode_json($result2_json);
@ret = $obj->result($result2_hr);
is_deeply(\@ret, [{'foo' => 'Q104381358'}], 'Get one foo result.');

# Test.
$obj = WQS::SPARQL::Result->new;
my $result3_json = slurp($data_dir->file('result3.json')->s);
my $result3_hr = decode_json($result3_json);
@ret = $obj->result($result3_hr, ['item', 'itemLabel']);
is_deeply(
	\@ret,
	[{
		'item' => 'Q27954834',
		'itemLabel' => decode_utf8('Michal Josef Špaček'),
	}],
	'Get one item result.',
);

# Test.
$obj = WQS::SPARQL::Result->new;
my $bad_json = slurp($data_dir->file('bad.json')->s);
my $bad_hr = decode_json($bad_json);
eval {
	$obj->result($bad_hr);
};
is($EVAL_ERROR, "Type 'bad' doesn't supported.\n", "Type 'bad' doesn't supported.");
clean();
