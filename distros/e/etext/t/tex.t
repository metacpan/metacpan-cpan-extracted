#!/usr/bin/perl
# The TeX symbol tables of the bundled Text::TeX: Unicode characters,
# consistent with their reverse maps.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../utils";
use Test::More tests => 12;
no warnings qw(once);

binmode(Test::More->builder->$_, ':utf8') for qw(output failure_output);

require_ok('Text::TeX');

my %xfont = %Text::TeX::xfont;
cmp_ok(scalar(keys %xfont), '>', 400, 'the table has the TeX symbols');
my @bad = grep { !ref $xfont{$_} || @{$xfont{$_}} != 2 || length($xfont{$_}[1]) != 1 } keys %xfont;
is("@bad", '', 'every entry is [font, one character]');
@bad = grep { ord($xfont{$_}[1]) < 0x80 } keys %xfont;
is("@bad", '', 'no entry is an 8-bit font code any more');
@bad = grep { $xfont{$_}[0] !~ /^(symbol|cmsy|cmex|msam|msbm)$/ } keys %xfont;
is("@bad", '', 'font names are the historical ones');

my %expect = ('\alpha' => "\x{3b1}", '\Omega' => "\x{3a9}", '\leq' => "\x{2264}",
	      '\le' => "\x{2264}", '\int' => "\x{222b}", '\sum' => "\x{2211}",
	      '\Rightarrow' => "\x{21d2}", '\langle' => "\x{27e8}", '\<' => "\x{27e8}",
	      '\pm' => "\x{b1}", '\otimes' => "\x{2297}", '\nleq' => "\x{2270}",
	      '\upsilon' => "\x{3c5}", '\emptyset' => "\x{2205}", '\hbar' => "\x{210f}");
my @wrong = grep { $xfont{$_}[1] ne $expect{$_} } keys %expect;
is("@wrong", '', 'a sample of symbols has the expected characters');

# Reverse maps.
ok(%Text::TeX::char2tex, 'per-font reverse map exists');
my $incons = 0;
for my $cs (keys %xfont) {
  my ($font, $char) = @{$xfont{$cs}};
  my $back = $Text::TeX::char2tex{$font}{$char};
  $incons++ unless defined $back && exists $xfont{$back}
    && $xfont{$back}[1] eq $char;
}
is($incons, 0, 'every symbol maps back to a control sequence giving the same character');
is($Text::TeX::char2tex{symbol}{"\x{3c9}"}, '\omega', 'omega maps back to \omega');
is($Text::TeX::char2tex{cmsy}{"\x{2264}"}, '\leq', 'the preferred name is the common one');
is($Text::TeX::tex_by_char{"\x{2211}"}, '\sum', 'font-independent reverse map');
is($Text::TeX::char2tex{msbm}{"\x{2268}"}, '\lneqq', 'canonical name preferred over its variants');
