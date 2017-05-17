use strict;
use warnings;

use Test::More;

unless ($ENV{YANDEX_API_KEY}) {
    plan skip_all => 'test requires a Yandex API key in the YANDEX_API_KEY environment variable';
}
else {
    plan tests => 2;
};

use Yandex::Dictionary;

my $dic = Yandex::Dictionary->new();
$dic->set_key($ENV{YANDEX_API_KEY});
$dic->set_text('time');
$dic->set_lang('en-ru');
my @result;
eval { @result = $dic->get_result_mean(); };
is($@, '', 'get_result_mean() returned array');
ok(ref(\@result) eq 'ARRAY', 'count matches array elements');

