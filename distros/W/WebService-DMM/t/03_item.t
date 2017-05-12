use strict;
use warnings;
use Test::More;

use WebService::DMM::Item;

subtest 'constructor' => sub {
    my $item = WebService::DMM::Item->new();

    ok $item, 'constructor';
    isa_ok $item, 'WebService::DMM::Item';
};

subtest 'accessors' => sub {
    my @accessors = qw/service_name floor_name category_name
                       content_id product_id title
                       actors directors authors fighters
                       price price_all list_price deliveries
                       date keywords maker label sample_images
                       jancode isbn stock series
                      /;

    my %args = (
        service_name  => 'test_service',
        floor_name    => 'test_floor',
        category_name => 'test_category',
        content_id    => 10,
        product_id    => 20,
        URL           => 'http://example.com/',
        URLsp         => 'http://example.com/',
        affiliateURL  => 'http://example.com/test-999',
        affiliateURLsp => 'http://example.com/test-999',
        title         => 'title',
        date          => '2012/09/10',
        keywords      => [qw/apple melon/],
        actors        => [qw/alice kate/],
        directors     => [qw/bob/],
        authors       => [qw/deen/],
        fighters      => [qw/foo bar/],
        maker         => 's1',
        label         => 'deeps',
        jancode       => '111',
        isbn          => '200',
        stock         => '100',
        price         => 1000,
        price_all     => 1000,
        list_price    => 2000,
        deliveries    => [{type=>'a', price=>'b'}],
        sample_images => [qw/a.jpg b.jpg/],
        series        => 'cafe',
    );

    my %aliases = (
        url => 'URL', url_sp => 'URLsp', affiliate_url => 'affiliateURL',
        affiliate_url_sp => 'affiliateURLsp',
    );

    my $item = WebService::DMM::Item->new(%args);
    for my $accessor (@accessors, keys %aliases) {
        can_ok $item, $accessor;
    }

    for my $accessor (@accessors, keys %aliases) {
        my $got = $item->$accessor;
        my $expexted = $args{$accessor} || $args{ $aliases{$accessor} };

        if (ref $got) {
            is_deeply $got, $expexted, "'$accessor' member";
        } else {
            is $got, $expexted, "'$accessor' member"
        }
    }
};

subtest 'image' => sub {
    my %image = (
        list  => 'aa',
        small => 'bb',
        large => 'cc',
    );

    my $item = WebService::DMM::Item->new(
        image => \%image,
    );

    for my $key (keys %image) {
        my $img = $item->image($key);
        is $img, $image{$key}, "Image type '$key'";
    }

    eval {
        $item->image('not_found');
    };
    like $@, qr/Invalid type 'not_found'/, 'invalid image type';
};

done_testing;
