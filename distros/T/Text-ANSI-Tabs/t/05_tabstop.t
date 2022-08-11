use v5.14;
use warnings;
use Test::More 0.98;
use utf8;
use open IO => ':utf8', ':std';

use Text::ANSI::Tabs qw(ansi_expand);
use Text::Tabs qw(expand);
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

sub r {
    my $opt = ref $_[0] ? shift : {};
    my $pattern = $opt->{pattern} ||  q/\S+/;
    $_[0] =~ s/($pattern)/\e[97;41m$1\e[m/gr;
}

$Text::Tabs::tabstop = $Text::ANSI::Tabs::tabstop = 4;

my $pattern = <<"END";
#123012301
0	01	01
	0	01
01		01
0123	01
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

for (
     [ '' => '', 'null' ],
     [ '一' => '一', 'no tab' ],
     [ '    ' => "\t", 'single tab' ],
     [ '    ' x 2 => "\t\t", 'double tab' ],
     [ '    x' => "\tx", 'head' ],
     [ '     x' => "\t x", 'head+' ],
     [ '一  x' => "一\tx", 'middle' ],
     [ '一   x' => "一\t x", 'middle+' ],
     [ '一  x' =>
       "一\tx",'middle' ],
     [ '一  一  x' =>
       "一\t一\tx",'middle x 2' ],
     [ '一二    x' =>
       "一二\tx", 'boundary' ],
     [ 'x一二   x' =>
       "x一二\tx", 'wide char on the boundary' ],
     [ 'x一二一二   x' =>
       "x一二一二\tx", 'double wide boundary' ],
) {

	my($a, $s, $msg) = @$_;

	if (1) {
		my $u = ansi_expand($s);
		is($u, $a, $msg)
			or warn Dumper $u, $s;
	}

	if (1) {
		my $rs = r($a);
		my $ru = ansi_expand(r($s));
		is($ru, $rs, "$msg (color non-space)")
			or warn Dumper $ru, $rs;
	};

	if (1) {
		my $opt = { pattern => q/\s+/ };
		my $rs = r($opt, $a);
		my $ru = ansi_expand(r($opt, $s));
		is($ru, $rs, "$msg (color space)")
			or warn Dumper $ru, $rs;
	}

	if (1) {
		my $opt = { pattern => q/.+/ };
		my $rs = r($opt, $a);
		my $ru = ansi_expand(r($opt, $s));
		is($ru, $rs, "$msg (color all)")
			or warn Dumper $ru, $rs;
	}
}

done_testing;
