use strict;
use Yandex::Translate;

my $tr = Yandex::Translate->new;

my $key = 'yandex_key';
$tr->set_key($key);

$tr->from_lang('en');
$tr->to_lang('ru');
$tr->set_text('Hello Yandex');

print $tr->translate(), "\n";

