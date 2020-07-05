use strict;
use utf8;
use warnings;

use Test::Deep;
use Test::More;
use URI;
use URI::QueryParam;
use WebDriver::Tiny;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw/failure_output output/;

# Perl 6 envy :-(
sub pick { map { splice @_, rand @_, 1 } 1 .. shift }
sub roll { map { $_[ rand @_ ]         } 1 .. shift }

my $drv = WebDriver::Tiny->new(
    capabilities => { 'moz:firefoxOptions' => { args => ['-headless'] } },
    host         => 'geckodriver',
    port         => 4444,
);

$drv->get('http://httpd');

is_deeply [ map $_->attr('name'), $drv->('form')->find('input,select') ], [
    'text', "text '", 'text "', 'text \\', 'text ☃',
    ('radio') x 3, 'select', 'multi select',
], 'names of all form fields are correct';

#my %expected;

#for ('text', 'text ☃') {
#    $drv->(qq/[name="$_"]/)->send_keys( $expected{$_} = join '', roll( 3, 'a'..'z' ) );

    #utf8::encode $expected{$_};
#}

#cmp_deeply +URI->new( $drv->url )->query_form_hash, \%expected,
#    'submit works on all form fields correctly';

my $elem = $drv->('input[type=text]');

$elem->send_keys('♥ ♦ ♣ ♠');

is $elem->prop('value'), '♥ ♦ ♣ ♠', 'elem->send_keys("♥ ♦ ♣ ♠")';

$elem->clear;

is $elem->prop('value'), '', 'elem->clear';

$elem->send_keys(1);

is $elem->prop('value'), 1, 'elem->send_keys(1)';

ok $drv->('#enabled')->enabled, 'enabled';
ok !$drv->('#disabled')->enabled, 'not enabled';

done_testing;
