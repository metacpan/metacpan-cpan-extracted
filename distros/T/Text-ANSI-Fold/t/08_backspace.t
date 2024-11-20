use v5.14;
use warnings;
use Test::More 0.98;
use utf8;

use Data::Dumper;
use open IO => ':utf8', ':std';
use Text::ANSI::Fold qw(ansi_fold);

sub folded {
    local $_ = shift;
    my($folded, $rest) = ansi_fold($_, @_);
    $folded;
}

sub color {
    my $code = { r => 31 , g => 32 , b => 34 }->{+shift};
    my @result;
    while (my($color, $plain) = splice @_, 0, 2) {
	push @result, "\e[${code}m" . $color . "\e[m";
	push @result, $plain if defined $plain;
    }
    join '', @result;
}

sub r { color 'r', @_ }
sub g { color 'g', @_ }
sub b { color 'b', @_ }

for my $ent (
    [ bold      => sub { $_[0] =~ s/(.)/$1\b$1/gr     } ],
    [ bold3     => sub { $_[0] =~ s/(.)/$1\b$1\b$1/gr } ],
    [ underline => sub { $_[0] =~ s/(.)/_\b$1/gr      } ],
    [ bold_ul   => sub { $_[0] =~ s/(.)/_\b$1\b$1/gr  } ],
    )
{
    my($msg, $sub) = @$ent;
    $_ = "12345678901234567890123456789012345678901234567890";
    my $len = length;
    $_ = $sub->($_);
    is(folded($_, 1),        $sub->("1"),          "$msg: 1");
    is(folded($_, 10),       $sub->("1234567890"), "$msg: 10");
    is(folded($_, $len),     $_,                   "$msg: just");
    is(folded($_, $len * 2), $_,                   "$msg: long");
    is(folded($_, -1),       $_,                   "$msg: negative");
}

is(folded("\b", -1), "\b", "backspace only (1)");
is(folded("\b"x10, -1), "\b"x10, "backspace only (10)");

$_ = "漢\b漢字\b字";
is(folded($_, 1), "漢\b漢", "wide char with single bs 1");
is(folded($_, 2), "漢\b漢", "wide char with single bs 2");
is(folded($_, 3), "漢\b漢", "wide char with single bs 3");
is(folded($_, 4), "漢\b漢字\b字", "wide char with single bs 4");

$_ = "漢\b\b漢字\b\b字";
is(folded($_, 1), "漢\b\b漢", "wide char with double bs 1");
is(folded($_, 2), "漢\b\b漢", "wide char with double bs 2");
is(folded($_, 3), "漢\b\b漢", "wide char with double bs 3");
is(folded($_, 4), "漢\b\b漢字\b\b字", "wide char with double bs 4");

$_ = "漢\b\b\b漢字\b\b\b字";
is(folded($_, 1), "漢\b\b\b漢", "wide char with triple bs 1");
is(folded($_, 2), "漢\b\b\b漢", "wide char with triple bs 2");
is(folded($_, 3), "漢\b\b\b漢", "wide char with triple bs 3");
is(folded($_, 4), "漢\b\b\b漢字\b\b\b字", "wide char with triple bs 4");

$_ = "漢\b漢字\b";
is(folded($_, 1), "漢\b漢", "broken wide char with single bs 1");
is(folded($_, 2), "漢\b漢", "broken wide char with single bs 2");
is(folded($_, 3), "漢\b漢字\b", "broken wide char with single bs 3");
is(folded($_, 4), "漢\b漢字\b", "broken wide char with single bs 4");

sub bd { $_[0] =~ s/(\w)/$1\cH$1/gr }
sub ul { $_[0] =~ s/(\w)/_\cH$1/gr }
for my $f (\&bd, \&ul) {
    state $n;
    $_ = &$f("123 456 789");
    is(folded($_, 5, boundary => 'word'), &$f("123 "),    "word boundary " . ++$n);
    is(folded($_, 6, boundary => 'word'), &$f("123 "),    "word boundary " . ++$n);
    is(folded($_, 7, boundary => 'word'), &$f("123 456"), "word boundary " . ++$n);
}

$_ = r("漢\b漢字\b字");
is(folded($_, 1), r("漢\b漢"), "wide char with single bs 1");
is(folded($_, 2), r("漢\b漢"), "wide char with single bs 2");
is(folded($_, 3), r("漢\b漢"), "wide char with single bs 3");
is(folded($_, 4), r("漢\b漢字\b字"), "wide char with single bs 4");

{
    $_ = r("漢\b漢").g("字\b字");
    is(folded($_, 1), r("漢\b漢"), "wide char with single bs 1");
    is(folded($_, 2), r("漢\b漢"), "wide char with single bs 2");
  {
    local $TODO = "leave extra ANSI sequence";
    is(folded($_, 3), r("漢\b漢"), "wide char with single bs 3");
  }
    is(folded($_, 4), r("漢\b漢").g("字\b字"), "wide char with single bs 4");
}

done_testing;
