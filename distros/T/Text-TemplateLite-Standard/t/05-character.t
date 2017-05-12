#!perl -T

use Test::More tests => 1;

use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;

Text::TemplateLite::Standard::register($tpl, qw/:character/);

$tpl->set(q{<<cr gg ht lf ll nl sp>>});
is($tpl->render->result, "\r>>\t\n<<\n ", 'char const functions');
