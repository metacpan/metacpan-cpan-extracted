use strict;

use utf8;

use Test::More qw(no_plan);
use Test::Exception;

use Unicode::Truncate;


## basic

is(truncate_egc('hello world', 7), 'hell…');
is(truncate_egc('hello world', 7, '...'), 'hell...');
is(truncate_egc('hello world', 7, ''), 'hello w');

is(truncate_egc('hello world', 10), 'hello w…');
is(truncate_egc('hello world', 11), 'hello world');
is(truncate_egc('hello world', 12), 'hello world');

is(truncate_egc('深圳', 5), '…');
is(truncate_egc('深圳', 6), '深圳');
is(truncate_egc('深圳', 7), '深圳');
is(truncate_egc('深圳', 8), '深圳');
is(truncate_egc('深圳', 9), '深圳');

is(truncate_egc('深圳', 4, '..'), '..');
is(truncate_egc('深圳', 5, '..'), '深..');
is(truncate_egc('深圳', 6, '..'), '深圳');

is(truncate_egc('深圳', 0, ''), '');
is(truncate_egc('深圳', 1, ''), '');
is(truncate_egc('深圳', 2, ''), '');
is(truncate_egc('深圳', 3, ''), '深');
is(truncate_egc('深圳', 4, ''), '深');
is(truncate_egc('深圳', 5, ''), '深');
is(truncate_egc('深圳', 6, ''), '深圳');
is(truncate_egc('深圳', 7, ''), '深圳');

is(truncate_egc('До свидания', 14, ''), 'До свид');
is(truncate_egc('До свидания', 15, ''), 'До свида');
is(truncate_egc('До свидания', 16, ''), 'До свида');
is(truncate_egc('До свидания', 17, ''), 'До свидан');

## input encoding

is(truncate_egc("\xe6\xb7\xb1\xe5\x9c\xb3", 5, '..'), '深..', "input doesn't need to be decoded");

throws_ok { truncate_egc("\xFF", 100) } qr/not valid UTF-8 .*detected at byte offset 0\b/;
throws_ok { truncate_egc("cbs\xCE\x80dd\xFFasdff", 100) } qr/not valid UTF-8 .*detected at byte offset 7\b/;

## malformed error reporting

throws_ok { truncate_egc() } qr/Usage:/, "needs input arg";
throws_ok { truncate_egc("blah") } qr/Usage:/, "needs trunc_size arg";
throws_ok { truncate_egc("blah", -1) } qr/must be >= 0/, "trunc_size can't be negative";
throws_ok { truncate_egc(undef, -1) } qr/need to pass a string/, "input must be string";

throws_ok { truncate_egc("blah", 3, undef) } qr/ellipsis must be a string/;
throws_ok { truncate_egc("blah", 3, "\xff") } qr/ellipsis must be utf-8 encoded/;

throws_ok { truncate_egc("blah", 3, "...", 1) } qr/too many items passed/;

throws_ok { truncate_egc("blah", 0) } qr/length of ellipsis is longer than truncation length/;
throws_ok { truncate_egc("blah", 1) } qr/length of ellipsis is longer than truncation length/;
throws_ok { truncate_egc("blah", 2) } qr/length of ellipsis is longer than truncation length/;
lives_ok { truncate_egc("blah", 3) };

## overlong encodings

throws_ok { truncate_egc("\xC0\x80", 10) } qr/not valid UTF-8/;
throws_ok { truncate_egc("\xC0\xa0", 10) } qr/not valid UTF-8/;
throws_ok { truncate_egc("\xF0\x82\x82\xAC", 10) } qr/not valid UTF-8/;

## combining characters

is(truncate_egc("ne\x{301}e", 0, ''), '');
is(truncate_egc("ne\x{301}e", 1, ''), 'n');
is(truncate_egc("ne\x{301}e", 2, ''), 'n');
is(truncate_egc("ne\x{301}e", 3, ''), 'n');
is(truncate_egc("ne\x{301}e", 4, ''), 'né');
is(truncate_egc("ne\x{301}e", 5, ''), 'née');

is(truncate_egc("ne\x{301}\x{1DD9}\x{FE26}e", 2, ''), 'n');
is(truncate_egc("ne\x{301}\x{1DD9}\x{FE26}e", 8, ''), "n");
is(truncate_egc("ne\x{301}\x{1DD9}\x{FE26}e", 9, ''), "n");
is(truncate_egc("ne\x{301}\x{1DD9}\x{FE26}e", 10, ''), "ne\x{301}\x{1DD9}\x{FE26}");
is(truncate_egc("ne\x{301}\x{1DD9}\x{FE26}e", 11, ''), "ne\x{301}\x{1DD9}\x{FE26}e");
is(truncate_egc("ne\x{301}\x{1DD9}\x{FE26}e", 12, ''), "ne\x{301}\x{1DD9}\x{FE26}e");

is(truncate_egc("e\x{302}", 3, ''), "e\x{302}");
is(truncate_egc("e\x{302}", 2, ''), "");

is(truncate_egc(" \x{308} ", 0, ''), "");
is(truncate_egc(" \x{308} ", 1, ''), "");
is(truncate_egc(" \x{308} ", 2, ''), "");
is(truncate_egc(" \x{308} ", 3, ''), " \x{308}");
is(truncate_egc(" \x{308} ", 4, ''), " \x{308} ");
