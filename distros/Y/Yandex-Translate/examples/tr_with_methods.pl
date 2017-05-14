use strict;
use utf8;
use Yandex::Translate;

my $tr = Yandex::Translate->new;

my $key = 'yandex_key';
$tr->set_key($key);

# For more info please check set_default_ui in doc.
$tr->set_default_ui('en');
$tr->set_from_lang('en');
$tr->set_to_lang('ru');
$tr->set_text('Hello Yandex');

print $tr->translate(), "\n";

