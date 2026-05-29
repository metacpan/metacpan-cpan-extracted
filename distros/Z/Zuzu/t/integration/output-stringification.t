use Test2::V0;
use Test2::Require::AuthorTesting;

use File::Spec;

my $repo_root = File::Spec->rel2abs( File::Spec->curdir );
my $zuzu_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );

my $display_source = join ' ',
	'say false;',
	'say true;',
	'say [];',
	'say [false, true];',
	'say { z: false, a: true };',
	'print false;';
my $display_string_cmd = "$^X $zuzu_bin -e '$display_source' 2>&1";
my $display_string_output = qx{$display_string_cmd};
my $display_string_exit = $? >> 8;
is $display_string_exit, 0,
	'say and print use ZuzuScript display stringification';
is $display_string_output,
	"false\ntrue\n[]\n[false, true]\n{a: true, z: false}\nfalse",
	'display stringification avoids Perl runtime details';

my $warn_string_cmd = "$^X $zuzu_bin -e 'warn false;' 2>&1";
my $warn_string_output = qx{$warn_string_cmd};
my $warn_string_exit = $? >> 8;
is $warn_string_exit, 0, 'warn uses ZuzuScript display stringification';
is $warn_string_output, "false\n", 'warn stringifies false as false';

my $debug_string_cmd = "$^X $zuzu_bin -d1 -e 'debug 1, false;' 2>&1";
my $debug_string_output = qx{$debug_string_cmd};
my $debug_string_exit = $? >> 8;
is $debug_string_exit, 0, 'debug uses ZuzuScript display stringification';
is $debug_string_output, "false\n", 'debug stringifies false as false';

done_testing;
