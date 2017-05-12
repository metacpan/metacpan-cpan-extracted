use strict;
use warnings;
use utf8;
use Test::More;
use Text::Sprintf::Zenkaku qw(sprintf);
use Test::Trap;
use Test::Exception;

use Term::Encoding qw(term_encoding);
eval {
    my $encoding = term_encoding;
    binmode STDOUT => "encoding($encoding)";
    binmode STDERR => "encoding($encoding)";
};

subtest "normal" => sub {
    is sprintf(), "";
    is sprintf("hello"), "hello";
    is sprintf("hello %s", "world"), "hello world";
};

subtest "format %s" => sub {
    is sprintf("[%s]",   "hello"), "[hello]";
    is sprintf("[%6s]",  "hello"), "[ hello]";
    is sprintf("[%-6s]", "hello"), "[hello ]";
};

subtest "format %s with zenkaku" => sub {
    is sprintf("[%s]",   "A"), "[A]";
    is sprintf("[%6s]",  "A"), "[     A]";
    is sprintf("[%-6s]", "A"), "[A     ]";

    is sprintf("[%s]",   "あ"), "[あ]";
    is sprintf("[%6s]",  "あ"), "[    あ]";
    is sprintf("[%-6s]", "あ"), "[あ    ]";
};

subtest "format %s with zenkaku 2" => sub {
    is sprintf("[%-12s]", "hello 世界."), "[hello 世界. ]";
    is sprintf("[%-11s]", "hello 世界."), "[hello 世界.]";
    is sprintf("[%-10s]", "hello 世界."), "[hello 世界.]";

    is sprintf("[%12s]", "hello 世界."), "[ hello 世界.]";
    is sprintf("[%11s]", "hello 世界."), "[hello 世界.]";
    is sprintf("[%10s]", "hello 世界."), "[hello 世界.]";

    is sprintf("[%-20s][%1s][%-1s]", "hello 世界.", "あ", "い"), "[hello 世界.         ][あ][い]";
};

subtest "sprintf with no parentheses" => sub {
    is + (sprintf "[%-12s]", "hello 世界."), "[hello 世界. ]";
    is + (sprintf "[%-11s]", "hello 世界."), "[hello 世界.]";
    is + (sprintf "[%-10s]", "hello 世界."), "[hello 世界.]";

    is + (sprintf "[%12s]", "hello 世界."), "[ hello 世界.]";
    is + (sprintf "[%11s]", "hello 世界."), "[hello 世界.]";
    is + (sprintf "[%10s]", "hello 世界."), "[hello 世界.]";

    is + (sprintf "[%-20s][%1s][%-1s]", "hello 世界.", "あ", "い"), "[hello 世界.         ][あ][い]";
};

subtest "sprintf with no parentheses" => sub {
    is + (sprintf), "";
    is + (sprintf "[%-12s]", "hello 世界."), "[hello 世界. ]";
    is + (sprintf "[%-11s]", "hello 世界."), "[hello 世界.]";
    is + (sprintf "[%-10s]", "hello 世界."), "[hello 世界.]";

    is + (sprintf "[%12s]", "hello 世界."), "[ hello 世界.]";
    is + (sprintf "[%11s]", "hello 世界."), "[hello 世界.]";
    is + (sprintf "[%10s]", "hello 世界."), "[hello 世界.]";

    is + (sprintf "[%-20s][%1s][%-1s]", "hello 世界.", "あ", "い"), "[hello 世界.         ][あ][い]";
};

subtest "sprintf %%" => sub {
    is sprintf("%%%%%s%%", "あ"), "%%あ%";
};

subtest "sprintf %c" => sub {
    is sprintf("%c%3s%c", ord('A'), "あ", ord('B')), "A あB";
};

subtest "sprintf %d" => sub {
    is sprintf("%d%3s%d", ord('A'), "あ", ord('B')), "65 あ66";
};

subtest "sprintf %u" => sub {
    is sprintf("%u%3s%u", ord('A'), "あ", ord('B')), "65 あ66";
};

subtest "sprintf %o" => sub {
    is sprintf("%o%3s%o", ord('A'), "あ", ord('B')), "101 あ102";
};

subtest "sprintf %x" => sub {
    is sprintf("%x%3s%x", ord('A'), "あ", ord('B')), "41 あ42";
};

subtest "sprintf %e" => sub {
    is sprintf("%e%3s%e", ord('A'), "あ", ord('B')), CORE::sprintf("%e%2s%e", ord('A'), "あ", ord('B'));
};

subtest "sprintf %f" => sub {
    is sprintf("%f%3s%f", ord('A'), "あ", ord('B')), "65.000000 あ66.000000";
};

subtest "sprintf %g" => sub {
    is sprintf("%g%3s%g", ord('A'), "あ", 6.6e-9), CORE::sprintf("%g%2s%g", ord('A'), "あ", 6.6e-9);
};

subtest "sprintf %X" => sub {
    is sprintf("%X%3s%X", ord('A'), "あ", 0xFF), "41 あFF";
};

subtest "sprintf %E" => sub {
    is sprintf("%E%3s%E", ord('A'), "あ", ord('B')), CORE::sprintf("%E%2s%E", ord('A'), "あ", ord('B'));
};

subtest "sprintf %G" => sub {
    is sprintf("%G%3s%G", ord('A'), "あ", 6.6e-9), CORE::sprintf("%G%2s%G", ord('A'), "あ", 6.6e-9);
};

subtest "sprintf %b" => sub {
    is sprintf("%b%3s%b", ord('A'), "あ", ord('B')), "1000001 あ1000010";
};

subtest "sprintf %B" => sub {
    plan skip_all => 'perl < 5.010000' if $] < 5.010000;
    is sprintf("%B%3s%B", ord('A'), "あ", ord('B')), "1000001 あ1000010";
};

subtest "sprintf %p" => sub {
    my $x = ord('A');
    my $y = ord('B');
    like sprintf("%p%3s%p", \$x, "あ", \$y), qr/^[0-9a-f]{4,} あ[0-9a-f]{4,}$/;
};

subtest "sprintf %n" => sub {
    ok 1;
};

subtest "sprintf %a" => sub {
    plan skip_all => 'perl < 5.022000' if $] < 5.022000;
    is sprintf("%a%3s%a", ord('A'), "あ", ord('B')), CORE::sprintf("%a%2s%a", ord('A'), "あ", ord('B'));
};

subtest "sprintf %A" => sub {
    plan skip_all => 'perl < 5.022000' if $] < 5.022000;
    is sprintf("%A%3s%A", ord('A'), "あ", ord('B')), CORE::sprintf("%A%2s%A", ord('A'), "あ", ord('B'));
};

subtest "space" => sub {
    is sprintf("% d%3s% d", 1, "あ", -1), " 1 あ-1";
};

subtest "plus '+'" => sub {
    is sprintf("%+d%3s%+d", 1, "あ", -1), "+1 あ-1";
};

subtest "minus '-'" => sub {
    is sprintf("%-2s%3s%-2s", 1, "あ", -1), "1  あ-1";
};

subtest "zero '0'" => sub {
    is sprintf("%02d%3s%02d", 1, "あ", -1), "01 あ-1";
};

subtest "sharp '#'" => sub {
    is sprintf("%#o%3s%#o", 12, "あ", 12), "014 あ014";
    is sprintf("%#x%3s%#x", 12, "あ", 12), "0xc あ0xc";
    is sprintf("%#X%3s%#X", 12, "あ", 12), "0XC あ0XC";
    is sprintf("%#b%3s%#b", 12, "あ", 12), "0b1100 あ0b1100";
};

subtest "sharp '#' with %B" => sub {
    plan skip_all => 'perl < 5.010000' if $] < 5.010000;
    is sprintf("%#B%3s%#B", 12, "あ", 12), "0B1100 あ0B1100";
};

subtest "plus '+' and space ' '" => sub {
    is sprintf("%+ d%3s% +d", 12, "あ", 12), CORE::sprintf("%+ d%2s% +d", 12, "あ", 12);
};

subtest "sharp '#' and precision" => sub {
    is sprintf("%#.5o%3s", 012, "あ"), "00012 あ";
    is sprintf("%#.5o%3s", 012345, "あ"), "012345 あ";
    is sprintf("%#.0o%3s", 0, "あ"), CORE::sprintf("%#.0o%2s", 0, "あ");
};

subtest "vector flag" => sub {
    is sprintf("%vd%3s", "AB\x{100}", "あ"), "65.66.256 あ";

    is sprintf('%*vd%3s', ':', '1234', 'あ'), '49:50:51:52 あ';
    is sprintf('%*vd%3s', ' ', '1234', 'あ'), '49 50 51 52 あ';
    is sprintf('%*4$vd %*4$vd %*4$vd %3s %3s', '12', '23', '34', ':', 'あ'), '49:50 50:51 51:52   :  あ';
};

subtest "(minimum) width" => sub {
    is sprintf('%s%3s', 'a', 'あ'), 'a あ';
    is sprintf('%6s%3s', 'a', 'あ'), '     a あ';
    is sprintf('%*s%3s', 6, 'a', 'あ'), '     a あ';
    is sprintf('%*2$s%3s%3s', 'a', 6, 'あ'), '     a  6 あ';
    is sprintf('%2s%3s', 'long', 'あ'), 'long あ';
    is sprintf('%*2$s%3$3s', 'a', 6, 'あ'), '     a あ';

    is sprintf('%s%3s', 'a', 'あ'), 'a あ';
    is sprintf('%6s%3s', 'a', 'あ'), '     a あ';
    is sprintf('%*s%3s', -6, 'a', 'あ'), 'a      あ';
    is sprintf('%*2$s%3s%3s', 'a', -6, 'あ'), 'a      -6 あ';
    is sprintf('%2s%3s', 'long', 'あ'), 'long あ';
    is sprintf('%*2$s%3$3s', 'a', -6, 'あ'), 'a      あ';
};

subtest "end with '%'" => sub {
    trap {is sprintf('%3s%', 'あ'), ' あ%'};
    is $trap->stdout, "";
    like $trap->stderr, qr/Invalid conversion in sprintf/;
};

subtest "complex pattern" => sub {
    is sprintf('%*3$s%*4$s', 'あ', 'い', 3, 4), ' あ  い';
    is sprintf('[%2$*1$s]', 3, 'あ'), '[ あ]';
    is sprintf('[%2$   *1$s]', -3, 'あ'), '[あ ]';

    is sprintf('[%2$*s]', -3, 'あ'), '[あ ]';
};

subtest "not supported" => sub {
    throws_ok {sprintf('%z', "a")} qr/not supported :/;
};

subtest "'% s' and '%  s'" => sub {
    is sprintf('[% s][% 3s]', 'あ', 'い'), '[あ][ い]';
};

done_testing;

