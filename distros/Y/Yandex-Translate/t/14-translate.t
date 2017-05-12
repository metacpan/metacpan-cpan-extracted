use strict;
use warnings;
use utf8;

use Test::More;

unless ($ENV{YANDEX_API_KEY}) {
    plan skip_all => 'test requires a Yandex API key in the YANDEX_API_KEY environment variable';
}
else {
    plan tests => 22;
}

use Yandex::Translate;

my $translator = Yandex::Translate->new();
$translator->set_key($ENV{YANDEX_API_KEY});
$translator->set_text('Моё судно на воздушной подушке полно угрей.');
$translator->set_to_lang('en');

# Plain text: guess the “from” language. (3 tests)
my ($lang, @lang);
eval { $lang = $translator->translate(); };
is($@, '', 'plain: $lang: translate() returned scalar');
eval { @lang = $translator->translate(); };
is($@, '', 'plain: @lang: translate() returned array');
is($lang[0], $lang, 'scalar matches first element of array');

# Plain text: also return the guessed “from” language. (3 tests)
my @option_lang;
$translator->set_options('1');
eval { @option_lang = $translator->translate(); };
is($@, '', 'plain: @option_lang: translate() returned array');
is($option_lang[0], 'ru', 'plain: language correctly guessed');
is($option_lang[1], $lang, 'plain: text correctly translated');

# Plain text: specify the “from” language. (4 tests)
my ($with_from_lang, @with_from_lang);
$translator->set_options();
$translator->set_from_lang('ru');
eval { $with_from_lang = $translator->translate(); };
is($@, '', 'plain: $with_from_lang: translate() returned scalar');
eval { @with_from_lang = $translator->translate(); };
is($@, '', 'plain: @with_from_lang: translate() returned array');
is($with_from_lang, $lang, 'plain: scalar matches guessed scalar');
is($with_from_lang[0], $lang[0], 'plain: first element of array matches first element of guessed array');

# HTML text: guess the “from” language. (5 tests)
$translator->set_text('<span id="absurdity">My hovercraft is full of eels.</span>');
$translator->set_from_lang();
$translator->set_to_lang('ru');
$translator->set_format('html');
eval { $lang = $translator->translate(); };
is($@, '', 'html: $lang: translate() returned scalar');
ok($lang =~ m|^<span id="absurdity">.*</span>$|, 'html: $lang: HTML remains untranslated');
eval { @lang = $translator->translate(); };
is($@, '', 'html: @lang: translate() returned array');
ok($lang[0] =~ m|^<span id="absurdity">.*</span>$|, 'html: @lang: HTML remains untranslated');
is($lang[0], $lang, 'html: scalar matches first element of array');

# HTML text: also return the guessed “from” language. (3 tests)
$translator->set_options('1');
eval { @option_lang = $translator->translate(); };
is($@, '', 'html: @option_lang: translate() returned array');
is($option_lang[0], 'en', 'html: language correctly guessed');
is($option_lang[1], $lang, 'html: text correctly translated');

# HTML text: specify the “from” language. (4 tests)
$translator->set_options();
$translator->set_from_lang('en');
eval { $with_from_lang = $translator->translate(); };
is($@, '', 'html: $with_from_lang: translate() returned scalar');
eval { @with_from_lang = $translator->translate(); };
is($@, '', 'html: @with_from_lang: translate() returned array');
is($with_from_lang, $lang, 'html: scalar matches guessed scalar');
is($with_from_lang[0], $lang[0], 'html: first element of array matches first element of guessed array');

