use strict;
use utf8;
use warnings;

use Test::Deep;
use Test::More;
use WebDriver::Tiny;

my $drv = WebDriver::Tiny->new(
    capabilities => { 'moz:firefoxOptions' => { args => ['-headless'] } },
    host         => 'geckodriver',
    port         => 4444,
);

$drv->get('http://httpd');

like $drv->window, qr/^[-\w]+$/, 'window';

cmp_deeply $drv->windows, [ re qr/^[-\w]+$/ ], 'windows';

like $drv->html, qr/^<html>/, 'html';

is $drv->('title')->html, '<title>Frosty the ☃</title>', 'html of <title>';

is $drv->('h1')->text, 'ᴛ̲ʜ̲ᴇ̲ʀ̲ᴇ̲ ̲ɪ̲s̲ ̲ɴ̲ᴏ̲ ̲U̲ɴ̲ɪ̲ᴄ̲ᴏ̲ᴅ̲ᴇ̲ ̲ᴍ̲ᴀ̲ɢ̲ɪ̲ᴄ̲ ̲ʙ̲ᴜ̲ʟ̲ʟ̲ᴇ̲ᴛ̲', 'text';

is $drv->('h3')->text, 'foo bar', 'text on more than one element';

is_deeply [ map $_->text, $drv->('h3') ], [qw/foo bar/],
    'find in list context';

is_deeply [ map $_->text, $drv->('h3')->split ], [qw/foo bar/], 'split';

is $drv->title, 'Frosty the ☃', 'title';

is $drv->url, 'http://httpd/', 'url';

( my $bottom = $drv->( 'go to bottom', method => 'link_text' ) )->click;

is $drv->url, 'http://httpd/#bottom', 'click';

( my $top = $drv->( 'go to top', method => 'link_text' ) )->click;

is $drv->url, 'http://httpd/#top', 'click';

is_deeply $drv->( 'to top', method => 'partial_link_text' ), $top,
    'partial_link_text matching one';

is_deeply [ $drv->( ' to ', method => 'partial_link_text' ) ],
    [ $bottom, $top ], 'partial_link_text matching two';

done_testing;
