use strict;
use Yandex::Translate;

my $tr =  Yandex::Translate->new;

my $key = 'trnsl.1.1.20170502T185327Z.003373b7b88cddda.5420c79cd704be7b9538b3e7d9ea9e7db457a4e7';

$tr->set_key($key);

print print join(',', $tr->get_langs_list()), "\n";

