use strict;
use warnings;

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
my ($lang_count, @lang);
eval { $lang_count = $translator->get_langs_list(); };
is($@, '', 'get_langs_list() returned scalar');
eval { @lang = $translator->get_langs_list(); };
is($@, '', 'get_langs_list() returned array');
ok($lang_count == scalar(@lang), 'count matches array elements');

