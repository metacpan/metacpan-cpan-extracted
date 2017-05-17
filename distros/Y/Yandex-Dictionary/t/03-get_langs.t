use strict;
use warnings;

use Test::More;

unless ($ENV{YANDEX_API_KEY}) {
    plan skip_all => 'test requires a Yandex API key in the YANDEX_API_KEY environment variable';
}
else {
    plan tests => 2;
}

use Yandex::Dictionary;

my $dic = Yandex::Dictionary->new;
$dic->set_key($ENV{YANDEX_API_KEY});
my $lang_json_string;
eval { $lang_json_string = $dic->get_langs_list(); };
is($@, '', 'get_langs_list() returned json string');
ok(defined $lang_json_string, 'match string json');

