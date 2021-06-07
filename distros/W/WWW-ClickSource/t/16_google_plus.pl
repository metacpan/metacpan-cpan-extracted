use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'https://plus.google.com',
        'params' => {},
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'google plus',
          'category' => 'referer',
          'campaign' => '',
          'medium' => 'social',
        },'Google Plus, no URL params');      
}

done_testing();