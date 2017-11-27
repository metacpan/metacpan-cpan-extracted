use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Text::VisualPrintf;

use Test::More tests => 8;

is( Text::VisualPrintf::sprintf( "%5s", '%s'),     '   %s', '%s in %s' );
is( Text::VisualPrintf::sprintf( "%5s", '$^X'),    '  $^X', 'VAR' );
is( Text::VisualPrintf::sprintf( "%5s", '@ARGV'),  '@ARGV', 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "\001\001", "日本語", "\001\002" ),
    "(\001\001, 日本語, \001\002)", 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "日本語", "\001\001", "\001\002" ),
    "(日本語, \001\001, \001\002)", 'ARRAY' );

is( Text::VisualPrintf::sprintf( "\001\001(%s, %s, %s)",
				 "壱", "日本語", "\001\002" ),
    "\001\001(壱, 日本語, \001\002)", 'ARRAY' );

sub ctrls {
    my($i, $j) = @_;
    my @seq;
    for my $i (1 .. $i) {
	for my $j (1 .. $j//$i) {
	    push @seq, pack "CC", $i, $j;
	}
    }
    join '', @seq;
};

my $longseq = ctrls(5, 4);
is( Text::VisualPrintf::sprintf("$longseq(%5s)", "壱"),
    "$longseq(   壱)",
    'Long binary format.');

 TODO:
{
    local $TODO = "Outlimit";
    my $allseq = ctrls(5, 5);
    is( Text::VisualPrintf::sprintf("$allseq(%5s)", "壱"),
	"$allseq(   壱)",
	'All binary pattern format.');
}

done_testing;
