use strict;
use warnings;
use utf8;

use Test::More;

unless ($ENV{YANDEX_API_KEY}) {
    plan skip_all => 'test requires a Yandex API key in the YANDEX_API_KEY environment variable';
}
else {
    plan tests => 3;
}

use Yandex::Translate;

my $translator = Yandex::Translate->new();
$translator->set_key($ENV{YANDEX_API_KEY});
$translator->set_text('Моё судно на воздушной подушке полно угрей.');
my ($lang, @lang);
eval { $lang = $translator->detect_lang(); };
is($@, '', 'detect_lang() returned scalar');
eval { @lang = $translator->detect_lang(); };
is($@, '', 'detect_lang() returned array');
is($lang, $lang[0], 'scalar matches first element of array');

