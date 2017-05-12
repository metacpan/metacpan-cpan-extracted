use strict;
use Yandex::Translate;

my $key = 'yandex_key';

my @attrs = ($key, 'Hello Yandex', 'en', 'ru', 'en', [], 'plain', '1');

my $tr = Yandex::Translate->new(@attrs);

my @ar = $tr->translate();
print @ar[0] .' => '. @ar[1], "\n";

