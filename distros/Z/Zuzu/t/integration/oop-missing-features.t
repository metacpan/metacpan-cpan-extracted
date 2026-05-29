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

sub run_src {
	my ( %args ) = @_;

	my $runtime = Zuzu::Runtime->new( lib => $args{lib} );
	my $ast = $parser->parse( $args{src}, $args{file} );
	my $result = $runtime->evaluate($ast);

	return ( $runtime, $result );
}

my $tmp = tempdir( CLEANUP => 1 );
my $mod_dir = File::Spec->catdir( $tmp, 'lib', 'zoo' );
make_path( $mod_dir );

write_utf8(
	File::Spec->catfile( $mod_dir, 'core.zzm' ),
	<<'SRC'
class Animal {
	let name;
	method get_name () {
		return name;
	}
}

trait Named {
	method tagged_name () {
		return "tag:" _ self.get_name();
	}
}
SRC
);

my ( undef, $tagged ) = run_src(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	file => File::Spec->catfile( $tmp, 'main.zzs' ),
	src => <<'SRC',
from zoo/core import Animal, Named;
class Dog extends Animal with Named {
}
let d := new Dog( name: "Bluey" );
d.tagged_name();
SRC
);

is $tagged, 'tag:Bluey',
	'class can extend an imported class and compose an imported trait';

my ( undef, $checks ) = run_src(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	file => File::Spec->catfile( $tmp, 'ops.zzs' ),
	src => <<'SRC',
from zoo/core import Animal, Named;
class Dog extends Animal with Named;
let d := new Dog( name: "Mochi" );
( d instanceof Animal ) + ( d does Named );
SRC
);

is $checks, 2,
	'instanceof and does operators work for object/class relationships';

my ( undef, $but_result ) = run_src(
	lib => [ File::Spec->catdir( $tmp, 'lib' ) ],
	file => File::Spec->catfile( $tmp, 'but.zzs' ),
	src => <<'SRC',
from zoo/core import Animal, Named;
class Fox extends Animal but Named;
let f := new Fox( name: "Rin" );
f.tagged_name();
SRC
);

is $but_result, 'tag:Rin',
	'class composition supports the "but" alias for "with"';

done_testing;
