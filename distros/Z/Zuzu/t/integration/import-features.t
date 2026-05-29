use Test2::V0;

use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub write_utf8 {
	my ( $path, $src ) = @_;

	open my $fh, '>:encoding(UTF-8)', $path
		or die "Cannot write $path: $!";
	print {$fh} $src;
	close $fh;

	return;
}

sub write_raw {
	my ( $path, $bytes ) = @_;

	open my $fh, '>:raw', $path
		or die "Cannot write $path: $!";
	print {$fh} $bytes;
	close $fh;

	return;
}

sub cache_files {
	my ( $dir ) = @_;

	return if !-d $dir;
	opendir my $dh, $dir
		or die "Cannot read $dir: $!";
	my @files = map {
		File::Spec->catfile( $dir, $_ )
	} grep {
		/\.stor\z/
	} readdir $dh;
	closedir $dh;

	return @files;
}

sub parse_and_eval {
	my ( %args ) = @_;

	my $runtime = Zuzu::Runtime->new( lib => $args{lib} );
	my $ast = $parser->parse( $args{src}, $args{file} );
	$runtime->evaluate( $ast );

	return $runtime;
}

my $tmp = tempdir( CLEANUP => 1 );
my $mod_dir = File::Spec->catdir( $tmp, 'lib', 'extras' );
make_path( $mod_dir );

write_utf8(
	File::Spec->catfile( $mod_dir, 'math.zzm' ),
	<<'SRC'
let x := 1;
const c := 3;
function add_x (v) {
	x += v;
	return x;
}
function bar () {
	return "bar-ok";
}
SRC
);

write_utf8(
	File::Spec->catfile( $mod_dir, 'private.zzm' ),
	<<'SRC'
function _hidden () {
	return "hidden-ok";
}
function visible () {
	return "visible-ok";
}
SRC
);

my $script = <<'SRC';
from extras/math import add_x, x;
add_x(2);
SRC

my $runtime = parse_and_eval(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	src => $script,
	file => File::Spec->catfile( $tmp, 'main.zzs' ),
);

is $runtime->call( 'add_x', 0 ), 3,
	'imported symbols are aliases to original module values';

like dies {
	$parser->parse(
		<<'SRC', 'lexical.zzs'
function foo () {
	from extras/math import bar;
	return bar();
}
foo();
bar();
SRC
	);
}, qr/undeclared identifier 'bar'/,
	'lexical import does not leak imported names outside the scope';

my $star_runtime = parse_and_eval(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	src => <<'SRC',
from extras/math import *;
SRC
	file => File::Spec->catfile( $tmp, 'star.zzs' ),
);

ok $star_runtime, 'star imports parse and evaluate without compile-time undeclared errors';
is $star_runtime->call( 'bar' ), 'bar-ok',
	'star import makes exported module function callable';

my $private_runtime = parse_and_eval(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	src => <<'SRC',
from extras/private import *, _hidden;
SRC
	file => File::Spec->catfile( $tmp, 'private.zzs' ),
);

is $private_runtime->call( 'visible' ), 'visible-ok',
	'star import keeps importing public exports';
is $private_runtime->call( '_hidden' ), 'hidden-ok',
	'underscore-prefixed exports can be imported explicitly';

like dies {
	parse_and_eval(
		lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
		src => <<'SRC',
from extras/math import not_real;
SRC
		file => File::Spec->catfile( $tmp, 'no-builtins.zzs' ),
	);
}, qr/has no export 'not_real'/,
	'importing a missing symbol reports an export error';

my $conditional_runtime = parse_and_eval(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	src => <<'SRC',
let enabled := false;
from extras/math import bar if enabled;
from extras/math import add_x unless enabled;
function bar_is_null () {
	return bar ≡ null;
}
function add_x_is_null () {
	return add_x ≡ null;
}
SRC
	file => File::Spec->catfile( $tmp, 'conditional.zzs' ),
);

is $conditional_runtime->call( 'bar_is_null' ), 1,
	'postfix if false binds import alias to null const';
is $conditional_runtime->call( 'add_x_is_null' ), 0,
	'postfix unless false keeps import enabled';

my $try_runtime = parse_and_eval(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	src => <<'SRC',
from extras/not_real try import Missing;
function missing_is_null () {
	return Missing ≡ null;
}
SRC
	file => File::Spec->catfile( $tmp, 'try-missing.zzs' ),
);

is $try_runtime->call( 'missing_is_null' ), 1,
	'try import of missing module yields null const binding';

my $try_conditional_runtime = parse_and_eval(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	src => <<'SRC',
let enabled := true;
from extras/not_real try import Maybe if enabled;
function maybe_is_null () {
	return Maybe ≡ null;
}
SRC
	file => File::Spec->catfile( $tmp, 'try-conditional.zzs' ),
);

is $try_conditional_runtime->call( 'maybe_is_null' ), 1,
	'try import can combine with postfix if';

like dies {
	$parser->parse(
		<<'SRC',
from extras/math try import *;
SRC
		'try-star.zzs',
	);
}, qr/Wildcard import '\*' cannot be combined/,
	'try import rejects wildcard list';

like dies {
	$parser->parse(
		<<'SRC',
from extras/math import * if true;
SRC
		'if-star.zzs',
	);
}, qr/Wildcard import '\*' cannot be combined/,
	'postfix import condition rejects wildcard list';

like dies {
	$parser->parse(
		<<'SRC',
from foo/../../bar import Blah;
SRC
		'parent-segment.zzs',
	);
}, qr/Import module path cannot contain '\.\.' segments/,
	'import rejects parent-directory segments in module paths';

my $rel_root = tempdir( CLEANUP => 1 );
my $app_dir = File::Spec->catdir( $rel_root, 'app' );
my $rel_lib = File::Spec->catdir( $app_dir, 'lib', 'local' );
make_path( $rel_lib );

write_utf8(
	File::Spec->catfile( $rel_lib, 'tool.zzm' ),
	<<'SRC'
function value () {
	return 42;
}
SRC
);

my $rel_runtime = parse_and_eval(
	lib => [],
	src => <<'SRC',
from local/tool import value;
SRC
	file => File::Spec->catfile( $app_dir, 'run.zzs' ),
);

is $rel_runtime->call( 'value' ), 42,
	'module resolution searches relative script lib/ directory';

my $cache_root = tempdir( CLEANUP => 1 );
my $cache_lib = File::Spec->catdir( $cache_root, 'lib', 'cache' );
make_path( $cache_lib );
my $cache_module = File::Spec->catfile( $cache_lib, 'hot.zzm' );

write_utf8(
	$cache_module,
	<<'SRC'
function value () {
	return 7;
}
SRC
);

my $cache_ast = $parser->parse(
	<<'SRC',
from cache/hot import value;
SRC
	File::Spec->catfile( $cache_root, 'entry.zzs' ),
);

my $module_parse_count = 0;
my $orig_parse = Zuzu::Parser->can( 'parse' );
{
	no warnings 'redefine';
	local *Zuzu::Parser::parse = sub {
		my ( $self, $source, $path ) = @_;
		$module_parse_count++ if defined $path and $path eq $cache_module;
		return $orig_parse->( $self, $source, $path );
	};

	my $first = Zuzu::Runtime->new( lib => [ File::Spec->catdir( $cache_root, 'lib' ) ] );
	$first->evaluate( $cache_ast );
	is $first->call( 'value' ), 7,
		'cached module fixture initial value is callable';

	my $second = Zuzu::Runtime->new( lib => [ File::Spec->catdir( $cache_root, 'lib' ) ] );
	$second->evaluate( $cache_ast );
	is $second->call( 'value' ), 7,
		'module AST cache is reused across runtime instances';
}
is $module_parse_count, 1,
	'module source parse runs once when file metadata is unchanged';

write_utf8(
	$cache_module,
	<<'SRC'
function value () {
	return 11;
}
SRC
);

my $module_reparse_count = 0;
{
	no warnings 'redefine';
	local *Zuzu::Parser::parse = sub {
		my ( $self, $source, $path ) = @_;
		$module_reparse_count++ if defined $path and $path eq $cache_module;
		return $orig_parse->( $self, $source, $path );
	};

	my $updated = Zuzu::Runtime->new( lib => [ File::Spec->catdir( $cache_root, 'lib' ) ] );
	$updated->evaluate( $cache_ast );
	is $updated->call( 'value' ), 11,
		'module AST cache invalidates when module file metadata changes';
}
is $module_reparse_count, 1,
	'module parse reruns after module file update';

my $persistent_root = tempdir( CLEANUP => 1 );
my $persistent_cache_dir = File::Spec->catdir( $persistent_root, 'ast-cache' );
my $persistent_lib = File::Spec->catdir( $persistent_root, 'lib', 'persist' );
make_path( $persistent_lib );
my $persistent_module = File::Spec->catfile( $persistent_lib, 'hot.zzm' );

write_utf8(
	$persistent_module,
	<<'SRC'
function value () {
	return 13;
}
SRC
);

my $persistent_ast = $parser->parse(
	<<'SRC',
from persist/hot import value;
SRC
	File::Spec->catfile( $persistent_root, 'entry.zzs' ),
);

{
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_ROOT = $persistent_cache_dir;
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_MAX_SIZE = 100 * 1024 * 1024;
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_MAX_AGE = 30 * 24 * 60 * 60;
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_EXPIRY_RAN = 0;
	local %Zuzu::Runtime::MODULE_AST_CACHE = ();

	my $persistent_parse_count = 0;
	no warnings 'redefine';
	local *Zuzu::Parser::parse = sub {
		my ( $self, $source, $path ) = @_;
		$persistent_parse_count++ if defined $path and $path eq $persistent_module;
		return $orig_parse->( $self, $source, $path );
	};

	my $first = Zuzu::Runtime->new(
		lib => [ File::Spec->catdir( $persistent_root, 'lib' ) ],
	);
	$first->evaluate( $persistent_ast );
	is $first->call( 'value' ), 13,
		'persistent cache fixture initial value is callable';
	is $persistent_parse_count, 1,
		'persistent cache parses source before the cache entry exists';

	%Zuzu::Runtime::MODULE_AST_CACHE = ();
	my $second = Zuzu::Runtime->new(
		lib => [ File::Spec->catdir( $persistent_root, 'lib' ) ],
	);
	$second->evaluate( $persistent_ast );
	is $second->call( 'value' ), 13,
		'persistent cache hit preserves module behaviour';
	is $persistent_parse_count, 1,
		'persistent cache avoids reparsing across runtime instances';

	ok scalar( cache_files($persistent_cache_dir) ),
		'persistent cache writes Storable entries to disk';

	write_utf8(
		$persistent_module,
		<<'SRC'
function value () {
	return 17;
}
SRC
	);

	%Zuzu::Runtime::MODULE_AST_CACHE = ();
	my $updated = Zuzu::Runtime->new(
		lib => [ File::Spec->catdir( $persistent_root, 'lib' ) ],
	);
	$updated->evaluate( $persistent_ast );
	is $updated->call( 'value' ), 17,
		'persistent cache invalidates when module source changes';
	is $persistent_parse_count, 2,
		'changed module source reparses once';
}

{
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_ROOT = File::Spec->catdir( $persistent_root, 'disabled-cache' );
	local %Zuzu::Runtime::MODULE_AST_CACHE = ();

	my $disabled_parse_count = 0;
	no warnings 'redefine';
	local *Zuzu::Parser::parse = sub {
		my ( $self, $source, $path ) = @_;
		$disabled_parse_count++ if defined $path and $path eq $persistent_module;
		return $orig_parse->( $self, $source, $path );
	};

	for ( 1 .. 2 ) {
		%Zuzu::Runtime::MODULE_AST_CACHE = ();
		my $runtime = Zuzu::Runtime->new(
			lib => [ File::Spec->catdir( $persistent_root, 'lib' ) ],
			persistent_ast_cache => 0,
		);
		$runtime->evaluate( $persistent_ast );
		is $runtime->call( 'value' ), 17,
			'module evaluates correctly with persistent AST cache disabled';
	}

	is $disabled_parse_count, 2,
		'disabled persistent AST cache parses on each fresh runtime';
	ok !-d $Zuzu::Runtime::PERSISTENT_AST_CACHE_ROOT,
		'disabled persistent AST cache does not create a cache directory';
}

{
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_ROOT = $persistent_cache_dir;
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_EXPIRY_RAN = 0;
	local %Zuzu::Runtime::MODULE_AST_CACHE = ();

	my @files = cache_files($persistent_cache_dir);
	ok @files, 'persistent cache has an entry to corrupt';
	write_raw( $_, "not a storable cache entry\n" ) for @files;

	my $corrupt_parse_count = 0;
	no warnings 'redefine';
	local *Zuzu::Parser::parse = sub {
		my ( $self, $source, $path ) = @_;
		$corrupt_parse_count++ if defined $path and $path eq $persistent_module;
		return $orig_parse->( $self, $source, $path );
	};

	my $runtime = Zuzu::Runtime->new(
		lib => [ File::Spec->catdir( $persistent_root, 'lib' ) ],
	);
	$runtime->evaluate( $persistent_ast );
	is $runtime->call( 'value' ), 17,
		'corrupt persistent cache entry falls back to parsing';
	is $corrupt_parse_count, 1,
		'corrupt persistent cache entry reparses once';
}

{
	my $expiry_cache_dir = File::Spec->catdir( $persistent_root, 'expiry-cache' );
	make_path($expiry_cache_dir);
	my $old_file = File::Spec->catfile( $expiry_cache_dir, 'old.stor' );
	my $big_file = File::Spec->catfile( $expiry_cache_dir, 'big.stor' );
	write_raw( $old_file, 'old-cache-entry' );
	write_raw( $big_file, 'big-cache-entry' x 20 );
	utime time - 120, time - 120, $old_file;
	utime time - 60, time - 60, $big_file;

	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_ROOT = $expiry_cache_dir;
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_MAX_AGE = 30;
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_MAX_SIZE = 20;
	local $Zuzu::Runtime::PERSISTENT_AST_CACHE_EXPIRY_RAN = 0;
	local %Zuzu::Runtime::MODULE_AST_CACHE = ();

	my $runtime = Zuzu::Runtime->new(
		lib => [ File::Spec->catdir( $persistent_root, 'lib' ) ],
	);
	$runtime->evaluate( $persistent_ast );
	is $runtime->call( 'value' ), 17,
		'module evaluates while persistent cache expiry runs';
	ok !-e $old_file,
		'persistent cache expiry removes entries older than max age';

	my $total_size = 0;
	$total_size += -s $_ for cache_files($expiry_cache_dir);
	cmp_ok $total_size, '<=', 20,
		'persistent cache expiry enforces the size budget';

	$runtime->clear_persistent_ast_cache;
	is [ cache_files($expiry_cache_dir) ], [],
		'clear_persistent_ast_cache removes persistent cache files';
}

my $builtin_runtime = Zuzu::Runtime->new(
	lib => [],
	builtin => {
		json => 'Zuzu::Module::JSON',
		math => 'Zuzu::Module::Math',
		io => 'Zuzu::Module::IO',
		'std/time' => 'Zuzu::Module::Time',
		'std/proc' => 'Zuzu::Module::Proc',
	},
);
my $builtin_ast = $parser->parse(
	<<'SRC',
from json import JSON;
let j := new JSON( utf8: true, pretty: false, canonical: true );
let got := j.encode( { arr: [ 7, 8, 9 ], bool: true } );
let h := j.decode( got );
function second_item () {
	return h{arr}[1];
}
function json_text () {
	return got;
}
SRC
	'builtin-json.zzs',
);
$builtin_runtime->evaluate( $builtin_ast );
is $builtin_runtime->call( 'second_item' ), 8,
	'builtin JSON module decodes array values';
like $builtin_runtime->call( 'json_text' ),
	qr/"arr"\s*:\s*\[\s*7,\s*8,\s*9\s*\]/,
	'builtin JSON module encodes structured values';

my $math_ast = $parser->parse(
	<<'SRC',
from math import Math, π;
function sin_half_pi_scaled () {
	return round( Math.sin( Math.pi / 2 ) * 1000 );
}
function unicode_pi_scaled () {
	return round( π * 1000 );
}
function rand_unit_interval () {
	let x := Math.rand();
	return x >= 0 and x < 1;
}
function trig_combo_scaled () {
	return round( Math.sec(0) + Math.cosec( Math.pi / 2 ) + Math.cotan( Math.pi / 4 ) );
}
SRC
	'builtin-math.zzs',
);
$builtin_runtime->evaluate( $math_ast );
is $builtin_runtime->call( 'sin_half_pi_scaled' ), 1000,
	'builtin Math module provides sine and pi constant access';
is $builtin_runtime->call( 'unicode_pi_scaled' ), 3142,
	'builtin Math module exports top-level π constant';
is $builtin_runtime->call( 'rand_unit_interval' ), 1,
	'builtin Math module rand returns values in [0, 1)';
is $builtin_runtime->call( 'trig_combo_scaled' ), 3,
	'builtin Math module provides reciprocal trig functions';


my $io_ast = $parser->parse(
	<<'SRC',
from io import Path;
let io_cwd_path := Path.cwd();
let io_root_path := Path.rootdir();
let io_tmp_file := Path.tempfile();

io_tmp_file.spew_utf8( "alpha\nbeta\n" );

let io_got_lines := [];
io_tmp_file.each_line( function (line) {
	io_got_lines.push(line);
} );

function io_cwd_absolute () {
	return io_cwd_path.is_absolute();
}

function io_root_is_root () {
	return io_root_path.is_rootdir();
}

function io_tail_name () {
	return io_tmp_file.basename();
}

function io_line_count () {
	return io_got_lines.length();
}

function io_next_line_returns_null () {
	while ( io_tmp_file.next_line() ≢ null ) {
		// consume all lines
	}
	return io_tmp_file.next_line() ≡ null;
}
SRC
	'builtin-io.zzs',
);
$builtin_runtime->evaluate( $io_ast );
is $builtin_runtime->call( 'io_cwd_absolute' ), 1,
	'builtin IO module Path.cwd returns absolute path';
is $builtin_runtime->call( 'io_root_is_root' ), 1,
	'builtin IO module Path.rootdir returns root path';
like $builtin_runtime->call( 'io_tail_name' ), qr/\S/,
	'builtin IO module tempfile has basename';
is $builtin_runtime->call( 'io_line_count' ), 2,
	'builtin IO module each_line iterates lines with trailing newline';
is $builtin_runtime->call( 'io_next_line_returns_null' ), 1,
	'builtin IO module next_line returns null at EOF';

my $time_ast = $parser->parse(
	<<'SRC',
from std/time import Time, TimeParser;
let t0 := new Time(2);

function time_epoch_plus_minute () {
	return t0.add_minutes(1).epoch();
}

function time_day_of_month () {
	return t0.day_of_month();
}

function time_format_from_to_string () {
	return t0.to_String();
}

function parsed_time_year () {
	let p := new TimeParser("%A %drd %b, %Y");
	let t := p.parse("Sunday 3rd Nov, 1943");
	return t.year();
}

function parsed_time_day_of_month () {
	let p := new TimeParser("%A %drd %b, %Y");
	let t := p.parse("Sunday 3rd Nov, 1943");
	return t.day_of_month();
}
SRC
	'builtin-time.zzs',
);
$builtin_runtime->evaluate( $time_ast );
is $builtin_runtime->call( 'time_epoch_plus_minute' ), 62,
	'builtin Time module supports add_minutes arithmetic';
is $builtin_runtime->call( 'time_day_of_month' ), 1,
	'builtin Time module exposes long-form day_of_month';
like $builtin_runtime->call( 'time_format_from_to_string' ),
	qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/,
	'builtin Time module to_String uses ISO-like datetime format';
is $builtin_runtime->call( 'parsed_time_year' ), 1943,
	'builtin TimeParser parses with strptime format string';
is $builtin_runtime->call( 'parsed_time_day_of_month' ), 3,
	'builtin TimeParser parse result exposes long-form day_of_month';

my $no_short_alias_ast = $parser->parse(
	<<'SRC',
from std/time import Time;
let t := new Time(2);
function short_alias_value () {
	return t.mday();
}
SRC
	'builtin-time-no-short-alias.zzs',
);
$builtin_runtime->evaluate( $no_short_alias_ast );
like dies {
	$builtin_runtime->call( 'short_alias_value' );
}, qr/Unknown method 'mday'/,
	'builtin Time module does not expose short alias mday';

my $proc_ast = $parser->parse(
	<<'SRC',
from std/proc import Proc, Env;

function proc_import_pid_is_number () {
	return Proc.pid() > 1;
}

function proc_import_env_roundtrip () {
	let key := "ZUZU_IMPORT_FEATURES_PROC";
	Env.remove(key);
	Env.set(key, "proc-ok");
	let got := Env.get(key, "fallback");
	Env.remove(key);
	return got;
}

function proc_import_run_with_stdin () {
	let res := Proc.run(
		"perl",
		[
			"-e",
			"my $x = <STDIN>; print $x;",
		],
		{
			stdin: "feed-me\n",
		},
	);
	return res{stdout};
}

let proc_signal_seen := 0;
Proc.onsignal( "USR1", function () {
	proc_signal_seen++;
} );

function proc_import_onsignal_callback_runs () {
	Proc.kill( "USR1", Proc.pid() );
	let spin := 0;
	while ( proc_signal_seen == 0 and spin < 1000 ) {
		spin++;
	}
	return proc_signal_seen;
}
SRC
	'builtin-proc.zzs',
);
$builtin_runtime->evaluate( $proc_ast );
is $builtin_runtime->call( 'proc_import_pid_is_number' ), 1,
	'builtin Proc module returns current process id';
is $builtin_runtime->call( 'proc_import_env_roundtrip' ), 'proc-ok',
	'builtin Env helper reads and writes environment variables';
is $builtin_runtime->call( 'proc_import_run_with_stdin' ), "feed-me\n",
	'builtin Proc module run supports stdin interaction';
is $builtin_runtime->call( 'proc_import_onsignal_callback_runs' ), 1,
	'builtin Proc module onsignal invokes callback for delivered signal';

my $repo_root = File::Spec->rel2abs( File::Spec->catdir( File::Spec->curdir ) );
my $zuzu_bin = File::Spec->catfile( $repo_root, 'bin', 'zuzu.pl' );
my $exit_script = File::Spec->catfile( $tmp, 'proc-exit.zzs' );
write_utf8(
	$exit_script,
	<<'SRC'
from std/proc import Proc;
Proc.exit(7);
SRC
);
my $exit_cmd = "$^X $zuzu_bin $exit_script 2>&1";
qx{$exit_cmd};
my $exit_code = $? >> 8;
is $exit_code, 7,
	'builtin Proc module exit terminates process with requested status';

done_testing;
