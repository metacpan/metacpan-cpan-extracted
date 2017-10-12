#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;
use File::Temp qw(tempdir);
use Path::Class qw(dir file);

use FindBin qw($Bin);
use lib "$Bin/lib";

use XML::Chain qw(xc);

my $tmp_dir = dir(tempdir( CLEANUP => 1 ));

subtest 'xc()' => sub {
    my $body = xc('body');
    isa_ok($body, 'XML::Chain::Element', 'xc(exported) returns element');
    is($body->as_string, '<body/>', 'create an element');

    my $body_class = xc('body', {'data-a' => 'b', class => 'myClass'});
    is($body_class->as_string, '<body class="myClass" data-a="b"/>', 'create an element with hash attribute');
    my $body_class2 = xc('body', class => 'myClass', onLoad => 'alert("yay!")');
    is($body_class2->as_string, '<body class="myClass" onLoad="alert(&quot;yay!&quot;)"/>', 'create an element with sorted attributes');
    my $load_file = xc([$Bin, 'tdata', '01_basics.xml']);
    is($load_file->as_string, '<hello><world/></hello>', 'create from file (IO::Any)');

    is(xc(\'<body><h1>and</h1><h1>head</h1></body>')->find('//h1')->count, 2, '=head3 xc($what_ref); -> parsing xml strings');

    my $over_el = xc('overload');
    is("$over_el", '<overload/>', '=head2 as_string; sample');

    my $xml_doc = XML::LibXML->load_xml(string => '<xml-doc><el/></xml-doc>');
    is(xc($xml_doc)->as_string, '<xml-doc><el/></xml-doc>', 'xc(XML::LibXML::Document->new())');
};

subtest 'basic creation / removal' => sub {
    my $body = xc('body');
    my $h1 = $body->c('h1')->t('I am heading');
    isa_ok($h1,'XML::Chain::Selector','$h1 → selector on traversal');
    is($body, '<body><h1>I am heading</h1></body>', 'selector create an element');
    cmp_ok($body->as_string, 'eq', $body->toString, 'toString alias to as_string');

    my $div = xc('div', class => 'pretty')
                ->c('h1')->t('hello')
                ->up
                ->c('p', class => 'intro')->t('world')
                ->root
                ->a( xc('p')->t('of chained XML.') );
    is($div->as_string, '<div class="pretty"><h1>hello</h1><p class="intro">world</p><p>of chained XML.</p></div>', '=head1 SYNOPSIS; block1 -> chained create elements');

    my $icon_el = xc('i', class => 'icon-download icon-white');
    is($icon_el->as_string, '<i class="icon-download icon-white"/>', '=head2 xc; sample');

    my $span_el = xc('span')->t('some')->t(' ')->t('more text');
    is($span_el->as_string, '<span>some more text</span>', '=head2 t; sample');

    my $append_xc = xc('body')
        ->a(xc('p')->t(1))
        ->a(xc('p2')->t(2));
    is($append_xc->as_string, '<body><p>1</p><p2>2</p2></body>', 'append xc()');

    my $head2_root = xc('p')
        ->t('this ')
        ->a(xc('b')->t('is'))
        ->t(' important!')
        ->root;
    is($head2_root, '<p>this <b>is</b> important!</p>', '=head2 root; sample');
    $head2_root->find('//b')->rename('i');
    is($head2_root, '<p>this <i>is</i> important!</p>', 'rename()');

    my $pdiv = xc('base')
            ->a(xc('p')->t(1))
            ->a(xc('p')->t(2))
            ->a(xc('div')->t(3))
            ->a(xc('p')->t(4));
    my $p = $pdiv->find('//p');
    is($pdiv->find('//p[position()=3]')->rm->name,'base','=head2 rm, remove_and_parent; rm() element, parent is base');
    is($p->count,2,'rm() element, 2 left in selection constructed before');
    is($pdiv, '<base><p>1</p><p>2</p><div>3</div></base>');
};

subtest 'navigation' => sub {
    my $body = xc('body')
                ->c('p')->t('para1')->up
                ->append_and_select('p')
                    ->t('para2 ')
                    ->a(xc('b')->t('important'))
                    ->t(' para2_2 ')
                    ->append(xc('b', class => 'less')->t('less important'))
                    ->t(' para2_3')
                    ->up
                ->c('p')->t('the last one')
                ->root;
    is($body, '<body><p>para1</p><p>para2 <b>important</b> para2_2 <b class="less">less important</b> para2_3</p><p>the last one</p></body>', 'test test xml');
    isa_ok($body->find('//b')->first->as_xml_libxml, 'XML::LibXML::Element', 'first <b>');
    isa_ok($body->children->first->as_xml_libxml, 'XML::LibXML::Element', 'first <p>');

    is($body->find('//b')->count, 2, 'two <b> tags');
    is($body->find('//p/b[@class="less"]')->text_content, 'less important', q{find('//p/b[@class="less"]')});
    is($body->find('/body/p[position() = last()]')->text_content, 'the last one', q{find('/body/p[position() = last()]')});
};

subtest 'copy elements between documents' => sub {
    my $body = xc('body')
        ->a('p', class => '1')
        ->a('p', class => '2');
    my $new_body = xc('body')
        ->a(xc('div')->a($body->find('/body/p')))
        ->a(xc('div')->t('second div'));
    is($new_body->single->as_string, '<body><div><p class="1"/><p class="2"/></div><div>second div</div></body>', 'test test xml inside divs');
};

subtest 'loop over elements, rename' => sub {
    my $body = xc('bodyz');
    is($body, '<bodyz/>','rename()');

    $body->rename('body');
    $body
        ->a(xc('p.1')->t(1))
        ->a(xc('p.2')->t(2))
        ->a(xc('div')->t(3))
        ->a(xc('p.3')->t(4))
        ->children->each(sub { $_->rename('p') if $_->name =~ m/^p[.]/ });
    is($body, '<body><p>1</p><p>2</p><div>3</div><p>4</p></body>','=head2 each; rename using each()');

    my $remap = xc('body')->a('p', i => 1);
    is( $remap->children->remap(
            sub {
                (map {xc('e', i => $_)} 1 .. 3), $_;
            }
            )->root,
        '<body><e i="1"/><e i="2"/><e i="3"/><p i="1"/></body>',
        '=head2 remap; add +3 elements'
    );
    is( $remap->find('//e[position()=2]')->remap(
            sub {
                xc('p', i=>4),
                xc('p', i=>5),
            }
            )->root,
        '<body><e i="1"/><p i="4"/><p i="5"/><e i="3"/><p i="1"/></body>',
        'replace element'
    );
    is( $remap->find('//e[@i="2"] | //p[@i="5"]')->remap(sub { })->root,
        '<body><e i="1"/><p i="4"/><e i="3"/><p i="1"/></body>',
        'remove elements'
    );

    my $remap2 = xc(\'<body><p>1</p><p>2</p><div>3</div><p>4</p></body>');
    $remap2->children->remap(sub {(
        ($_->name eq 'div')
        ? xc('p')->t($_->text_content)         # replace <div> for <p>
        : $_->text_content eq '2'
        ? (                                    # replace node with text "2" for 3x <div>
            xc('div')->t(2),
            xc('div')->t(21),
            xc('div')->t(22),
        )
        : $_->text_content eq '4'
        ? undef                                # delete <p> with text "4"
        : $_                                   # first <p> kept
    )});
    is($remap2, '<body><p>1</p><div>2</div><div>21</div><div>22</div><p>3</p></body>','replace and delete element via remap()');

    wrap_element: {
        local $TODO = 'wrap element';
        my $i = 5;
        is(
            xc('body')->a('p1')->a('p2')->children->remap(
                sub { xc('div'.$i++)->a($_) }
            )->root,
            '<body><div5><p1/></div5><div6><p2/></div6></body>',
        );
    };
};

subtest 'store' => sub {
    my $tmp_file = $tmp_dir->file('t01.xml');
    xc('body')->t('save me')->set_io_any([$tmp_dir, 't01.xml'])->store;
    is(xc($tmp_file)->text_content, 'save me', '=head1 CHAINED DOCUMENT METHODS; ->store() and load via file');

    isa_ok(xc($tmp_file)->empty->c('div')->t('updated')->store, 'XML::Chain::Element', '->store() returns xc element');
    is($tmp_file->slurp.'', '<body><div>updated</div></body>', 'load & ->store() via file');
};

subtest 'element attributes' => sub {
    my $body = xc(\'<body><img/></body>');
    $body->children->attr('href' => '#', 'title' => '');
    is($body->as_string, '<body><img href="#" title=""/></body>', '->attr() setter');
    is($body->children->attr('href'), '#', '->attr() getter');
    $body->children->attr('title' => undef);
    is($body->as_string, '<body><img href="#"/></body>', '->attr() remove');
};

done_testing;
