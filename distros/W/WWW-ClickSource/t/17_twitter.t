use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://twitter.com',
        'params' => {},
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'twitter',
          'category' => 'referer',
          'campaign' => '',
          'medium' => 'social',
        },'Twitter, no URL params');      
}

done_testing();