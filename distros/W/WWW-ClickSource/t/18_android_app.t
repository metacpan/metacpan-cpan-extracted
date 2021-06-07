use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'android-app://com.google.android.googlequicksearchbox',
        'params' => {
                     'gclid' => 'CjwKEAjw_oK4BRDym-SDq-aczicSJAC7UVRt6Jk6GohtQuJgW_dqBivLEy8_adIn2Kvo30mzRnZLlhoC0A3w_wcB'
                    },
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, { 
                        medium => 'cpc',
                        source => 'android-app',
                        category => 'paid',
                        campaign => '',
                        app => 'com.google.android.googlequicksearchbox',
    },'CPC Google adwords from google app');
               
}

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'android-app://com.google.android.googlequicksearchbox',
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, { 
                        medium => '',
                        source => 'android-app',
                        category => 'referer',
                        campaign => '',
                        app => 'com.google.android.googlequicksearchbox',
    },'Referer - android app');

}

done_testing();
