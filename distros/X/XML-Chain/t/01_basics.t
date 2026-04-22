#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;
use File::Temp  qw(tempdir);
use Path::Class qw(dir file);

use FindBin qw($Bin);
use lib "$Bin/lib";

use XML::Chain qw(xc);

my $tmp_dir = dir( tempdir( CLEANUP => 1 ) );

subtest 'xc()' => sub {
    my $body = xc('body');
    isa_ok( $body, 'XML::Chain::Element', 'xc(exported) returns element' );
    is( $body->as_string, '<body></body>', 'create an element' );

    my $body_class = xc( 'body', { 'data-a' => 'b', class => 'myClass' } );
    is( $body_class->as_string,
        '<body class="myClass" data-a="b"></body>',
        'create an element with hash attributes'
    );
    my $body_class2 =
        xc( 'body', class => 'myClass', onLoad => 'alert("yay!")' );
    is( $body_class2->as_string,
        '<body class="myClass" onLoad="alert(&quot;yay!&quot;)"></body>',
        'create an element with attributes'
    );
    my $load_file = xc( [ $Bin, 'tdata', '01_basics.xml' ] );
    is( $load_file->as_string,
        '<hello><world></world></hello>',
        'create from file (IO::Any)'
    );

    is( xc( \'<body><h1>and</h1><h1>head</h1></body>' )->find('//h1')->count,
        2,
        '=head3 xc($what_ref); parses XML strings'
    );

    my $over_el = xc('overload');
    is( "$over_el", '<overload></overload>', '=head2 as_string; sample' );

    my $xml_doc =
        XML::LibXML->load_xml( string => '<xml-doc><el/></xml-doc>' );
    is( xc($xml_doc)->as_string,
        '<xml-doc><el></el></xml-doc>',
        'xc(XML::LibXML::Document->new())'
    );
};

subtest 'basic creation / removal' => sub {
    my $body = xc('body');
    my $h1   = $body->c('h1')->t('I am heading');
    isa_ok( $h1, 'XML::Chain::Selector', '$h1 → selector on traversal' );
    is( $body,
        '<body><h1>I am heading</h1></body>',
        'selector creates an element'
    );
    cmp_ok( $body->as_string, 'eq', $body->toString,
        'toString alias to as_string' );

    my $div =
        xc( 'div', class => 'pretty' )
        ->c('h1')
        ->t('hello')
        ->up->c( 'p', class => 'intro' )
        ->t('world')
        ->root->a( xc('p')->t('of chained XML.') );
    is( $div->as_string,
        '<div class="pretty"><h1>hello</h1><p class="intro">world</p><p>of chained XML.</p></div>',
        '=head1 SYNOPSIS; block 1 -> chained element creation'
    );

    my $icon_el = xc( 'i', class => 'icon-download icon-white' );
    is( $icon_el->as_string,
        '<i class="icon-download icon-white"></i>',
        '=head2 xc; sample'
    );

    my $span_el = xc('span')->t('some')->t(' ')->t('more text');
    is( $span_el->as_string,
        '<span>some more text</span>',
        '=head2 t; sample'
    );

    my $append_xc = xc('body')->a( xc('p')->t(1) )->a( xc('p2')->t(2) );
    is( $append_xc->as_string, '<body><p>1</p><p2>2</p2></body>',
        'append xc()' );

    my $head2_root =
        xc('p')->t('this ')->a( xc('b')->t('is') )->t(' important!')->root;
    is( $head2_root,
        '<p>this <b>is</b> important!</p>',
        '=head2 root; sample'
    );
    $head2_root->find('//b')->rename('i');
    is( $head2_root, '<p>this <i>is</i> important!</p>', 'rename()' );

    my $pdiv = xc('base')->a( xc('p')->t(1) )->a( xc('p')->t(2) )
        ->a( xc('div')->t(3) )->a( xc('p')->t(4) );
    my $p = $pdiv->find('//p');
    is( $pdiv->find('//p[position()=3]')->rm->name,
        'base',
        '=head2 rm, remove_and_parent; rm() element, parent is base' );
    is( $p->count, 2,
        'rm() element, 2 left in selection constructed before' );
    is( $pdiv, '<base><p>1</p><p>2</p><div>3</div></base>' );
};

subtest 'basic navigation' => sub {
    my $body =
        xc('body')->c('p')->t('para1')->up->append_and_select('p')
        ->t('para2 ')
        ->a( xc('b')->t('important') )
        ->t(' para2_2 ')
        ->append( xc( 'b', class => 'less' )->t('less important') )
        ->t(' para2_3')
        ->up->c('p')->t('the last one')->root;
    is( $body,
        '<body><p>para1</p><p>para2 <b>important</b> para2_2 <b class="less">less important</b> para2_3</p><p>the last one</p></body>',
        'build nested XML'
    );
    isa_ok( $body->find('//b')->first->as_xml_libxml,
        'XML::LibXML::Element', 'first <b>' );
    isa_ok( $body->children->first->as_xml_libxml,
        'XML::LibXML::Element', 'first <p>' );

    is( $body->find('//b')->count, 2, 'two <b> tags' );
    is( $body->find('//p/b[@class="less"]')->text_content,
        'less important',
        q{find('//p/b[@class="less"]')}
    );
    is( $body->find('/body/p[position() = last()]')->text_content,
        'the last one', q{find('/body/p[position() = last()]')} );

    my $mixed =
        xc( \'<body>before<p>one</p><!-- note --><p>two</p>after</body>' );
    is( $mixed->children->count, 2,
        'children() returns only child elements' );
    is( $mixed->children->first->name,
        'p', 'children() skips text and comment nodes' );
};

subtest 'basic copy elements between documents' => sub {
    my $body     = xc('body')->a( 'p', class => '1' )->a( 'p', class => '2' );
    my $new_body = xc('body')->a( xc('div')->a( $body->find('/body/p') ) )
        ->a( xc('div')->t('second div') );
    is( $new_body->single->as_string,
        '<body><div><p class="1"></p><p class="2"></p></div><div>second div</div></body>',
        'copy selected XML inside divs'
    );
};

subtest 'store' => sub {
    my $tmp_file = $tmp_dir->file('t01.xml');
    xc('body')->t('save me')->set_io_any( [ $tmp_dir, 't01.xml' ] )->store;
    is( xc($tmp_file)->text_content,
        'save me',
        '=head1 CHAINED DOCUMENT METHODS; ->store() and load via file' );

    isa_ok( xc($tmp_file)->empty->c('div')->t('updated')->store,
        'XML::Chain::Element', '->store() returns an xc element' );
    is( $tmp_file->slurp . '',
        '<body><div>updated</div></body>',
        'load & ->store() via file'
    );
};

subtest 'element attributes' => sub {
    my $body = xc( \'<body><img/></body>' );
    $body->children->attr( 'href' => '#', 'title' => '' );
    is( $body->as_string,
        '<body><img href="#" title=""></img></body>',
        '->attr() setter'
    );
    is( $body->children->attr('href'), '#', '->attr() getter' );
    $body->children->attr( 'title' => undef );
    is( $body->as_string,
        '<body><img href="#"></img></body>',
        '->attr() remove'
    );
};

subtest 'default parser' => sub {
    my $parser = XML::Chain->_default_parser;
    isa_ok( $parser, 'XML::LibXML', 'private default parser' );
    ok( $parser->no_network, 'default parser disables network access' );
    ok( !$parser->expand_entities,
        'default parser disables entity expansion' );
    ok( !$parser->load_ext_dtd,
        'default parser disables external DTD loading' );
    ok( !$parser->recover, 'default parser disables recovery mode' );

    throws_ok(
        sub { xc( \'<body><broken></body>' ) },
        qr/parser error|Opening and ending tag mismatch|Premature end/i,
        'malformed XML is rejected by the default parser',
    );
};

subtest 'data() storage - per-element metadata' => sub {
    my $root =
        xc( \'<root><item id="1"/><item id="2"/><item id="3"/></root>' );

    # Get and set on single element
    my $item1 = $root->find('//item[@id="1"]')->first;
    $item1->data( user_id => 42 );
    is( $item1->data('user_id'), 42, 'data() set and get on single element' );

    # Multiple keys
    $item1->data( status => 'active' );
    is( $item1->data('status'),  'active', 'data() stores multiple keys' );
    is( $item1->data('user_id'), 42, 'previously set data still accessible' );

    # Get all data
    my $all_data = $item1->data;
    is_deeply(
        $all_data,
        { 'user_id' => 42, 'status' => 'active' },
        'data() with no args returns all'
    );

    # Set on multi-element selection
    my $all_items = $root->find('//item');
    $all_items->data( processed => 1 );
    foreach my $item ( $all_items->as_xml_libxml ) {

        # Get back as Element to check data
        my $el =
            $root->find( '//item[@id="' . $item->getAttribute('id') . '"]' )
            ->first;
        is( $el->data('processed'),
            1, 'data() set on all elements in selection' );
    }

    # Verify item1 still has its original data
    is( $item1->data('user_id'),
        42, 'multi-element set does not overwrite existing data' );
    is( $item1->data('processed'), 1, 'multi-element set adds new keys' );
};

subtest 'map_selection() and grep_selection()' => sub {
    my $root = xc(
        \'<root><p>one</p><div>two</div><p>three</p><span>four</span></root>'
    );

    # grep_selection - filter by element name
    my $ps = $root->children->grep_selection( sub { $_->name eq 'p' } );
    is( $ps->count, 2, 'grep_selection() returns matching elements' );
    is( $ps->first->text_content,
        'one', 'grep_selection() first matched element' );

    # grep_selection - filter by text content
    my $long = $root->children->grep_selection(
        sub { length( $_->text_content ) > 3 } );
    is( $long->count, 2, 'grep_selection() filters by text length' );

    # grep_selection - empty result
    my $none =
        $root->children->grep_selection( sub { $_->name eq 'article' } );
    is( $none->count, 0,
        'grep_selection() returns empty selector when nothing matches' );

    # map_selection - identity returns all elements
    my $divs = $root->children->map_selection( sub {$_} );
    is( $divs->count, 4,
        'map_selection() with identity returns all elements' );

    # map_selection - return only matching elements (filter via map_selection)
    my $only_p =
        $root->children->map_selection( sub { $_->name eq 'p' ? $_ : () } );
    is( $only_p->count, 2,
        'map_selection() can filter by returning nothing' );

    # chaining: grep_selection then count
    is( $root->children->grep_selection( sub { $_->name ne 'div' } )->count,
        3, 'grep_selection() chains correctly' );
};

done_testing();
