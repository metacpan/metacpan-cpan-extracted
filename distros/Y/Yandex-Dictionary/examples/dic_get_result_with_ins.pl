use Yandex::Dictionary;
use utf8;

my $key = 'yandex_key';

my $dic = Yandex::Dictionary->new($key, 'time', 'en-ru', 'en', 'json');
# OR $dic = Yandex::Dictionary->new($key, 'time', 'en-ru', 'en', 'xml'); for xml output.
print $dic->get_result(), "\n";

