use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://partner-site.com/de-vanzare/garsoniere/Bucuresti/13_Septembrie/Strada_Dorneasca',
        'params' => {
                     'utm_source' => 'partner-site.com',
                     'utm_campaign' => 'partnersite',
                     'utm_medium' => 'cpc'
                   },
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'partner-site.com',
          'campaign' => 'partnersite',
          'medium' => 'cpc',
          'category' => 'paid'
        },'Paid traffic (source other than regular advertisers)');
}


{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'https://www.facebook.com/',
        'params' => {
                     'utm_source' => 'partner-site.com',
                     'utm_campaign' => 'partnersite',
                     'utm_medium' => 'cpc'
                    },
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'partner-site.com',
          'campaign' => 'partnersite',
          'medium' => 'cpc',
          'category' => 'paid'
        },'Paid traffic (source other than regular advertisers trough facebook)');
}

done_testing();
