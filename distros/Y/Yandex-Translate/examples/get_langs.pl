use strict;
use utf8;
use Yandex::Translate;

my $tr =  Yandex::Translate->new;

my $key = 'yandex_key'; 

$tr->set_key($key);

print print join(',', $tr->get_langs_list()), "\n";

