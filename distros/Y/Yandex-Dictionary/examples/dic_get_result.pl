use Yandex::Dictionary;
use utf8;

my $dic = Yandex::Dictionary->new;
$dic->set_key('yandex_key');

$dic->set_text('time');

$dic->set_lang('en-tr');

#$dic->set_format('xml');

print $dic->get_result(), "\n";
