use Test2::V0;

use Zuzu qw(
	zuzu_eval
	zuzu_evalfile
);

use File::Spec;
use File::Temp qw( tempdir );

is(
	zuzu_eval('1 + 2;'),
	3,
	'zuzu_eval returns evaluation result',
);

my $tmpdir = tempdir( CLEANUP => 1 );
my $script = File::Spec->catfile( $tmpdir, 'result.zzs' );
open my $fh, '>:encoding(UTF-8)', $script
	or die "Could not create $script: $!";
print {$fh} "2 + 5;\n";
close $fh;

is(
	zuzu_evalfile($script),
	7,
	'zuzu_evalfile returns evaluation result',
);

done_testing;
