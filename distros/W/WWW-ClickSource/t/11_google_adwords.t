use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://www.google.ro/aclk?sa=l&ai=CkQ8Jxu8AV5anOMj3ywPhrq7QDZfdqJoIv6Wn19AB-LWwrUoIABABIKOy3CNgg_XjhbAcoAGZrb7WA8gBAakCs4NyggsbkT6qBCVP0Kto3k4Dqvav_8byU4XYwL5wkoIvnLtst3V1mfmNu1K-T9edgAWz-P4YoAYs2AYEgAfP0sEpiAcBkAcCqAemvhvYBwE&sig=AOD64_2-T-kawZPcVep59iFv5IkkmtSIWQ&clui=0&rct=j&q=&ved=0ahUKEwiO5tHVoPLLAhUK1iwKHVw1DbIQ0QwIHA&adurl=http://partner-site.com/de-vanzare/terenuri/Prahova/Bucov',
        'params' => {
                     'gclid' => 'CjwKEAjw_oK4BRDym-SDq-aczicSJAC7UVRt6Jk6GohtQuJgW_dqBivLEy8_adIn2Kvo30mzRnZLlhoC0A3w_wcB'
                    },
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, { 
                        medium => 'cpc',
                        source => 'google',
                        category => 'paid',
                        campaign => ''
    },'CPC Google adwords');
               
}

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://www.google.ro/aclk?sa=l&ai=CkQ8Jxu8AV5anOMj3ywPhrq7QDZfdqJoIv6Wn19AB-LWwrUoIABABIKOy3CNgg_XjhbAcoAGZrb7WA8gBAakCs4NyggsbkT6qBCVP0Kto3k4Dqvav_8byU4XYwL5wkoIvnLtst3V1mfmNu1K-T9edgAWz-P4YoAYs2AYEgAfP0sEpiAcBkAcCqAemvhvYBwE&sig=AOD64_2-T-kawZPcVep59iFv5IkkmtSIWQ&clui=0&rct=j&q=&ved=0ahUKEwiO5tHVoPLLAhUK1iwKHVw1DbIQ0QwIHA&adurl=http://partner-site.com/de-vanzare/terenuri/Prahova/Bucov',
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, { 
                        medium => 'cpc',
                        source => 'google',
                        category => 'paid',
                        campaign => ''
    },'CPC Google adwords - no gclid');
               
}

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://www.googleadservices.com/pagead/aclk?sa=L&ai=CAvjkhtH_VsrfCurjyAPs-p6QBpfdqJoI98Sm19ABh8yto44GCAAQAygDYIOl4YXoG6ABma2-1gPIAQGpArODcoILG5E-qgQiT9AQ_H8y95KcOi84GOysV7no9Wj3-UpxC2CzNz-Lgygn2ogGAaAGLIAHz9LBKZAHA6gHpr4b2AcB&ohost=www.google.ro&cid=CAASJORov5iv3xprfKmaaysPUr0tNY1j_tsIYIbZyPZNCKL-YTerSQ&sig=AOD64_0pdoRD49qaUOISHM8jcA1zoq0h-A&clui=6&rct=j&q=&ved=0ahUKEwjqgNTWj_DLAhUFEpoKHc-tA-oQ0QwIJw&adurl=http://partner-site.com/de-vanzare/apartamente-3-camere/Bucuresti/Centrul_Civic/Bulevardul_Mircea_Voda',
        'params' => {
                     'gclid' => 'CLXBtbKQ8MsCFUa4GwodTYIP2g'
                    },
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, { 
                        medium => 'cpc', 
                        source => 'google', 
                        category => 'paid',
                        campaign => '',
     },'CPC Google adwords - on-page ad');
               
}

{
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => 'http://www.googleadservices.com/pagead/aclk?sa=L&ai=CAvjkhtH_VsrfCurjyAPs-p6QBpfdqJoI98Sm19ABh8yto44GCAAQAygDYIOl4YXoG6ABma2-1gPIAQGpArODcoILG5E-qgQiT9AQ_H8y95KcOi84GOysV7no9Wj3-UpxC2CzNz-Lgygn2ogGAaAGLIAHz9LBKZAHA6gHpr4b2AcB&ohost=www.google.ro&cid=CAASJORov5iv3xprfKmaaysPUr0tNY1j_tsIYIbZyPZNCKL-YTerSQ&sig=AOD64_0pdoRD49qaUOISHM8jcA1zoq0h-A&clui=6&rct=j&q=&ved=0ahUKEwjqgNTWj_DLAhUFEpoKHc-tA-oQ0QwIJw&adurl=http://partner-site.com/de-vanzare/apartamente-3-camere/Bucuresti/Centrul_Civic/Bulevardul_Mircea_Voda',
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, { 
                        medium => 'cpc', 
                        source => 'google', 
                        category => 'paid',
                        campaign => '',
     },'CPC Google adwords - on-page ad - no gclid');         
}


{
    my %source = WWW::ClickSource::detect_click_source({
        'params' => {
                     'gclid' => 'CLXBtbKQ8MsCFUa4GwodTYIP2g'
                    },
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, { 
                        medium => 'cpc', 
                        source => 'google', 
                        category => 'paid',
                        campaign => '',
     },'CPC Google adwords - missing refrerer');
}



done_testing();