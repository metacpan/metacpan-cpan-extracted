use strict;
use warnings;
use utf8;

use Test::More tests => 2;

use Yandex::Translate;

my $translator = Yandex::Translate->new();
$translator->set_ui('ru');
my $html_element = $translator->get_yandex_technology_reference();
is($html_element, '<a href="http://translate.yandex.ru/">Переведено сервисом Яндекс.Переводчик</a>', 'correct Yandex technology reference in Russian');
$translator->set_ui('en');
$html_element = $translator->get_yandex_technology_reference();
is($html_element, '<a href="http://translate.yandex.com/">Powered by Yandex.Translate</a>', 'correct Yandex technology reference in English');
$translator->set_ui('tr');
$html_element = $translator->get_yandex_technology_reference();
is($html_element, '<a href="http://translate.yandex.com.tr/">Tarafından desteklenmektedir Yandex.Translate</a>', 'correct Yandex technology reference in Turkish');

