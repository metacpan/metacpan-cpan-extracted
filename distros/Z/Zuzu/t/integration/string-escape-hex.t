use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'string-escape-hex.zzs' );

	return $runtime->evaluate( $ast );
}

is eval_src(<<'SRC'), "\e[32mPASS\e[0m", 'double-quoted strings decode \\xNN escapes';
"\x1b[32mPASS\x1b[0m";
SRC

is eval_src(<<'SRC'), "\e[32mPASS\e[0m", 'template literals decode \\xNN escapes';
`\x1b[32mPASS\x1b[0m`;
SRC

like dies {
	eval_src(<<'SRC');
"\x4";
SRC
}, qr/Invalid string escape/, 'double-quoted string rejects short \\x escape';

like dies {
	eval_src(<<'SRC');
`\xZZ`;
SRC
}, qr/Invalid template escape/, 'template literal rejects invalid \\x escape';

done_testing;
