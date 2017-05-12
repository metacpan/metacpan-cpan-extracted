use Test::More;

use strict;
use warnings;

use_ok('WWW::ClickSource');

my @test_urls = (
    'https://www.google.ro',
    'https://www.google.co.uk/',
    'https://www.google.com.tw/',
    'https://webcache.googleusercontent.com',
    'http://www.google.ro/search?q=Spatiu+comercial+de+inchiriat+20mp+sect+4+bucuresti&client=ms-opera_mb_no&channel=bh&prmd=ivns&ei=Lpz_VpStL8zda62OotgM&start=70&sa=N',
    'http://www.google.ro/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&ved=0ahUKEwjYm5_P5_LLAhViApoKHVCHAvAQFggfMAE&url=http%3A%2F%2Fmysite.com%2Fcoldwell-banker-anunturi%2Fvanzare-apartament-3-camere-in-sector-6-zona-veteranilor-cbr108425.html&usg=AFQjCNEXX7niko19ju_GfMBhkNTQst5w-w&sig2=ojgXXbtrNGKmU_S0j-oP-w&bvm=bv.118443451,d.bGs',
    'http://www.google.com/search',
);

foreach my $url (@test_urls) {
    
    my %source = WWW::ClickSource::detect_click_source({
        'referer' => $url,
        'params' => {},
        'host' => 'myapp.com'
    });
    
    is_deeply(\%source, {
                 medium => 'organic', 
                 source => 'google', 
                 category => 'organic',
                 campaign => ''
    },"Organic searach from ".substr($url,0,50));      
               
}

done_testing();