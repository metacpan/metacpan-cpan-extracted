use v5.14;
use warnings;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold::Util qw(ansi_expand);
use Text::Tabs;
use Data::Dumper;

Text::ANSI::Fold->configure(expand => 1);

sub r { $_[0] =~ s/(\S+)/\e[31m$1\e[m/gr }

my $pattern = <<"END";
#12345670123456701
0	01	01
	0	01
0123		01
01234567	01
		01
END

for my $t (split "\n", $pattern) {
    next if $t =~ /^#/;
    my $x = expand $t;
    for my $p (
	[ $t => $x ],
	[ r($t) => r($x) ],
	)
    {
	my($s, $a) = @$p;
	is(ansi_expand($s), $a, sprintf("ansi_expand(\"%s\") -> \"%s\"", $s, $a));
    }
}

for my $t ($pattern) {
    my $x = expand $t;
    for my $p (
	[ $t => $x ],
	[ r($t) => r($x) ],
	)
    {
	my($s, $a) = @$p;
	is(ansi_expand($s), $a, sprintf("ansi_expand(\"%s\") -> \"%s\"", $s, $a));
    }

    my @t = split /^/m, $t;
    my @x = expand @t;
    my @rt = map r($_), @t;
    my @rx = map r($_), @x;
    for my $p (
	[ \@t => \@x ],
	[ \@rt => \@rx ],
	)
    {
	my($s, $a) = @$p;
	is_deeply([ ansi_expand(@$s) ], $a,
		  sprintf("expand(\"%s\") -> \"%s\"", Dumper $s, Dumper $a));
    }
}

done_testing;
