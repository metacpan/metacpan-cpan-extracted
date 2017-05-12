{
	package Joo;
	#use rig ":base";
	use rig -engine=>'base', -jit;
	use rig moose;

	has 'aa' => is=>'rw', isa=>'Str';

	method tellme($name) {
		print "NAM=$name\n";
	}

}

package main;
use rig qw/goo bam/;
my $a = new Joo;

$a->tellme( 'rod' );
say "First " . first { $_ > 2 } 1..10;

my $bbb = 101;
open my $ff, '<', 'lkdjflskj';

say Dumper({ aa=>11 });
1;
