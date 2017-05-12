use strict;
use warnings;

use Test::More;

eval "use JSON 2.0;";
plan skip_all => 'JSON 2.0 required for this test!' if $@;

plan tests => 2;

use Validator::Custom;

my $rule;
my $vc;
my $js;


# js_fill_form_button;
$rule = {
    name1 => 'ab',
    name2 => 'c{3}'
};
$vc = Validator::Custom->new;
$js = $vc->js_fill_form_button($rule);
like($js, qr/name1/);
like($js, qr/name2/);

# For JavaScript Test
if ($ENV{PERL5_VALIDATOR_CUSTOM_TEST}) {
    $vc = Validator::Custom->new;
    $rule = {
        "text1" => '[ab]{2}',
        "text2" => '[ab]{2}',
        "textarea1" => '[ab]{2}',
        "textarea2" => '[ab]{2}',
        "hidden1" => '[ab]{2}',
        "hidden2" => '[ab]{2}',
        "password1" => '[ab]{2}',
        "password2" => '[ab]{2}'
    };
    $js = $vc->js_fill_form_button($rule);
    
    use FindBin;
    open my $fh, '>', "$FindBin::Bin/js_fill_form_button_test.tmp"
      or die $!;
    print $fh $js;
}
