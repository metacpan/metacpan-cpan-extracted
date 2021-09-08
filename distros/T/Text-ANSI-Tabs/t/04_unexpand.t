use v5.14;
use warnings;
use Test::More 0.98;
use utf8;
use open IO => ':utf8', ':std';

use Text::ANSI::Tabs qw(ansi_expand ansi_unexpand);
use Text::Tabs;
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

my $pattern = <<"END";
#12345670123456701
0       01      01
        0       01
0123            01
01234567        01
                01
END

for my $t (split "\n", $pattern) {
    next if $t =~ /^#/;
    my $u = unexpand $t;
    for my $p (
	[ $t => $u ],
	[ r($t) => r($u) ],
	)
    {
	my($s, $a) = @$p;
	is(ansi_unexpand($s), $a,
	   sprintf("ansi_unexpand(\"%s\") -> \"%s\"", $s, $a));
    }
}

for my $t ($pattern) {
    my $u = unexpand $t;
    for my $p (
	[ $t => $u ],
	[ r($t) => r($u) ],
	)
    {
	my($s, $a) = @$p;
	is(ansi_unexpand($s), $a,
	   sprintf("ansi_unexpand(\"%s\") -> \"%s\"", $s, $a));
    }

    my @t = split /^/m, $t;
    my @u = unexpand @t;
    my @rt = map r($_), @t;
    my @ru = map r($_), @u;
    for my $p (
	[ \@t => \@u ],
	[ \@rt => \@ru ],
	)
    {
	my($s, $a) = @$p;
	is_deeply([ ansi_unexpand(@$s) ], $a,
		  sprintf("expand(\"%s\") -> \"%s\"", Dumper $s, Dumper $a));
    }
}

my $color_re    = qr{ \e \[ [\d;]* m }x;
my $reset_re    = qr{ \e \[ [0;]* m }x;
my $erase_re    = qr{ \e \[ [\d;]* K }x;
my $end_re      = qr{ $reset_re | $erase_re }x;
my $csi_re      = qr{
    # see ECMA-48 5.4 Control sequences
    \e \[		# csi
    [\x30-\x3f]*	# parameter bytes
    [\x20-\x2f]*	# intermediate bytes
    [\x40-\x7e]		# final byte
}x;

for (
     [ '' => '', 'null' ],
     [ '一' => '一', 'no tab' ],
     [ '        ' => "\t", 'single tab' ],
     [ '        ' x 2 => "\t\t", 'double tab' ],
     [ '        x' => "\tx", 'head' ],
     [ '         x' => "\t x", 'head+' ],
     [ '一      x' => "一\tx", 'middle' ],
     [ '一       x' => "一\t x", 'middle+' ],
     [ '一二三  x' =>
       "一二三\tx",'middle' ],
     [ '一二三  一二三  x' =>
       "一二三\t一二三\tx",'middle x 2' ],
     [ '一二三四        x' =>
       "一二三四\tx", 'boundary' ],
     [ 'x一二三四       x' =>
       "x一二三四\tx", 'wide char on the boundary' ],
     [ 'x一二三四一二三四       x' =>
       "x一二三四一二三四\tx", 'double wide boundary' ],
    ) {

    my($s, $a, $msg) = @$_;

    if (1) {
	my $u = ansi_unexpand($s);
	is($u, $a, $msg)
	    or warn Dumper $u, $s;
    }

    if (1) {
	my $rs = r($a);
	my $ru = ansi_unexpand(r($s));
	is($ru, $rs, "$msg (color non-space)")
	    or warn Dumper $ru, $rs;
    };

    if (1) {
	my $opt = { pattern => q/\s+/ };
	my $rs = r($opt, $a);
	my $ru = ansi_unexpand(r($opt, $s));
	is($ru, $rs, "$msg (color space)")
	    or warn Dumper $ru, $rs;
    }

    if (1) {
	my $opt = { pattern => q/.+/ };
	my $rs = r($opt, $a);
	my $ru = ansi_unexpand(r($opt, $s));
	is($ru, $rs, "$msg (color all)")
	    or warn Dumper $ru, $rs;
    }
}

done_testing;
