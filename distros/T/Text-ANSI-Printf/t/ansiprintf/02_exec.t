use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Test::More;
use Data::Dumper;

use lib '.';
use t::ansiprintf::Util;

use Term::ANSIColor::Concise qw(ansi_color ansi_code);

sub test {
    my $answer = pop @_;
    my $comment = join(' ', map { / / ? "'$_'" : $_ } @_);
    is(ansiprintf(@_)->{stdout},
       $answer,
       $comment);
}

for my $fg ('RGBCMYKW' =~ /./g) {
    no strict 'refs';
    *{$fg} = sub { ansi_color($fg, @_) };
    for my $bg ('RGBCMYKW' =~ /./g) {
	*{"${fg}on${bg}"} = sub { ansi_color("${fg}/${bg}", @_) };
    }
}

test qw(a), "a";
test qw(a\n), "a\n";
test qw(%s a), "a";
test qw(%s\n a), "a\n";
test qw(%s%s a b), "ab";

test '%s', R('Red') => R('Red');
test '%s%s', R('Red'), G('Green') => R('Red').G('Green');
test '%-5s%-5s', R('Red'), G('Green') => R('Red').'  '.G('Green');

test '%2$-*3$s%1$-*4$s', R('Red'), G('Green'), '5', '6', => G('Green').R('Red').'   ';

done_testing;
