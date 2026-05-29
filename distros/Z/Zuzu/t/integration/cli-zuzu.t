use Test2::V0;
use Test2::Require::AuthorTesting;

use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $zuzu_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );

ok -x $zuzu_bin, 'bin/zuzu.pl exists and is executable';

my $tmpdir = tempdir( CLEANUP => 1 );
my $script = File::Spec->catfile( $tmpdir, 'main.zzs' );
open my $fh, '>:encoding(UTF-8)', $script
	or die "Could not create $script: $!";
print {$fh} <<'SRC';
function __main__ (args) {
	for ( let item in args ) {
		let _seen := item;
	}
	die "MAIN_CALLED:" _ args[0] _ ":" _ args[2];
}
SRC
close $fh;

my $cmd = "$^X $zuzu_bin $script alpha beta gamma 2>&1";
my $output = qx{$cmd};
my $exit = $? >> 8;
isnt $exit, 0, 'zuzu calls __main__ after evaluation';
like $output, qr/MAIN_CALLED:alpha:gamma/,
	'__main__ receives argv as Array';

my $async_main_script = File::Spec->catfile( $tmpdir, 'async-main.zzs' );
open my $async_main_fh, '>:encoding(UTF-8)', $async_main_script
	or die "Could not create $async_main_script: $!";
print {$async_main_fh} <<'SRC';
from std/task import resolved;
async function __main__ (args) {
	let value := await {
		resolved(args[1]);
	};
	die "ASYNC_MAIN:" _ args[0] _ ":" _ value;
}
SRC
close $async_main_fh;

my $async_main_cmd = "$^X $zuzu_bin $async_main_script alpha beta 2>&1";
my $async_main_output = qx{$async_main_cmd};
my $async_main_exit = $? >> 8;
isnt $async_main_exit, 0, 'zuzu awaits async __main__ after evaluation';
like $async_main_output, qr/ASYNC_MAIN:alpha:beta/,
	'async __main__ receives argv and completes awaited work';

my $sync_task_main_script = File::Spec->catfile( $tmpdir, 'sync-task-main.zzs' );
open my $sync_task_main_fh, '>:encoding(UTF-8)', $sync_task_main_script
	or die "Could not create $sync_task_main_script: $!";
print {$sync_task_main_fh} <<'SRC';
from std/task import failed;
function __main__ (args) {
	return failed("SYNC_MAIN_TASK_SHOULD_NOT_BE_AWAITED");
}
SRC
close $sync_task_main_fh;

my $sync_task_main_cmd = "$^X $zuzu_bin $sync_task_main_script 2>&1";
my $sync_task_main_output = qx{$sync_task_main_cmd};
my $sync_task_main_exit = $? >> 8;
is $sync_task_main_exit, 0,
	'zuzu does not implicitly await a synchronous __main__ return value';
is $sync_task_main_output, '',
	'synchronous __main__ returning a failed Task is only called';

my $debug_cmd = "$^X $zuzu_bin -d3 $script alpha beta gamma 2>&1";
my $debug_output = qx{$debug_cmd};
my $debug_exit = $? >> 8;
isnt $debug_exit, 0, 'zuzu accepts -dN debug option';
like $debug_output, qr/MAIN_CALLED:alpha:gamma/,
	'-dN does not alter argv forwarding';

my $debug_flag_cmd = "$^X $zuzu_bin -d $script alpha beta gamma 2>&1";
my $debug_flag_output = qx{$debug_flag_cmd};
my $debug_flag_exit = $? >> 8;
isnt $debug_flag_exit, 0, 'zuzu accepts -d debug option via Getopt::Long';
like $debug_flag_output, qr/MAIN_CALLED:alpha:gamma/,
	'-d does not alter argv forwarding';

my $bad_debug_cmd = "$^X $zuzu_bin -d-1 $script 2>&1";
my $bad_debug_output = qx{$bad_debug_cmd};
my $bad_debug_exit = $? >> 8;
is $bad_debug_exit, 2, 'negative debug level is rejected';
like $bad_debug_output, qr/non-negative integer/,
	'error explains debug level requirements';

my $help_cmd = "$^X $zuzu_bin --help 2>&1";
my $help_output = qx{$help_cmd};
my $help_exit = $? >> 8;
is $help_exit, 2, '--help exits with usage status';
like $help_output, qr/--no-cache/,
	'help documents --no-cache';
like $help_output, qr/--clear-cache/,
	'help documents --clear-cache';
like $help_output, qr/--no-visitor/,
	'help documents --no-visitor';

my $bad_visitor_cmd = "$^X $zuzu_bin --no-visitor=NoSuchVisitor $script 2>&1";
my $bad_visitor_output = qx{$bad_visitor_cmd};
my $bad_visitor_exit = $? >> 8;
is $bad_visitor_exit, 2, 'unknown visitor name is rejected';
like $bad_visitor_output, qr/Unknown visitor 'NoSuchVisitor'/,
	'unknown visitor error names the bad visitor';

my $super_script = File::Spec->catfile( $tmpdir, 'super.zzs' );
open my $super_fh, '>:encoding(UTF-8)', $super_script
	or die "Could not create $super_script: $!";
print {$super_fh} <<'SRC';
class Parent {
	method value () {
		return "parent";
	}
}
class Child extends Parent {
	method value () {
		return super() _ ":child";
	}
}
function __main__ (args) {
	let child := new Child();
	die child.value();
}
SRC
close $super_fh;

my $no_super_cmd = "$^X $zuzu_bin --no-visitor=SuperHints $super_script 2>&1";
my $no_super_output = qx{$no_super_cmd};
my $no_super_exit = $? >> 8;
isnt $no_super_exit, 0, '--no-visitor disables the named visitor';
like $no_super_output, qr/parent:child/,
	'disabled SuperHints conservatively keeps super dispatch setup';

my $inc_dir = File::Spec->catdir( $tmpdir, 'modules', 'extras' );
make_path( $inc_dir );
my $inc_mod = File::Spec->catfile( $inc_dir, 'value.zzm' );
open my $inc_fh, '>:encoding(UTF-8)', $inc_mod
	or die "Could not create $inc_mod: $!";
print {$inc_fh} <<'SRC';
function answer () {
	return 42;
}
SRC
close $inc_fh;

my $import_script = File::Spec->catfile( $tmpdir, 'import.zzs' );
open my $import_fh, '>:encoding(UTF-8)', $import_script
	or die "Could not create $import_script: $!";
print {$import_fh} <<'SRC';
from extras/value import answer;
die "INC_ANSWER:" _ answer();
SRC
close $import_fh;

my $include_cmd = "$^X $zuzu_bin -I$tmpdir/modules $import_script 2>&1";
my $include_output = qx{$include_cmd};
my $include_exit = $? >> 8;
isnt $include_exit, 0, 'zuzu loads modules from -I/path include directory';
like $include_output, qr/INC_ANSWER:42/,
	'-I/path include directory is part of import search path';

my $no_main_script = File::Spec->catfile( $tmpdir, 'no-main.zzs' );
open my $no_main_fh, '>:encoding(UTF-8)', $no_main_script
	or die "Could not create $no_main_script: $!";
print {$no_main_fh} "let x := 1;\n";
close $no_main_fh;

my $no_main_cmd = "$^X $zuzu_bin $no_main_script 2>&1";
my $no_main_output = qx{$no_main_cmd};
my $no_main_exit = $? >> 8;
is $no_main_exit, 0, 'scripts without __main__ still evaluate successfully';
is $no_main_output, '', 'scripts without __main__ produce no implicit output';

my $version_cmd = "$^X $zuzu_bin -v 2>&1";
my $version_output = qx{$version_cmd};
my $version_exit = $? >> 8;
is $version_exit, 0, '-v exits successfully';
like $version_output, qr/\Azuzu version \S+/,
	'-v prints project version';

my $version_verbose_cmd = "$^X $zuzu_bin -V -I$tmpdir/modules 2>&1";
my $version_verbose_output = qx{$version_verbose_cmd};
my $version_verbose_exit = $? >> 8;
is $version_verbose_exit, 0, '-V exits successfully';
like $version_verbose_output, qr/lib search paths:/,
	'-V includes runtime lib search paths heading';
like $version_verbose_output, qr/\Q$tmpdir\/modules\E/,
	'-V includes -I search path';
like $version_verbose_output, qr/builtin modules:/,
	'-V includes builtin modules heading';
like $version_verbose_output, qr/std\/data\/json/,
	'-V includes builtin module names';

my $deny_fs_script = File::Spec->catfile( $tmpdir, 'deny-fs.zzs' );
open my $deny_fs_fh, '>:encoding(UTF-8)', $deny_fs_script
	or die "Could not create $deny_fs_script: $!";
print {$deny_fs_fh} <<'SRC';
from std/io import Path;
die "PATH:" _ Path.cwd().to_String();
SRC
close $deny_fs_fh;

my $deny_capability_cmd = "$^X $zuzu_bin --deny=fs $deny_fs_script 2>&1";
my $deny_capability_output = qx{$deny_capability_cmd};
my $deny_capability_exit = $? >> 8;
isnt $deny_capability_exit, 0, '--deny rejects denied capability-backed builtin modules';
like $deny_capability_output, qr/Cannot find module 'std\/io' in lib paths/,
	'--deny=fs hides std/io modules from import resolution';

my $deny_gui_script = File::Spec->catfile( $tmpdir, 'deny-gui.zzs' );
open my $deny_gui_fh, '>:encoding(UTF-8)', $deny_gui_script
	or die "Could not create $deny_gui_script: $!";
print {$deny_gui_fh} <<'SRC';
from std/gui/objects import Widget;
SRC
close $deny_gui_fh;

my $deny_gui_cmd = "$^X $zuzu_bin --deny=gui $deny_gui_script 2>&1";
my $deny_gui_output = qx{$deny_gui_cmd};
my $deny_gui_exit = $? >> 8;
isnt $deny_gui_exit, 0, '--deny=gui rejects std/gui/objects imports';
like $deny_gui_output, qr/std\/gui\/objects is denied by runtime policy/,
	'--deny=gui fails while loading std/gui/objects';

my $deny_gui_dialogue_cmd = "$^X $zuzu_bin --deny=gui -e 'from std/gui/dialogue import alert, confirm, prompt, file_open; from std/tui import filename_completions; alert(\"Hi\"); say(confirm(\"Q\", auto_result: true)); say(prompt(\"Name:\", auto_result: \"Ada\")); say(file_open(auto_result: \"x.txt\")); say(filename_completions(\"modules/std/tu\").length() > 0);' 2>&1";
my $deny_gui_dialogue_output = qx{$deny_gui_dialogue_cmd};
my $deny_gui_dialogue_exit = $? >> 8;
is $deny_gui_dialogue_exit, 0,
	'--deny=gui allows std/gui/dialogue terminal fallbacks';
is $deny_gui_dialogue_output, "Hi\n1\nAda\nx.txt\n1\n",
	'std/gui/dialogue terminal fallback output is plain on non-TTY stdout';

my $deny_module_cmd = "$^X $zuzu_bin --denymodule=extras/value -I$tmpdir/modules $import_script 2>&1";
my $deny_module_output = qx{$deny_module_cmd};
my $deny_module_exit = $? >> 8;
isnt $deny_module_exit, 0, '--denymodule rejects explicitly denied module imports';
like $deny_module_output, qr/Module 'extras\/value' is denied by runtime policy/,
	'--denymodule reports denied module policy';

my $inline_cmd = "$^X $zuzu_bin -e 'function __main__ (args) { die \"INLINE:\" _ args[0]; }' hello 2>&1";
my $inline_output = qx{$inline_cmd};
my $inline_exit = $? >> 8;
isnt $inline_exit, 0, '-e evaluates inline code without script file';
like $inline_output, qr/INLINE:hello/,
	'-e inline script receives argv through __main__';

my $preload_mod = File::Spec->catfile( $inc_dir, 'preload.zzm' );
open my $preload_fh, '>:encoding(UTF-8)', $preload_mod
	or die "Could not create $preload_mod: $!";
print {$preload_fh} <<'SRC';
function forty_two () {
	return 42;
}
SRC
close $preload_fh;

my $preload_cmd = "$^X $zuzu_bin -I$tmpdir/modules -Mextras/preload -e 'die \"PRELOAD:\" _ forty_two();' 2>&1";
my $preload_output = qx{$preload_cmd};
my $preload_exit = $? >> 8;
isnt $preload_exit, 0, '-M preloads module exports into inline evaluation';
like $preload_output, qr/PRELOAD:42/,
	'-M imports module exports with wildcard prelude';

my $die_object_cmd = "$^X $zuzu_bin -e 'die \"hi\"' 2>&1";
my $die_object_output = qx{$die_object_cmd};
my $die_object_exit = $? >> 8;
isnt $die_object_exit, 0, 'die on String exits with exception';
like $die_object_output, qr/\Ahi at \(command line\), line 1\s*\z/,
	'die stringifies Exception payload via to_String';

my $default_object_string_cmd = "$^X $zuzu_bin -e 'class Foo; say new Foo()' 2>&1";
my $default_object_string_output = qx{$default_object_string_cmd};
my $default_object_string_exit = $? >> 8;
is $default_object_string_exit, 0, 'say works for plain objects';
like $default_object_string_output, qr/\A\[Foo\]\n\z/,
	'plain objects stringify as [ClassName]';

my $custom_object_string_cmd = "$^X $zuzu_bin -e 'class Foo { method to_String () { return \"xyz\" } } say new Foo()' 2>&1";
my $custom_object_string_output = qx{$custom_object_string_cmd};
my $custom_object_string_exit = $? >> 8;
is $custom_object_string_exit, 0, 'say works for objects with to_String';
like $custom_object_string_output, qr/\Axyz\n\z/,
	'object to_String overrides default object display';

my $repl_cmd = join ' ',
	'printf',
	"'%s\\n'",
	"'let n1 := 40'",
	"'function get_n1 () {'",
	"'return n1;'",
	"'}'",
	"'get_n1'",
	"'get_n1()'",
	'|',
	"$^X",
	$zuzu_bin,
	'-R',
	'2>&1';
my $repl_output = qx{$repl_cmd};
my $repl_exit = $? >> 8;
my $ansi = qr/\e\[[0-9;]*m/;

is $repl_exit, 0, '-R exits successfully after stdin reaches EOF';
like $repl_output, qr/\Qzuzu (...)> \E/,
	'-R switches to continuation prompt for incomplete input';
unlike $repl_output, qr/Wide character in print/,
	'-R prompt output avoids wide-character warnings';
unlike $repl_output, qr/Redeclaration of 'CancelledException'/,
	'-R does not redeclare parser-known builtin classes';
like $repl_output, qr/\Q40\E/,
	'-R evaluates let statement without requiring semicolon';
like $repl_output, qr/\QFunction\E/,
	'-R renders function values in output';
like $repl_output, qr/\Q40\E.*\QFunction\E.*\QFunction\E.*\Q40\E/s,
	'-R evaluates multiline function definitions and calls in order';
like $repl_output, qr/$ansi/,
	'-R emits ANSI styling for prompt/output/error channels';


my $repl_abort_cmd = join ' ',
	'printf',
	"'%s\n'",
	"'let := 1'",
	"';'",
	"'1 + 1'",
	'|',
	"$^X",
	$zuzu_bin,
	'-R',
	'2>&1';
my $repl_abort_output = qx{$repl_abort_cmd};
my $repl_abort_exit = $? >> 8;

is $repl_abort_exit, 0,
	'-R treats standalone semicolon as continuation abort sentinel';
like $repl_abort_output, qr/CompileError\[E_COMPILE_SYNTAX\]/,
	'-R reports syntax error immediately after abort sentinel';
like $repl_abort_output, qr/\Q2\E/,
	'-R resumes normal evaluation after aborting continuation buffer';

done_testing;
