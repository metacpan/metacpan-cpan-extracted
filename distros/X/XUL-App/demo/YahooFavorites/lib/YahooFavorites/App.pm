use strict;
use warnings;

package YahooFavorites::App;
our $VERSION = '1.0.4';

use XUL::App::Schema;
use XUL::App schema {
    xulfile 'about.xul' =>
        generated from 'YahooFavorites::View::About';

    xulfile 'options.xul' =>
        generated from 'YahooFavorites::View::Options',
        includes 'options.js';

    xulfile 'webdigest.xul' =>
        generated from 'YahooFavorites::View::WebDigest',
        overlays 'chrome://browser/content/browser.xul',
        includes qw( webdigest.css webdigest_mac.css );

    xpifile 'yahoofavorites.xpi' =>
        name is 'YahooFavorites',
        display_name is '雅虎收藏＋',
        id is '{17cc9b7a-e4c0-11da-974c-0050baed0569}', # FIXME: ensure id is unique.
        version is '1.0.5',
        description is '收藏、分享、发现',
        targets {
            Firefox => ['2.0' => '3.0.*'],  # FIXME
            Mozilla => ['1.5' => '1.8'],  # FIXME
        },
        creator is '阿里巴巴雅虎口碑公司',
        developers are ['agentzh'],
        contributors are [],
        #updateURL is 'http://myweb.cn.yahoo.com/update.rdf',
        homepageURL is 'http://yahoofavorites.agentz.org', # FIXME
        aboutURL is 'chrome://myweb.cn.yahoo.com/content/about.xul',
        iconURL is 'chrome://yahoofavorites/content/about-webdigest-small.png';  # like 'chrome://yahoofavorites/content/logo.png'
        #updateURL is 'http://myweb.cn.yahoo.com/firefox/update.rdf';
};

1;

