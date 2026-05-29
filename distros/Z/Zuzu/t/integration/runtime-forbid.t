use Test2::V0;
use Test2::Require::AuthorTesting;

use Zuzu qw( zuzu_eval );

my $script = <<'ZZS';
from std/io import Path;
ZZS

like(
	dies { zuzu_eval( $script, { deny_modules => [ 'std/io' ] } ) },
	qr/denied by runtime policy/,
	'deny_modules rejects blocked module imports',
);

like(
	dies { zuzu_eval( $script, { forbid => [ 'std/io' ] } ) },
	qr/denied by runtime policy/,
	'legacy forbid alias still rejects blocked imports',
);

ok(
	lives { zuzu_eval( 'from std/data/json import JSON;' ) },
	'non-forbidden modules still load',
);

like(
	dies { zuzu_eval( 'from std/net/dns import lookup; lookup("localhost", "BOGUS");' ) },
	qr/unsupported DNS record type 'BOGUS'/,
	'std/net/dns rejects unsupported record types',
);

ok(
	lives { zuzu_eval( 'from std/archive import Archive;' ) },
	'std/archive remains importable without fs access because it supports in-memory operations',
);

like(
	dies { zuzu_eval( 'from std/io import Path;', { deny => [ 'fs' ] } ) },
	qr/Cannot find module 'std\/io' in lib paths/,
	'deny fs makes std/io unavailable',
);

like(
	dies { zuzu_eval( 'from std/io/socks import SocksServer;', { deny => [ 'fs' ] } ) },
	qr/Cannot find module 'std\/io\/socks' in lib paths/,
	'deny fs also hides std/io submodules',
);

like(
	dies { zuzu_eval( 'from std/net/http import HTTP;', { deny => [ 'net' ] } ) },
	qr/Cannot find module 'std\/net\/http' in lib paths/,
	'deny net hides std/net modules',
);

like(
	dies { zuzu_eval( 'from std/net/dns import lookup;', { deny => [ 'net' ] } ) },
	qr/Cannot find module 'std\/net\/dns' in lib paths/,
	'deny net hides std/net/dns',
);

like(
	dies { zuzu_eval( 'from std/io/socks import Socket;', { deny => [ 'net' ] } ) },
	qr/Cannot find module 'std\/io\/socks' in lib paths/,
	'deny net hides std/io/socks builtin module',
);

like(
	dies {
		zuzu_eval(
			'from std/data/json import JSON; let j := new JSON(); j.load(null);',
			{ deny => [ 'fs' ] },
		);
	},
	qr/JSON\.load is denied by runtime policy/,
	'JSON.load throws when fs is denied',
);

like(
	dies {
		zuzu_eval(
			'from std/archive import Archive; Archive.load(null);',
			{ deny => [ 'fs' ] },
		);
	},
	qr/Archive\.load is denied by runtime policy/,
	'Archive.load throws when fs is denied',
);

like(
	dies {
		zuzu_eval(
			'from perl import Perl; Perl.eval("1 + 1");',
			{ deny => [ 'perl' ] },
		);
	},
	qr/Perl\.eval is denied by runtime policy/,
	'Perl.eval throws when perl is denied',
);

ok(
	lives { zuzu_eval( 'from std/io import Path;', { allow => [ 'fs' ] } ) },
	'allow fs keeps std/io importable',
);

like(
	dies { zuzu_eval( 'from std/net/http import HTTP;', { allow => [ 'fs' ] } ) },
	qr/Cannot find module 'std\/net\/http' in lib paths/,
	'allow list denies net when not listed',
);

like(
	dies {
		zuzu_eval(
			'from perl import Perl; Perl.eval("1 + 1");',
			{ allow => [ 'fs' ] },
		);
	},
	qr/Perl\.eval is denied by runtime policy/,
	'allow list denies perl when not listed',
);

is(
	zuzu_eval( '__system__{deny_fs};', { deny => [ 'fs' ] } ),
	1,
	'__system__.deny_fs is true when fs is denied',
);

is(
	zuzu_eval(
		<<'ZZS',
from std/tui import filename_completions, directory_completions;
filename_completions( "modules/std/tu" ).length()
	_ ":" _ directory_completions( "modules/st" ).length();
ZZS
		{ deny => [ 'fs' ] },
	),
	'0:0',
	'std/tui filesystem completions are empty when fs is denied',
);

is(
	zuzu_eval( '__system__{deny_net};', { deny => [ 'net' ] } ),
	1,
	'__system__.deny_net is true when net is denied',
);

is(
	zuzu_eval( '__system__{deny_gui};' ),
	0,
	'__system__.deny_gui defaults to false',
);

is(
	zuzu_eval( '__system__{deny_gui};', { deny => [ 'gui' ] } ),
	1,
	'__system__.deny_gui is true when gui is denied',
);

like(
	dies { zuzu_eval( 'from std/gui/objects import Widget;', { deny => [ 'gui' ] } ) },
	qr/std\/gui\/objects is denied by runtime policy/,
	'deny gui rejects std/gui/objects at import time',
);

is(
	zuzu_eval(
		<<'ZZS',
from std/gui/dialogue import confirm, prompt, file_open;
from std/tui import filename_completions;
( confirm( "Q", auto_result: true ) ? "yes" : "no" )
	_ ":" _ prompt( "Name:", auto_result: "Ada" )
	_ ":" _ file_open( auto_result: "x.txt" )
	_ ":" _ ( filename_completions( "modules/std/tu" ).length() > 0 );
ZZS
		{ deny => [ 'gui' ] },
	),
	'yes:Ada:x.txt:1',
	'std/gui/dialogue loads with deny gui and uses non-GUI results',
);

is(
	zuzu_eval( '__system__{deny_perl};', { deny => [ 'perl' ] } ),
	1,
	'__system__.deny_perl is true when perl is denied',
);

is(
	zuzu_eval( '__system__{deny_js};' ),
	1,
	'__system__.deny_js is always true in the Perl runtime',
);

like(
	dies { zuzu_eval( 'from javascript import JS;' ) },
	qr/Cannot find module 'javascript' in lib paths/,
	'Perl runtime treats javascript as unavailable because js is denied',
);

is(
	zuzu_eval( '__system__{deny_net};', { allow => [ 'fs' ] } ),
	1,
	'allow list reflects deny_net when net is omitted',
);

done_testing;
