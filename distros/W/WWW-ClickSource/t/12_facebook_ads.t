use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

{
    my %source = WWW::ClickSource::detect_click_source({
        'params' => {
                     'utm_source' => 'facebook.com',
                     'utm_campaign' => 'facebook_projects',
                     'utm_medium' => 'facebook_ads'
                   },
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'facebook.com',
          'campaign' => 'facebook_projects',
          'medium' => 'facebook_ads',
          'category' => 'paid'
        },'Paid facebook ads - without referer');      
}


{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://l.facebook.com/l.php?u=http%3A%2F%2Fmysite.com%2Fansambluri-rezidentiale%2Fpolitehnica-park-residence-79.html%3Futm_source%3Dfacebook.com%26utm_medium%3Dfacebook_ads%26utm_campaign%3Dfacebook_projects&h=LAQHbabAgAQG_qlncuEksPga8LnrPeEdi_JOWmmbwK80NDg&enc=AZPLDl2ZtcVN2fPYVWEZ6NabsduLxbPTIKrNyxcD5b6GSSK0PN5ZUEuMgyhXZzS1aMpCkYWvlXgZwfX7VY6N9A-UfEmZ5zGyi27KAIe06nO-IMzlHoHttmztns3MJcD_5j1bn6XLVp0O-2ikcPDYedquOqLfpAfuhEhPa64VMTL9PQ',
        'params' => {
                         'utm_medium' => 'facebook_ads',
                         'utm_campaign' => 'facebook_projects',
                         'utm_source' => 'facebook.com'
                       },
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'facebook.com',
          'campaign' => 'facebook_projects',
          'medium' => 'facebook_ads',
          'category' => 'paid'
        },'Paid facebook ads - with referer');
}

# links from subscribe to offer ads (user not actually subscribed but clicked on the url back to the website)
{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://l.facebook.com',
        'params' => {},
        'host' => 'mysite.com'
    });
    
    is_deeply(\%source, {
          'source' => 'facebook',
          'category' => 'referer',
          'campaign' => '',
          'medium' => 'paid',
        },'Facebook paid offers, no URL params');
}


done_testing();
