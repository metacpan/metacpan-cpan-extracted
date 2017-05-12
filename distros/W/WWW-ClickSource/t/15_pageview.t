use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://mysite.com/some_page_on_my_site.html',
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'mysite.com',
          'campaign' => '',
          'medium' => '',
          'category' => 'pageview'
        },'internal page view');
}


{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://mysite.com/some_page_on_my_site.html',
        'params' => {
                     'utm_source' => 'mysite.com',
                     'utm_campaign' => 'promoted_listing',
                     'utm_medium' => 'internal_ads'
                   },
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'mysite.com',
          'campaign' => 'promoted_listing',
          'medium' => 'internal_ads',
          'category' => 'referer'
        },'Paid traffic from internal link');
}

done_testing();
