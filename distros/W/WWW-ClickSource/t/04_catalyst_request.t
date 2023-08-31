use Test::More;

use strict;
use warnings;

eval "use Catalyst::Request";
plan skip_all => "Catalyst::Request required for this test"
    if $@;
    
plan tests => 6;

use_ok("WWW::ClickSource::Request");
use_ok('WWW::ClickSource::Request::CatalystRequest');


{
    my $catalyst_request = bless( {
                 'data_handlers' => {
                                      'application/json' => sub { "DUMMY" },
                                      'application/x-www-form-urlencoded' => sub { "DUMMY" }
                                    },
                 'env' => {},
                 'cookies' => {},
                 'query_keywords' => '',
                 'protocol' => 'HTTP/1.1',
                 'hostname' => '1.2.3.4',
                 'remote_user' => undef,
                 'address' => '1.2.3.4',
                 '_path' => 'coldwell-banker-anunturi/de-vanzare-teren-500-m-sup-2-sup-in-cluj-napoca-zona-manastur-cbl04434.html',
                 'headers' => bless( {
                                       'x-forwarded-for' => '1.2.3.4',
                                       'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                                       'x-forwarded-port' => '80',
                                       '::std_case' => {
                                                         'x-forwarded-port' => 'X-FORWARDED-PORT',
                                                         'cookie' => 'COOKIE',
                                                         'x-forwarded-for' => 'X-FORWARDED-FOR'
                                                       },
                                       'referer' => 'https://www.google.ro',
                                       'user-agent' => 'Mozilla/5.0 (Windows NT 6.0; rv:45.0) Gecko/20100101 Firefox/45.0',
                                       'accept-encoding' => 'gzip, deflate',
                                       'accept-language' => 'en-US,en;q=0.5',
                                       'cookie' => '',
                                       'host' => 'mysite.com'
                                     }, 'HTTP::Headers' ),
                 'base' => bless( do{\(my $o = 'http://mysite.com:5001/')}, 'URI::http' ),
                 'uri' => bless( do{\(my $o = 'http://mysite.com:5001/coldwell-banker-anunturi/de-vanzare-teren-500-m-sup-2-sup-in-cluj-napoca-zona-manastur-cbl04434.html')}, 'URI::http' ),
                 'captures' => [],
                 'method' => 'GET',
                 '_read_length' => 0,
                 '_body' => 0,
                 'arguments' => [
                                  'coldwell-banker-anunturi',
                                  'de-vanzare-teren-500-m-sup-2-sup-in-cluj-napoca-zona-manastur-cbl04434.html'
                                ],
                 'uploads' => {},
                 'secure' => 0,
                 'action' => '/',
                 'body_parameters' => {},
                 'match' => '/',
                 'parameters' => {},
                 '_use_hash_multivalue' => 0,
                 'query_parameters' => {},
                 '_read_position' => 0
               }, 'Catalyst::Request' );               



    isa_ok($catalyst_request,'Catalyst::Request', 'Object 1 built correctly');

    my $click_source_request = WWW::ClickSource::Request->new($catalyst_request);
    
    is_deeply($click_source_request,bless( {
                 'referer' => bless( do{\(my $o = 'https://www.google.ro')}, 'URI::https' ),
                 'params' => {},
                 'host' => 'mysite.com'
               }, 'WWW::ClickSource::Request::CatalystRequest' ), "Goole organic request as expected");
}

{
    my $catalyst_request = bless( {
                 '_use_hash_multivalue' => 0,
                 'query_parameters' => {
                                         'utm_source' => 'facebook.com',
                                         'utm_campaign' => 'facebook_projects',
                                         'utm_medium' => 'facebook_ads'
                                       },
                 '_read_position' => 0,
                 'parameters' => {
                                   'utm_campaign' => 'facebook_projects',
                                   'utm_source' => 'facebook.com',
                                   'utm_medium' => 'facebook_ads'
                                 },
                 'body_parameters' => {},
                 'match' => 'ansambluri-rezidentiale',
                 'method' => 'GET',
                 '_body' => 0,
                 '_read_length' => 0,
                 'captures' => [],
                 'base' => bless( do{\(my $o = 'http://mysite.com:5001/')}, 'URI::http' ),
                 'uri' => bless( do{\(my $o = 'http://mysite.com:5001/ansambluri-rezidentiale/politehnica-park-residence-79.html?utm_source=facebook.com&utm_medium=facebook_ads&utm_campaign=facebook_projects')}, 'URI::http' ),
                 'action' => 'ansambluri-rezidentiale',
                 'secure' => 0,
                 'arguments' => [
                                  'politehnica-park-residence-79.html'
                                ],
                 'uploads' => {},
                 'protocol' => 'HTTP/1.1',
                 'hostname' => '1.2.3.4',
                 'remote_user' => undef,
                 'env' => {},
                 'data_handlers' => {
                                      'application/json' => sub { "DUMMY" },
                                      'application/x-www-form-urlencoded' => sub { "DUMMY" }
                                    },
                 'cookies' => {},
                 'headers' => bless( {
                                       'x-forwarded-for' => '1.2.3.4',
                                       'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                                       '::std_case' => {
                                                         'cookie' => 'COOKIE',
                                                         'upgrade-insecure-requests' => 'UPGRADE-INSECURE-REQUESTS',
                                                         'x-forwarded-port' => 'X-FORWARDED-PORT',
                                                         'x-forwarded-for' => 'X-FORWARDED-FOR'
                                                       },
                                       'x-forwarded-port' => '80',
                                       'referer' => 'http://l.facebook.com/l.php?u=http%3A%2F%2Fmysite.com%2Fansambluri-rezidentiale%2Fpolitehnica-park-residence-79.html%3Futm_source%3Dfacebook.com%26utm_medium%3Dfacebook_ads%26utm_campaign%3Dfacebook_projects&h=yAQGdSa9hAQEPxU4-RM5j6eZ_aB3ttRLUzZeJPabMpGjDzw&enc=AZOgYWXyAfT5cPnyJ4x-d23dOy7vDU2uQbt4QJOLxksCApfSg3iFdZltCl8wvmEe_lLfQFb7R4kJ4y-WtqOgTfac9bfeTQL8DHGxUN2pd2QlCURxMVexFfbuTwUCKkcYGdEDs2Es0hifObOz-pZY27Kk',
                                       'accept-encoding' => 'gzip, deflate, sdch',
                                       'user-agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.87 Safari/537.36',
                                       'cookie' => '',
                                       'accept-language' => 'en-US,en;q=0.8,ro;q=0.6',
                                       'upgrade-insecure-requests' => '1',
                                       'host' => 'mysite.com'
                                     }, 'HTTP::Headers' ),
                 '_path' => 'ansambluri-rezidentiale/politehnica-park-residence-79.html',
                 'address' => '1.2.3.4'
               }, 'Catalyst::Request' );
               
               
    isa_ok($catalyst_request,'Catalyst::Request', 'Object 2 built correctly');

    my $click_source_request = WWW::ClickSource::Request->new($catalyst_request);
    
    is_deeply($click_source_request,bless( {
                 'referer' => bless( do{\(my $o = 'http://l.facebook.com/l.php?u=http%3A%2F%2Fmysite.com%2Fansambluri-rezidentiale%2Fpolitehnica-park-residence-79.html%3Futm_source%3Dfacebook.com%26utm_medium%3Dfacebook_ads%26utm_campaign%3Dfacebook_projects&h=yAQGdSa9hAQEPxU4-RM5j6eZ_aB3ttRLUzZeJPabMpGjDzw&enc=AZOgYWXyAfT5cPnyJ4x-d23dOy7vDU2uQbt4QJOLxksCApfSg3iFdZltCl8wvmEe_lLfQFb7R4kJ4y-WtqOgTfac9bfeTQL8DHGxUN2pd2QlCURxMVexFfbuTwUCKkcYGdEDs2Es0hifObOz-pZY27Kk')}, 'URI::http' ),
                 'params' => {
                               'utm_source' => 'facebook.com',
                               'utm_campaign' => 'facebook_projects',
                               'utm_medium' => 'facebook_ads'
                             },
                 'host' => 'mysite.com'
               }, 'WWW::ClickSource::Request::CatalystRequest' ), "Facebook ads request as expected");
               
               
}