use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;

# Test dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = Wikibase::Cache::Backend::Basic->new;
my $ret = $obj->get('label', 'Q11573');
is($ret, 'metre', 'Get label for Q11573 (metre).');

# Test.
$ret = $obj->get('description', 'Q11573');
is($ret, 'SI unit of length', 'Get description for Q11573 (SI unit of length).');

# Test.
$ret = $obj->get('description', 'bad');
is($ret, undef, 'Get description for bad (undef).');

# Test.
eval {
	$obj->get('bad', 'Q11573');
};
is($EVAL_ERROR, "Type 'bad' isn't supported.\n", "Type 'bad' isn't supported.");
clean();

# Test.
open my $fh, '<', $data_dir->file('example.txt')->s;
$obj = Wikibase::Cache::Backend::Basic->new(
	'data_fh' => $fh,
);
$ret = $obj->get('label', 'P31');
is($ret, 'foo', 'Get label for P31 in test mapping file (foo).');
close $fh;
