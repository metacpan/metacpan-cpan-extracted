use Test2::V0;
use Test2::Require::AuthorTesting;

use File::Spec;

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $zuzudoc_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzudoc.pl' );
my $module_file = File::Spec->catfile(
	$repo_root,
	'stdlib',
	'modules',
	'std',
	'io.zzm',
);

ok -x $zuzudoc_bin, 'bin/zuzudoc.pl exists and is executable';

my $module_cmd = "PAGER=cat $^X $zuzudoc_bin -I$repo_root/stdlib/modules std/io 2>&1";
my $module_output = qx{$module_cmd};
my $module_exit = $? >> 8;
is $module_exit, 0, 'zuzudoc.pl resolves module names via search paths';
like $module_output, qr/std\/io/,
	'zuzudoc.pl renders module pod text';

my $file_cmd = "PAGER=cat $^X $zuzudoc_bin $module_file 2>&1";
my $file_output = qx{$file_cmd};
my $file_exit = $? >> 8;
is $file_exit, 0, 'zuzudoc.pl accepts direct file paths';
like $file_output, qr/Filesystem paths and standard stream helpers/,
	'zuzudoc.pl renders named file documentation';

done_testing;
