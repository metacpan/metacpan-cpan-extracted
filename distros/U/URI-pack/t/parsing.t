#!perl -T

use 5.008;
use strict;
use warnings 'all';

##############################################################################
# TEST MODULES
use Test::Most;

##############################################################################
# MODULES
use URI;

##############################################################################
# TEST PLAN
plan tests => 30;

{
	# Make a new URI object
	my $uri = new_ok('URI', ['pack://http:,,www.mysite.com,my.package/a/b/foo.xml'], 'URI::pack');

	ok($uri->has_package_uri, '... and it has a package');
	is($uri->package_uri, 'http://www.mysite.com/my.package', '... and package URI is correct');
	ok($uri->has_part_name, '... and it has a part name');
	is($uri->part_name, '/a/b/foo.xml', '... and part name is correct');
	is_deeply([$uri->part_name_segments], [qw(a b foo.xml)], '... and part name has three segments');

	# Making changes to part_name
	lives_ok {$uri->part_name('/apples/inv.xml')} '... and setting new part name works';
	is($uri->part_name, '/apples/inv.xml', '... and new part name is there');
	is_deeply([$uri->part_name_segments], [qw(apples inv.xml)], '... and new part name is in segments');

	# Making changes to part_name_segments
	lives_ok {$uri->part_name_segments(qw(trees have apples.txt))} '... and setting new part name segments works';
	is($uri->part_name, '/trees/have/apples.txt', '... and new part name is there');
	is_deeply([$uri->part_name_segments], [qw(trees have apples.txt)], '... and new part name is in segments');
}

{
	# Make a new URI object without the package
	my $uri = new_ok('URI', ['/a/b/foo.xml', 'pack'], 'URI::pack');

	ok(!$uri->has_package_uri, '... and it does not have a package');
	ok($uri->has_part_name, '... and it has a part name');
	is($uri->part_name, '/a/b/foo.xml', '... and part name is correct');

	lives_ok {$uri->part_name('/a/%D1%86.xml')} '... and setting new part name to /a/%D1%86.xml works';
	is($uri->part_name, '/a/%D1%86.xml', '... and new part name is there');

	dies_ok {$uri->part_name('//xml/.')} '... and setting new part name to //xml/. fails';
	is($uri->part_name, '/a/%D1%86.xml', '... and part name is still the old');

	# Test failures
	throws_ok {$uri->part_name('')} qr{not be empty}, '... and new empty part fails';
	throws_ok {$uri->part_name('wow')} qr{start with a forward slash}, '... and new part not starting with a / fails';
	throws_ok {$uri->part_name('/wow/')} qr{forward slash as the last character}, '... and new part ending with a / fails';
	throws_ok {$uri->part_name('/\test')} qr{other than pchar characters}, '... and new part containing a non-pchar fails';
	throws_ok {$uri->part_name('/te%2fst.xml')} qr{not contain percent-encoded forward slash}, '... and new part containing a precent-encoded / fails';
	throws_ok {$uri->part_name('/te%5cst.xml')} qr{not contain percent-encoded .+? backward slash}, '... and new part containing a precent-encoded \ fails';
	throws_ok {$uri->part_name('/te%36st.xml')} qr{not contain percent-encoded unreserved characters}, '... and new part containing a precent-encoded unreserved character fails';
	throws_ok {$uri->part_name('/xml/test.')} qr{not end with a dot}, '... and new part ending in a dot fails';
	throws_ok {$uri->part_name('//xml/test.xml')} qr{empty segment}, '... and new part with empty segment fails';
	throws_ok {$uri->part_name('/./test')} qr{not end with a dot}, '... and new part with a segment of only a dot fails';
}

exit 0;
