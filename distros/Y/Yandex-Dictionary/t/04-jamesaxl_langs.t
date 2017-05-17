use strict;
use warnings;

use Test::More;

unless ($ENV{YANDEX_API_KEY}) {
    plan skip_all => 'test requires a Yandex API key in the YANDEX_API_KEY environment variable';
}
else {
    plan tests => 3;
}

use Yandex::Dictionary;

my $dic = Yandex::Dictionary->new();
$dic->set_key($ENV{YANDEX_API_KEY});
$dic->set_text('time');
$dic->set_lang('en-ru');
my ($lang_count, @lang);
eval { $lang_count = $dic->james_axl_langs_list(); };
is($@, '', 'james_axl_langs_list() returned scalar');
eval { @lang = $dic->james_axl_langs_list(); };
is($@, '', 'james_axl_langs_list() returned array');
ok($lang_count == scalar(@lang), 'count matches array elements');

