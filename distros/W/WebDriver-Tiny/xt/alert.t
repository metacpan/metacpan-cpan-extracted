use strict;
use warnings;

use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => { 'moz:firefoxOptions' => { args => ['-headless'] } },
    host         => 'geckodriver',
    port         => 4444,
);

$drv->get('http://httpd:8080');

$drv->( 'alert', method => 'link_text' )->click;

is $drv->alert_text, 'hi', 'alert_text';

$drv->alert_dismiss;

done_testing;
