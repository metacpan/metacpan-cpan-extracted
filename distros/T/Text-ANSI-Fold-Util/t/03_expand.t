use v5.14;
use warnings;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold::Util qw(ansi_expand);
use Text::Tabs;
use Data::Dumper;

Text::ANSI::Fold->configure(expand => 1);

sub r { $_[0] =~ s/(\S+)/\e[31m$1\e[m/gr }

for my $t (split "\n", <<"END"
#1234567890123456789
0	89
0123	89
01234567	67
END
) {
    next if $t =~ /^#/;
    my $x = expand $t;
    for my $p (
	[ $t => $x ],
	[ r($t) => r($x) ],
	)
    {
	my($s, $a) = @$p;
	is(expand($s), $a, sprintf("expand(\"%s\") -> \"%s\"", $s, $a));
    }
}

for my $t (<<"END"
#1234567890123456789
0	89
0123	89
01234567	67
END
) {
    my $x = expand $t;
    for my $p (
	[ $t => $x ],
	[ r($t) => r($x) ],
	)
    {
	my($s, $a) = @$p;
	is(expand($s), $a, sprintf("expand(\"%s\") -> \"%s\"", $s, $a));
    }

    my @t = split /^/m, $t;
    my @rt = map r($_), @t;
    my @x = expand @t;
    my @rx = map r($_), @x;
    for my $p (
	[ \@t => \@x ],
	[ \@rt => \@rx ],
	)
    {
	my($s, $a) = @$p;
	is_deeply([ expand(@$s) ], $a,
		  sprintf("expand(\"%s\") -> \"%s\"", Dumper $s, Dumper $a));
    }
}

done_testing;
