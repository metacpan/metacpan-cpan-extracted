use strict;
use Yandex::Translate;

my $tr =  Yandex::Translate->new;

my $key = 'yandex_key';

$tr->set_key($key);

# We set here four langs, if we do not run this method It will use 
# all validate langs that yandex has , It is good sometimes but 
# I do not like it because It does not detect the right lan sometimes, 
# but do not follow my idea and try to be 'Diligent' (James Axl).

$tr->set_hint([qw{en ru ar tr});

$tr->set_text('Hello');
print $tr->detect_lang(), "\n";

$tr->set_text('Здравствуйте');
print $tr->detect_lang(), "\n";

$tr->set_text('السلام عليكم');
print $tr->detect_lang(), "\n";
