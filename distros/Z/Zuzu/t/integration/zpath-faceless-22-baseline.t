use Test2::V0;

use File::Spec;

if ( not $ENV{ZPATH_FACELESS_ENFORCE_BASELINE} ) {
	plan skip_all => 'set ZPATH_FACELESS_ENFORCE_BASELINE=1 to enforce 22-failure snapshot';
}

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $faceless_script = File::Spec->catfile(
	$repo_root,
	't',
	'ztests',
	'std',
	'path',
	'zpath',
	'_faceless.zzs',
);

if ( not -f $faceless_script ) {
	plan skip_all => 'faceless ztest fixture is not present in this split checkout';
}

ok( -f $faceless_script, 'faceless ztest fixture exists' );

my $cmd = join(
	' ',
	$^X,
	'-Ilib',
	'bin/zuzu.pl',
	'-Istdlib/modules',
	'-Istdlib/test-modules',
	$faceless_script,
	'2>&1',
);

my $output = qx{$cmd};
my $exit_status = $? >> 8;

is( $exit_status, 0, 'faceless fixture process exits cleanly' );

my @failed_queries = ( $output =~ /^not ok \d+ - Query:\s*(.+)$/mg );

my @expected_failed_queries = (
	'key(/address)',
	'index(numbers/*[type == \'home\'])',
	'/numbers/#0/number/..*',
	'index(..)',
	'first, first,last',
	'**/numbers/*/union(..)/*',
	'index(numbers/*[type == \'home\']) == 1',
	'age /2',
	'2 - 2',
	'numbers/*[index() % 2 == 0]',
	'numbers/*[index() % 2.4 != 0]',
	'**/numbers == **/numbers/#0/..',
	'number("1231213123213123123124124124142") > number("1231213123213123123124124124141")',
	'number("1231213123213123123124124124142") > number("1231213123213123123124124124141.9")',
	'number("1231213123213123123124124124142") > 9999',
	'join("|", numbers/*[type == "iPhone"]/things/*)',
	'tag(tagged)',
	'type(key(#1))',
	'union(**/table,**/table,**/person)',
	'**/items/item/value(number(price) * number(quantity))',
	'sum(**/items/item/value(number(price) * number(quantity)))',
	'format("$%02.2f", sum(**/items/item/value(number(price) * number(quantity))))',
);

is(
	\@failed_queries,
	\@expected_failed_queries,
	'faceless fixture keeps the known 22-query baseline in stable order',
);

done_testing;
