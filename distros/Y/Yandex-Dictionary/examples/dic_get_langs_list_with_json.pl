use Yandex::Dictionary;
use utf8;

my $dic = Yandex::Dictionary->new;
$dic->set_key('yandex_key');

$dic->set_text('time');

$dic->set_lang('en-tr');

print join(',', $dic->james_axl_langs_list()), "\n";
print scalar($dic->james_axl_langs_list()), "\n";

