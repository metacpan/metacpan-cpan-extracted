use v5.14;
use warnings;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold qw(ansi_fold);
use Text::Tabs;

Text::ANSI::Fold->configure(expand => 1);

sub folded { (ansi_fold(@_))[0] }
sub unesc { $_[0] =~ s/([\t\e])/{"\t"=>"\\t","\e"=>"\\e"}->{$1}/ger }
sub r { $_[0] =~ s/(\d+)/\e[31m$1\e[m/gr }

for my $t (split "\n", <<"END"
#1234567890123456789
0	89
0123	89
01234567	67
END
) {
    next if $t =~ /^#/;
    my $x = expand $t;
    for my $l (1 .. length($x) + 1) {
	for my $p (
	    [ $t => folded($x, $l) ],
	    [ r($t) => r(folded($x, $l)) ],
	    )
	{
	    my($s, $a) = @$p;
	    is(folded($s, $l), $a, sprintf("fold(\"%s\", %d) -> \"%s\"", $s, $l, $a));
	}
    }
}

Text::ANSI::Fold->configure(expand => 1, tabstyle => 'shade');

for my $t (split "\n", <<"END"
#1234567890123456789
0	89
0123	89
01234567	67
END
) {
    next if $t =~ /^#/;
    my $x = expand $t;
    for my $l (1 .. length($x) + 1) {
	for my $p (
	    [ $t => folded($x, $l) ],
	    [ r($t) => r(folded($x, $l)) ],
	    )
	{
	    my($s, $a) = @$p;
	    $a =~ s/( )( *)/'▒' x length($1) . '░' x length($2)/ge;
	    is(folded($s, $l), $a, sprintf("fold(\"%s\", %d) with shade tabs", $s, $l));
	}
    }
}

done_testing;
