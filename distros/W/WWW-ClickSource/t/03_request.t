use Test::More;

use strict;
use warnings;

eval "use Catalyst::Request";
plan skip_all => "Catalyst::Request required for this test"
    if $@;
    
plan tests => 3;

use_ok("WWW::ClickSource::Request");


{

    my $click_source_request = WWW::ClickSource::Request->new({
        'referer' => 'https://www.google.ro',
        'params' => {},
        'host' => 'mysite.com'
    });
    
    is_deeply($click_source_request,bless( {
                 'referer' => bless( do{\(my $o = 'https://www.google.ro')}, 'URI::https' ),
                 'params' => {},
                 'host' => 'mysite.com'
               }, 'WWW::ClickSource::Request' ), "Goole organic request as expected");
}

{
    
    my $click_source_request = WWW::ClickSource::Request->new({
                 'referer' => 'http://l.facebook.com/l.php?u=http%3A%2F%2Fmysite.com%2Fansambluri-rezidentiale%2Fpolitehnica-park-residence-79.html%3Futm_source%3Dfacebook.com%26utm_medium%3Dfacebook_ads%26utm_campaign%3Dfacebook_projects&h=yAQGdSa9hAQEPxU4-RM5j6eZ_aB3ttRLUzZeJPabMpGjDzw&enc=AZOgYWXyAfT5cPnyJ4x-d23dOy7vDU2uQbt4QJOLxksCApfSg3iFdZltCl8wvmEe_lLfQFb7R4kJ4y-WtqOgTfac9bfeTQL8DHGxUN2pd2QlCURxMVexFfbuTwUCKkcYGdEDs2Es0hifObOz-pZY27Kk',
                 'params' => {
                               'utm_source' => 'facebook.com',
                               'utm_campaign' => 'facebook_projects',
                               'utm_medium' => 'facebook_ads'
                             },
                 'host' => 'mysite.com'
               });
    
    is_deeply($click_source_request,bless( {
                 'referer' => bless( do{\(my $o = 'http://l.facebook.com/l.php?u=http%3A%2F%2Fmysite.com%2Fansambluri-rezidentiale%2Fpolitehnica-park-residence-79.html%3Futm_source%3Dfacebook.com%26utm_medium%3Dfacebook_ads%26utm_campaign%3Dfacebook_projects&h=yAQGdSa9hAQEPxU4-RM5j6eZ_aB3ttRLUzZeJPabMpGjDzw&enc=AZOgYWXyAfT5cPnyJ4x-d23dOy7vDU2uQbt4QJOLxksCApfSg3iFdZltCl8wvmEe_lLfQFb7R4kJ4y-WtqOgTfac9bfeTQL8DHGxUN2pd2QlCURxMVexFfbuTwUCKkcYGdEDs2Es0hifObOz-pZY27Kk')}, 'URI::http' ),
                 'params' => {
                               'utm_source' => 'facebook.com',
                               'utm_campaign' => 'facebook_projects',
                               'utm_medium' => 'facebook_ads'
                             },
                 'host' => 'mysite.com'
               }, 'WWW::ClickSource::Request' ), "Facebook ads request as expected");
               
               
}