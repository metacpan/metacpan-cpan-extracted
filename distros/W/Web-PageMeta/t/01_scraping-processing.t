#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::Most;
use Web::PageMeta;
use Web::Scraper;

subtest 'www.meon.eu' => sub {
    my $escraper = scraper {
        process_first '.slider .camera_wrap div', 'image' => '@data-src';
    };
    my $wmeta = Web::PageMeta->new(
        url           => 'https://www.meon.eu/',
        extra_scraper => $escraper,
        _ua           => Test::Mock::Future::HTTP->new,
    );
    is($wmeta->title,       'Jozef Kutej, meon.eu - digitizing creativity', 'title()');
    is($wmeta->image,       'https://www.meon.eu/static/img/picture1.jpg',  'image()');
    is($wmeta->image_data,  "www.meon.eu:picture1.jpg\n",                   'image_data()');
    is($wmeta->description, 'homepage',                                     'description()');
};

subtest 'apa.at' => sub {
    my $wmeta = Web::PageMeta->new(
        url => 'https://apa.at/',
        _ua => Test::Mock::Future::HTTP->new
    );
    is($wmeta->title, 'Willkommen in der APA – Austria Presse Agentur', 'title()');
    is($wmeta->image, 'https://apa.at/wp-content/uploads/2020/05/apa_start_1.jpg', 'image()');
    is($wmeta->image_data, "mock-image-data:apa_start_1.jpg\n", 'image_data()');
};

subtest 'geizhals.at' => sub {

    # iso-8859-1 example
    my $wmeta = Web::PageMeta->new(
        url => 'https://geizhals.at/x-a2374481.html',
        _ua => Test::Mock::Future::HTTP->new
    );
    is( $wmeta->title,
        'Huawei MateBook 14 AMD Space Grey (2020), Ryzen 5 4600H, 16GB RAM ab € 906,55 (2021) | Preisvergleich Geizhals Österreich',
        'title()'
    );
    is($wmeta->image, 'https://gzhls.at/i/44/81/2374481-n0.jpg', 'image()');
};

subtest 'www.meon.eu/base-test1' => sub {
    my $wmeta = Web::PageMeta->new(
        url => 'https://www.meon.eu/base-test1',
        _ua => Test::Mock::Future::HTTP->new,
    );
    is($wmeta->image, 'https://www.meon.eu/static/img/testing-base.jpg', 'image()');
};

subtest 'www.meon.eu/base-test2' => sub {
    my $wmeta = Web::PageMeta->new(
        url => 'https://www.meon.eu/base-test2',
        _ua => Test::Mock::Future::HTTP->new,
    );
    is($wmeta->image, 'https://www.meon.at/static/img/testing-base2.jpg', 'image()');
};

subtest 'www.meon.eu/Web-PageMeta-notfound' => sub {
    my $wmeta = Web::PageMeta->new(
        url => 'https://www.meon.eu/Web-PageMeta-notfound',
        _ua => Test::Mock::Future::HTTP->new,
    );
    throws_ok { $wmeta->image } 'HTTP::Exception::404', 'test 404 not found';
};
subtest 'nonexistinghostname.meon.eu/' => sub {
    my $wmeta = Web::PageMeta->new(
        url => 'https://nonexistinghostname.meon.eu/',
        _ua => Test::Mock::Future::HTTP->new,
    );
    eval {$wmeta->title};
    if (ok($@, 'exception on broken hostname')) {
        my $e = $@;
        isa_ok($e, 'HTTP::Exception::503', '503 status');
        like(
            $e->status_message,
            qr/\(595\) No such device or address/,
            '503 status, originally 595 from AnyEvent::HTTP'
        );
    }
};

done_testing();

package Test::Mock::Future::HTTP;

use Moose;
use FindBin qw($Bin);
use URI::Escape qw(uri_escape);
use Path::Class qw(file dir);

sub http_get {
    my ($self, $url) = @_;

    my $sites_data_body = file($Bin, 'site_data', uri_escape($url));
    return Future->fail(
        'not found ' . $sites_data_body . ' (`t/site_data/fetch_sitedata.pl ' . $url . '`?)')
        unless -f $sites_data_body;
    my $sites_data_hdr = file($Bin, 'site_data', uri_escape($url) . '.hdrs');
    return Future->fail(
        'not found ' . $sites_data_hdr . ' (`t/site_data/fetch_sitedata.pl ' . $url . '`?)')
        unless -f $sites_data_hdr;

    my $body = $sites_data_body->slurp(iomode => '<:raw');
    my $dumper = 'my ' . $sites_data_hdr->slurp(iomode => '<:raw');
    my $headers = eval $dumper;
    return Future->done($body, $headers);
}

1;
