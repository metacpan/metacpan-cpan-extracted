use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;

use WebService::DMM;

subtest 'actual parse response', => sub {
    my $guard = mock_guard('Furl::Response', +{
        content => sub {
            local $/;
            <DATA>;
        },
        is_success => sub { 1 },
    },
    'Furl', +{
        get => sub { 'Furl::Response' },
    });

    my $dmm = WebService::DMM->new(
        affiliate_id => 'test-999',
        api_id       => 'test_api_id',
    );

    my $res = $dmm->search(
        site    => 'DMM.co.jp',
        service => 'digital',
        keyword => 'test_key',
    );

    my @items = @{$res->items};
    is((scalar @items), 1, "return items");

    my $item = shift @items;
    isa_ok($item, "WebService::DMM::Item");

    is $item->content_id, 111, 'content id';
    is $item->product_id, 112, 'product id';
    is $item->title, 'test_title', 'title';
    is $item->url, 'http://example.com/', 'URL';
    is $item->affiliate_url, 'http://example.com/test-999', 'affiliate url';
    is $item->image('list'), 'http://pics.dmm.co.jp/testpt.jpg', 'image(list)';
    is $item->image('small'), 'http://pics.dmm.co.jp/testps.jpg', 'image(small)';
    is $item->image('large'), 'http://pics.dmm.co.jp/testpl.jpg', 'image(large)';
    is_deeply $item->sample_images, [
        'http://pics.dmm.co.jp/sample1.jpg',
        'http://pics.dmm.co.jp/sample2.jpg',
    ], 'sample image urls';
    is $item->price, '500-', 'from price';
    is $item->list_price, '1000', 'list price';
    is $item->date, '2012-02-07 10:00:43', 'date';
    is_deeply $item->keywords, ['key1', 'key2'], 'keywords';

    isa_ok $item->series, 'WebService::DMM::Series';
    is $item->series->name, 'test_series', 'series name';
    is $item->series->id, 3, 'series id';

    isa_ok $item->maker, 'WebService::DMM::Maker';
    is $item->maker->name, 'test_maker', 'maker name';
    is $item->maker->id, '4', 'maker id';

    my @actors = @{$item->actors};
    isa_ok $actors[0], 'WebService::DMM::Person::Actor';
    is $actors[0]->name, 'test_actress1', 'actress name1';
    is $actors[0]->ruby, 'test_actress1_ruby', 'actress ruby2';
    is $actors[0]->id, 10, 'actress id1';
    is $actors[1]->name, 'test_actress2', 'actress name2';
    is $actors[1]->ruby, 'test_actress2_ruby', 'actress ruby2';
    is $actors[1]->id, 20, 'actress id2';

    my @directors = @{$item->directors};
    isa_ok $directors[0], 'WebService::DMM::Person::Director';
    is $directors[0]->name, 'test_director', 'director name';
    is $directors[0]->ruby, 'test_director_ruby', 'director ruby';
    is $directors[0]->id, 30, 'director id';

    isa_ok $item->label, 'WebService::DMM::Label';
    is $item->label->name, 'test_label', 'label name';
    is $item->label->id, 40, 'label id';
};

done_testing;

__DATA__
<?xml version="1.0" encoding="euc-jp"?>
<response>
  <request>
    <parameters>
      <parameter name="api_id" value="test_api_id" />
      <parameter name="affiliate_id" value="test-999" />
      <parameter name="operation" value="ItemList" />
      <parameter name="version" value="1.00" />
      <parameter name="timestamp" value="2012-01-13 14:08:16" />
      <parameter name="site" value="DMM.co.jp" />
      <parameter name="service" value="digital" />
      <parameter name="keyword" value="test_key" />
    </parameters>
  </request>
  <result>
    <result_count>20</result_count>
    <total_count>3880</total_count>
    <first_position>1</first_position>
    <items>
      <item>
        <service_name>test</service_name>
        <floor_name>video</floor_name>
        <category_name>video</category_name>
        <content_id>111</content_id>
        <product_id>112</product_id>
        <title>test_title</title>
        <URL>http://example.com/</URL>
        <affiliateURL>http://example.com/test-999</affiliateURL>
        <imageURL>
          <list>http://pics.dmm.co.jp/testpt.jpg</list>
          <small>http://pics.dmm.co.jp/testps.jpg</small>
          <large>http://pics.dmm.co.jp/testpl.jpg</large>
        </imageURL>
        <sampleImageURL>
          <sample_s>
            <image>http://pics.dmm.co.jp/sample1.jpg</image>
            <image>http://pics.dmm.co.jp/sample2.jpg</image>
          </sample_s>
        </sampleImageURL>
        <prices>
          <price>500-</price>
          <list_price>1000</list_price>
        </prices>
        <date>2012-02-07 10:00:43</date>
        <iteminfo>
          <keyword>
            <name>key1</name>
            <id>1</id>
          </keyword>
          <keyword>
            <name>key2</name>
            <id>2</id>
          </keyword>
          <series>
            <name>test_series</name>
            <id>3</id>
          </series>
          <maker>
            <name>test_maker</name>
            <id>4</id>
          </maker>
          <actress>
            <name>test_actress1</name>
            <id>10</id>
          </actress>
          <actress>
            <name>test_actress1_ruby</name>
            <id>10_ruby</id>
          </actress>
          <actress>
            <name>av</name>
            <id>10_classify</id>
          </actress>
          <actress>
            <name>test_actress2</name>
            <id>20</id>
          </actress>
          <actress>
            <name>test_actress2_ruby</name>
            <id>20_ruby</id>
          </actress>
          <actress>
            <name>av</name>
            <id>20_classify</id>
          </actress>
          <director>
            <name>test_director</name>
            <id>30</id>
          </director>
          <director>
            <name>test_director_ruby</name>
            <id>30_ruby</id>
          </director>
          <label>
            <name>test_label</name>
            <id>40</id>
          </label>
        </iteminfo>
      </item>
    </items>
  </result>
</response>
