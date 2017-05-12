#!/usr/bin/env perl

use Test::More tests => 9
	+do { eval { require Test::NoWarnings;Test::NoWarnings->import; 1 } || 0 };
use uni::perl ':ru';

ok defined &cp1251::encode, 'have encode';
ok defined &cp1251::decode, 'have decode';

my $tr = koi8r::decode(cp1251::encode("это тест"));
is ($tr,"ЩРН РЕЯР", 'translate ok');

my $file = do {open my $f, "<", 't/data/file'; <$f> };
$tr = koi8r::decode(cp1251::encode($file));
is ($tr,"ЩРН РЕЯР", 'file open ok');

my $file = do {open my $f, "<:raw", 't/data/file'; <$f> };
ok !utf8::is_utf8($file), ':raw works';

ok defined &utf::encode, 'have utf::encode';
ok defined &utf::decode, 'have utf::decode';
my $x = utf::decode(utf::encode("тест"));

ok utf8::is_utf8($x), 'utf enc->dec ok (flag)';
is "тест", $x,        'utf enc->dec ok';
