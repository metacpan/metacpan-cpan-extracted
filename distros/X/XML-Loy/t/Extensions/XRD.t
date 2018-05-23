#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib', '../lib', '../../lib';

use Test::More tests => 133;

use Mojo::JSON qw/encode_json decode_json/;

use_ok('XML::Loy::XRD');

# Synopsis

ok(my $xrd = XML::Loy::XRD->new, 'Empty Constructor');
ok($xrd->subject('http://sojolicio.us/'), 'Add subject');
ok($xrd->alias('https://sojolicio.us/'), 'Add alias');
ok($xrd->link('lrdd' => { template => '/.well-known/webfinger?resource={uri}'}),
     'Add link');
ok($xrd->property('describedby' => '/me.foaf'), 'Add property');
ok($xrd->property('private' => undef), 'Add property');

is($xrd->to_pretty_xml, << 'XRD', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Subject>http://sojolicio.us/</Subject>
  <Alias>https://sojolicio.us/</Alias>
  <Link rel="lrdd"
        template="/.well-known/webfinger?resource={uri}" />
  <Property type="describedby">/me.foaf</Property>
  <Property type="private"
            xsi:nil="true" />
</XRD>
XRD


is($xrd->at('*')->attr('xmlns:xsi'), 'http://www.w3.org/2001/XMLSchema-instance', 'xsi');

is($xrd->subject, 'http://sojolicio.us/', 'Get subject');

ok($xrd->subject('blabla'), 'Set subject');

is($xrd->subject, 'blabla', 'Get subject');

ok($xrd->subject('http://sojolicio.us/'), 'Set subject');

my @array = $xrd->alias;
is($array[0], 'https://sojolicio.us/', 'Get alias');

ok($xrd->alias('http://sojolicio.us'), 'Add alias');
@array = $xrd->alias;
is($array[0], 'https://sojolicio.us/', 'Get alias');
is($array[1], 'http://sojolicio.us', 'Get alias');

my $jrd = decode_json($xrd->to_json);

is($jrd->{subject}, 'http://sojolicio.us/', 'JRD Subject');
is($jrd->{aliases}->[0], 'https://sojolicio.us/', 'JRD Alias');
ok($jrd->{aliases}->[1], 'JRD Alias');
is($jrd->{links}->[0]->{rel}, 'lrdd', 'JRD link 1');
is($jrd->{links}->[0]->{template}, '/.well-known/webfinger?resource={uri}', 'JRD link 1');
ok(!$jrd->{properties}->{private}, 'JRD property 1');
is($jrd->{properties}->{describedby}, '/me.foaf', 'JRD property 2');

ok(my $element = $xrd->property(profile => '/akron.html'), 'Add property');

is($element->text, '/akron.html', 'Return property');

is($xrd->at('Property[type=profile]')->text, '/akron.html', 'Get Property');

ok(!$xrd->property, 'Get Property without type');

is($xrd->property('profile')->text, '/akron.html', 'Get Property');

ok($element = $xrd->link(hcard => '/me.hcard'), 'Add link');

ok($element->attr('href'), 'Return link');

ok($element->add(Title => 'My hcard'), 'Add title');

is($xrd->at('Link[rel=hcard] Title')->text, 'My hcard', 'Get title');

ok($element = $xrd->link(lrdd2 => {template => '/wf?resource={uri}'}), 'Add link');

ok($element->add(Title => 'My Webfinger'), 'Add title');

is($xrd->at('Link[rel=lrdd2] Title')->text, 'My Webfinger', 'Get title');

is($xrd->link('hcard')->at('Title')->text, 'My hcard', 'Get title');

is($xrd->at('Link[rel=lrdd2] Title')->text, 'My Webfinger', 'Get title');
is($xrd->at('Link[rel=lrdd2]')->at('Title')->text, 'My Webfinger', 'Get title');
is($xrd->link('lrdd2')->all_text, 'My Webfinger', 'Get title');


ok($xrd->link('lrdd3' => '/me.json'), 'Add link');

is($xrd->link('lrdd3')->attr('href'), '/me.json', 'Get link');

ok($xrd->link('lrdd3')->remove, 'Remove link');
ok($xrd->link('lrdd'), 'Get link');
ok($xrd->link('lrdd2'), 'Get link');
ok(!$xrd->link('lrdd3'), 'Get link');
ok($xrd->expires('1264843800'), 'Set expiration');
is($xrd->expires, '2010-01-30T09:30:00Z', 'Expiration date');

is($xrd->expires->epoch, '1264843800', 'Expiration date');

ok($xrd->expired, 'Document has expired');

ok($xrd->expires(time + 100), 'Set expiration');
ok(!$xrd->expired, 'Document has expired');

$xrd = XML::Loy::XRD->new(<<XRD);
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Subject>http://sojolicio.us/</Subject>
  <Alias>https://sojolicio.us/</Alias>
  <Link rel="lrdd"
        template="/.well-known/webfinger?resource={uri}" />
  <Property type="describedby">/me.foaf</Property>
  <Property type="private"
            xsi:nil="true" />
</XRD>
XRD

is($xrd->link('lrdd')->attr('template'), '/.well-known/webfinger?resource={uri}', 'Get link');

is($xrd->property('private')->attr('xsi:nil'), 'true', 'Get property');
is($xrd->subject, 'http://sojolicio.us/', 'Get subject');

$xrd = XML::Loy::XRD->new(<<'JRD');
  {"subject":"http:\/\/sojolicio.us\/",
"aliases":["https:\/\/sojolicio.us\/"],
"links":[{"rel":"lrdd",
"template":"\/.well-known\/webfinger?resource={uri}"}],
"properties":{"private":null,"describedby":"\/me.foaf"}}
JRD

is($xrd->at('Alias')->text, 'https://sojolicio.us/', 'Get Alias');

is($xrd->property('private')->attr('xsi:nil'), 'true', 'nil attribute');

ok($xrd->property(works => 'nice'), 'Add property');
ok($xrd->property(and_works => { -type => 'base64' }, 'evennicer'), 'Add property');
is($xrd->property('and_works')->text, 'evennicer', 'armored property is correct');


##################################
# Old tests

ok($xrd = XML::Loy::XRD->new, 'Constructor');

my $xrd_string = $xrd->to_pretty_xml;
$xrd_string =~ s/\s//g;

is ($xrd_string, '<?xmlversion="1.0"encoding="UTF-8"'.
                 'standalone="yes"?><XRDxmlns="http:'.
                 '//docs.oasis-open.org/ns/xri/xrd-1'.
                 '.0"xmlns:xsi="http://www.w3.org/20'.
                 '01/XMLSchema-instance"/>',
                 'Initial XRD');


my $subnode_1 = $xrd->add('Link',{ rel => 'foo' }, 'bar');

is(ref($subnode_1), 'XML::Loy::XRD',
   'Subnode added');

is($xrd->at('Link')->attr('rel'), 'foo', 'Attribute');
is($xrd->at('Link[rel="foo"]')->text, 'bar', 'Text');

my $subnode_2 = $subnode_1->comment("Foobar Link!");

is($subnode_1, $subnode_2, "Comment added");

$xrd = XML::Loy::XRD->new(<<'XRD');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <!-- Foobar Link! -->
  <Link rel="foo">bar</Link>
</XRD>
XRD

ok($xrd, 'XRD loaded');

is($xrd->at('Link[rel="foo"]')->text, 'bar', "DOM access Link");
is($xrd->link('foo')->text, 'bar', "DOM access Link");

$xrd->add('Property', { type => 'bar' }, 'foo');

is($xrd->at('Property[type="bar"]')->text, 'foo', 'DOM access Property');
is($xrd->property('bar')->text, 'foo', 'DOM access Property');

is_deeply(
    decode_json($xrd->to_json),
    { links =>
	[ { rel => 'foo' } ] =>
	  properties =>
	    { bar  => 'foo' } },
    'Correct JRD');

# From https://tools.ietf.org/html/draft-hammer-hostmeta-17#appendix-A
my $jrd_doc = <<'JRD';
{
  "subject":"http://blog.example.com/article/id/314",
  "expires":"2010-01-30T09:30:00Z",
  "aliases":[
    "http://blog.example.com/cool_new_thing",
    "http://blog.example.com/steve/article/7"],

  "properties":{
    "http://blgx.example.net/ns/version":"1.3",
    "http://blgx.example.net/ns/ext":null
  },
  "links":[
    {
      "rel":"author",
      "type":"text/html",
      "href":"http://blog.example.com/author/steve",
      "titles":{
        "default":"About the Author",
        "en-us":"Author Information"
      },
      "properties":{
        "http://example.com/role":"editor"
      }
    },
    {
      "rel":"author",
      "href":"http://example.com/author/john",
      "titles":{
        "default":"The other author"
      }
    },
    {
      "rel":"copyright",
      "template":"http://example.com/copyright?id={uri}"
    }
  ]
}
JRD

my $xrd_doc = <<'XRD';
<?xml version='1.0' encoding='UTF-8'?>
<XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'
     xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
  <Subject>http://blog.example.com/article/id/314</Subject>
  <Expires>2010-01-30T09:30:00Z</Expires>
  <Alias>http://blog.example.com/cool_new_thing</Alias>
  <Alias>http://blog.example.com/steve/article/7</Alias>
  <Property type='http://blgx.example.net/ns/version'>1.2</Property>
  <Property type='http://blgx.example.net/ns/version'>1.3</Property>
  <Property type='http://blgx.example.net/ns/ext' xsi:nil='true' />
  <Link rel='author' type='text/html'
        href='http://blog.example.com/author/steve'>
    <Title>About the Author</Title>
    <Title xml:lang='en-us'>Author Information</Title>
    <Property type='http://example.com/role'>editor</Property>
  </Link>
  <Link rel='author' href='http://example.com/author/john'>
    <Title>The other guy</Title>
    <Title>The other author</Title>
  </Link>
  <Link rel='copyright'
        template='http://example.com/copyright?id={uri}' />
</XRD>
XRD

$xrd = XML::Loy::XRD->new($xrd_doc);

is_deeply(
  decode_json($xrd->to_json),
  decode_json($jrd_doc), 'JRD'
);

$xrd = XML::Loy::XRD->new($jrd_doc);

is_deeply(
  decode_json($xrd->to_json),
  decode_json($jrd_doc), 'JRD'
);


# Expires:
is ($xrd->expires, '2010-01-30T09:30:00Z', 'Expiration date');
is ($xrd->expires->epoch, '1264843800', 'Expiration date');


$xrd_doc = <<'XRD';
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
     xmlns:hm="http://host-meta.net/xrd/1.0"
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <hm:Host>hostme.ta</hm:Host>
  <Property type="permanentcheck">1</Property>
  <Property type="foo">bar</Property>
  <Property type="check">4</Property>
  <Link href="http://www.sojolicio.us/"
        rel="salmon">
    <Title>Salmon</Title>
  </Link>
</XRD>
XRD

$xrd = XML::Loy::XRD->new($xrd_doc);

my @prop = $xrd->at(':root')->children('Property')->each;

is($prop[0]->attr('type'), 'permanentcheck', 'Found prop 1');
is($prop[1]->attr('type'), 'foo', 'Found prop 2');
is($prop[2]->attr('type'), 'check', 'Found prop 3');

ok($xrd->link(author => { href => 'http://sojolicio.us/author'}), 'Add link');
ok($xrd->link(hub => { href => 'http://sojolicio.us/hub'}), 'Add link');

my $xrd2 = $xrd->filter_rel('salmon hub');

is($xrd->property('permanentcheck')->text, 1, 'Found prop 1');
is($xrd->property('foo')->text, 'bar', 'Found prop 2');
is($xrd->property('check')->text, 4, 'Found prop 3');
is($xrd->link('salmon')->attr('href'), 'http://www.sojolicio.us/', 'Link 1');
is($xrd->link('author')->attr('href'), 'http://sojolicio.us/author', 'Link 2');
is($xrd->link('hub')->attr('href'), 'http://sojolicio.us/hub', 'Link 3');

my $xrd3 = $xrd->filter_rel(['salmon', 'author']);

is($xrd2->property('permanentcheck')->text, 1, 'Found prop 1');
is($xrd2->property('foo')->text, 'bar', 'Found prop 2');
is($xrd2->property('check')->text, 4, 'Found prop 3');
is($xrd2->link('salmon')->attr('href'), 'http://www.sojolicio.us/', 'Link 1');
ok(!$xrd2->link('author'), 'Link 2');
is($xrd2->link('hub')->attr('href'), 'http://sojolicio.us/hub', 'Link 3');

my $xrd4 = $xrd->filter_rel('hub', 'author');

is($xrd3->property('permanentcheck')->text, 1, 'Found prop 1');
is($xrd3->property('foo')->text, 'bar', 'Found prop 2');
is($xrd3->property('check')->text, 4, 'Found prop 3');
is($xrd3->link('salmon')->attr('href'), 'http://www.sojolicio.us/', 'Link 1');
is($xrd3->link('author')->attr('href'), 'http://sojolicio.us/author', 'Link 2');
ok(!$xrd3->link('hub'), 'Link 3');

my $xrd5 = $xrd->filter_rel;

is($xrd4->property('permanentcheck')->text, 1, 'Found prop 1');
is($xrd4->property('foo')->text, 'bar', 'Found prop 2');
is($xrd4->property('check')->text, 4, 'Found prop 3');
ok(!$xrd4->link('salmon'), 'Link 1');
is($xrd4->link('author')->attr('href'), 'http://sojolicio.us/author', 'Link 2');
is($xrd4->link('hub')->attr('href'), 'http://sojolicio.us/hub', 'Link 3');

is($xrd5->property('permanentcheck')->text, 1, 'Found prop 1');
is($xrd5->property('foo')->text, 'bar', 'Found prop 2');
is($xrd5->property('check')->text, 4, 'Found prop 3');
ok(!$xrd5->link('salmon'), 'Link 1');
ok(!$xrd5->link('author'), 'Link 2');
ok(!$xrd5->link('hub'), 'Link 3');

ok(my $xrd6 = XML::Loy::XRD->new, 'New XRD document');
ok($xrd6->link(name => 'Akron'), 'Add name link');
ok($xrd6->alias('Peter'), 'Add alias');
ok($xrd6->subject('Sorted Test'), 'Add subject');
ok($xrd6->expires(time), 'Add expires');

my $xrd6r = $xrd6->at('*');
is($xrd6r->children->[0]->tag, 'Subject', 'Check Subject');
is($xrd6r->children->[1]->tag, 'Expires', 'Check Subject');
is($xrd6r->children->[2]->tag, 'Link', 'Check Subject');
is($xrd6r->children->[3]->tag, 'Alias', 'Check Subject');

ok(my $xrd7 = XML::Loy->new('test'), 'New XRD with prefixes');
ok($xrd7->extension(-XRD), 'Add extension');
ok($xrd7->link(name => 'Akron'), 'Add name link');
ok($xrd7->alias('Peter'), 'Add alias');
ok($xrd7->subject('Sorted Test'), 'Add subject');
ok($xrd7->expires(time), 'Add expires');

my $xrd7r = $xrd7->at('*');
is($xrd7r->children->[0]->tag, 'xrd:Subject', 'Check Subject');
is($xrd7r->children->[1]->tag, 'xrd:Expires', 'Check Subject');
is($xrd7r->children->[2]->tag, 'xrd:Link', 'Check Subject');
is($xrd7r->children->[3]->tag, 'xrd:Alias', 'Check Subject');


my $wrapper = XML::Loy->new('test');
ok($wrapper->extension(-XRD), 'Set extension');
ok($wrapper->property(test => 'geht'), 'Set property');

is($wrapper->at('*')->attr('xmlns:xsi'), 'http://www.w3.org/2001/XMLSchema-instance', 'xsi');

__END__
