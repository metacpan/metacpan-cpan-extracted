use Test2::V0;
use File::Path qw( make_path remove_tree );
use File::Spec;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src, $runtime_args, $filename ) = @_;
	my $runtime = Zuzu::Runtime->new( %{ $runtime_args // {} } );
	my $ast = $parser->parse( $src, defined $filename ? $filename : "system-globals.zzs" );

	return $runtime->evaluate($ast);
}

is eval_src(<<"SRC"), "Zuzu::Runtime", "__system__ exposes runtime name";
__system__{runtime};
SRC

is eval_src(<<"SRC"), "0", "__system__ exposes language version";
"" _ __system__{language_version};
SRC

like eval_src(<<"SRC"), qr/\A\d+\.\d{6}\z/, "__system__ exposes perl version";
"" _ __system__{perl_version};
SRC

is eval_src(
	'__system__{inc}[0] _ ":" _ __system__{inc}[1];',
	{
		lib => [ "/opt/zuzu/modules", "/tmp/extra/modules" ],
	}
), "/opt/zuzu/modules:/tmp/extra/modules",
	"__system__ exposes lib search paths as Array";

like(
	dies {
		eval_src(<<"SRC", { lib => [ "/opt/zuzu/modules" ] });
__system__{inc}.append( "/tmp/other" );
SRC
	},
	qr/Cannot modify __system__/,
	"__system__ rejects inc array mutation",
);

is eval_src(<<"SRC"), "ok", "__global__ is writable";
__global__.set( "mode", "ok" );
__global__{mode};
SRC

like(
	dies {
		eval_src(<<"SRC");
__system__.set( "runtime", "X" );
SRC
	},
	qr/Cannot modify __system__/,
	"__system__ rejects dict method mutation",
);

like(
	dies {
		eval_src(<<"SRC");
__system__{runtime} := "X";
SRC
	},
	qr/Cannot modify __system__/,
	"__system__ rejects dict assignment mutation",
);

like(
	dies {
		eval_src(<<"SRC");
__system__ := {};
SRC
	},
	qr/Cannot assign to const '__system__'/,
	"__system__ binding is const",
);

is eval_src(<<"SRC"), "system-globals.zzs", "__file__ exposes the initial source file";
__file__.to_String();
SRC

is eval_src(<<"SRC", { deny => [ "fs" ] }), undef, "__file__ is null when fs is denied";
__file__;
SRC

my $tmp_root = File::Spec->catdir( File::Spec->tmpdir, "zuzu-perl-file-global-$$" );
my $module_dir = File::Spec->catdir( $tmp_root, 'modules' );
make_path($module_dir);
my $module_path = File::Spec->catfile( $module_dir, 'file_probe.zzm' );
open my $module_fh, '>:encoding(UTF-8)', $module_path
	or die "Could not write $module_path: $!";
print {$module_fh} "const module_file := __file__.to_String();\n";
close $module_fh;

is eval_src(<<"SRC", { lib => [ $module_dir ] }), File::Spec->rel2abs( $module_path ), "__file__ is absolute in loaded modules";
from file_probe import module_file;
module_file;
SRC

remove_tree($tmp_root);

done_testing;
