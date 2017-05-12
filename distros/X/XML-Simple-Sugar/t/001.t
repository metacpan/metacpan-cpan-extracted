use v5.18.0;
use Test::More;
use Test::Exception;
use strict;
use warnings;

use_ok 'XML::Simple::Sugar';

subtest 'xml_read_and_xml_write' => sub {
    my $xs = XML::Simple::Sugar->new;
    $xs->xml_read('<foo><bar baz="biz">abc</bar></foo>');
    my $xml    = $xs->xml_write;
    my $xs_2   = XML::Simple::Sugar->new->xml_read($xml);
    is_deeply $xs->xml_data, $xs_2->xml_data,
        'Internal data structures consistent pre and post write';
};

subtest 'autovivify' => sub {
    my $xs = XML::Simple::Sugar->new;
    lives_ok sub {
        $xs->company->departments( { 'name' => 'IT Department' } )
          ->department( [0] )->person( [0] )->salary(60000);
    }, 'Can autovivify';

    my $xs_2 = XML::Simple::Sugar->new(
        { xml_autovivify => 0, xml => '<foo><bar baz="biz">abc</bar></foo>' } );

    throws_ok { $xs_2->foo->def } qr/def is not a subnode of foo/, 'Can use strict (elements)';
    throws_ok { $xs_2->foo->bar( { 'another' => 'attribute' } ); }
        qr/another is not an attribute of bar/, 'Can use strict (attributes)';
};

subtest 'content' => sub {
    my $xs = XML::Simple::Sugar->new(
        { xml => '<foo><bar baz="biz">abc</bar></foo>' } );
    is $xs->foo->bar->xml_content, 'abc', 'Can fetch content';
    $xs->foo->bar('def');
    is $xs->foo->bar->xml_content, 'def', 'Can change content';

    my $xs2 = XML::Simple::Sugar->new;
    my $xs3 = XML::Simple::Sugar->new;
    $xs3->table->tr->th('title');
    $xs2->html->body->div($xs3);
    my $xml = q|<html><body><div><table><tr><th>title</th></tr></table></div></body></html>|;
    my $xs4 = XML::Simple::Sugar->new( { xml => $xml } );

    is_deeply $xs2->xml_data, $xs4->xml_data,
        'Can nest XML::Simple::Sugar objects';

    my $xs5 = XML::Simple::Sugar->new;
    my $xs6 = XML::Simple::Sugar->new;
    $xs6->table->tr->th('title');
    $xs5->html->body->div->xml_nest($xs6);
    my $xs7 = XML::Simple::Sugar->new( { xml => $xml } );

    is_deeply $xs5->xml_data, $xs7->xml_data,
        'Can nest XML::Simple::Sugar objects with xml_nest';

    my $xs8 = XML::Simple::Sugar->new;
    my $xs9 = XML::Simple::Sugar->new;
    $xs9->table->tr->th('title');
    $xs8->html->body->div([ 0, $xs6 ]);
    my $xs10 = XML::Simple::Sugar->new( { xml => $xml } );

    is_deeply $xs8->xml_data, $xs10->xml_data,
        'Can nest XML::Simple::Sugar objects with []';
};

subtest 'collections' => sub {
    my $xs          = XML::Simple::Sugar->new;
    my $departments = $xs->company->departments;
    my $person = $xs->company->departments->department( [0] )->person( [0] );

    $person->first_name('John')
      ->last_name('Smith')
      ->email('jsmith@example.com');

    my $person_2 = $xs->company->departments->department( [0] )->person( [1] );

    $person_2->first_name('Kelly')
      ->last_name('Smith')
      ->email('ksmith@example.com');

    is $xs->company
        ->departments
        ->department( [0] )
        ->person( [1] )
        ->first_name
        ->xml_content,
        'Kelly',
        'Can set/access elements by index';

    my @xs = $xs->company->departments->department( [0] )->person( ['all'] );
    is scalar @xs, 2, 'Can fetch all elements in a collection';

    @xs = $xs->company->departments->department( [0] )->nonexistent( ['all'] );
    is scalar @xs, 0, 'Returns empty list for non-existent collection';

    is $xs->company
        ->departments
        ->department( [0] )
        ->person( [1] )
        ->first_name( [ 1, 'John' ] )
        ->xml_content,
        'John',
        'Can set/access elements by index array';

    is_deeply $xs->company
        ->departments
        ->department( [0] )
        ->person( [ 1, undef, { 'Is_Nice' => 'Yes' } ] )
        ->xml_attr,
        { 'Is_Nice' => 'Yes' },
        'Can set/access attributes by index array';
};

subtest 'attr_rmattr' => sub {
    my $xs          = XML::Simple::Sugar->new;
    my $departments = $xs->company->departments;
    $xs->company->departments( { 'name' => 'IT Department' } );
    my $attr = $xs->company->departments->xml_attr;
    is $attr->{'name'}, 'IT Department', 'Can set attributes';
    $xs->company->departments->xml_rmattr('name');
    $attr = $xs->company->departments->xml_attr;
    is $attr->{'name'}, undef, 'Can remove attributes';
};

subtest 'xmldecl' => sub {
    my $xs = XML::Simple::Sugar->new( { xml_xs => XML::Simple->new( XMLDecl => 'foo' ) } );
    my $subnode = $xs->subnode;
    like $subnode->xml_write, qr/^foo/, 'Subnode returns root XMLDecl';

    $xs = XML::Simple::Sugar->new;
    like $xs->xml_write, qr/\Q<?xml version="1.0"?>\E/, 'Default XMLDecl';
};

subtest 'soapish' => sub {
    my $xs = XML::Simple::Sugar->new;
    my $soap_envelope = 'soap:Envelope';
    my $soap_body     = 'soap:Body';
    $xs->$soap_envelope->xml_attr( {
        'xmlns:soap'    => 'http://schemas.xmlsoap.org/soap/envelope/',
        'xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
        'xmlns:xsd'     => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
        'soap:encodingStyle' => 'http://schemas.xmlsoap.org/soap/encoding/',
    } )
    ->$soap_body
    ->foo( [ 0, 'bar', { 'xsi:type' => 'xsd:string' } ] );

    my $xs2 = XML::Simple::Sugar->new;
    $xs2->xml_read('<soap:Envelope soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soap:Body><foo xsi:type="xsd:string">bar</foo></soap:Body></soap:Envelope>');

    is_deeply $xs->xml_data, $xs2->xml_data,
      'Soapish names work as elements';
};

subtest 'String overload' => sub {
    my $xs = XML::Simple::Sugar->new;
    $xs->foo('bar');

    my $xs2 = XML::Simple::Sugar->new( { xml => "$xs" } );
    is_deeply $xs->xml_data, $xs2->xml_data, 'Stringification works';
};

done_testing;
