use Yandex::Dictionary;
use utf8;
use Data::Dumper;

my $dic = Yandex::Dictionary->new;
$dic->set_key('yandex_key');

$dic->set_text('time');

$dic->set_lang('en-tr');

my @result = $dic->get_result_syn;

print Dumper \@result , "\n";

