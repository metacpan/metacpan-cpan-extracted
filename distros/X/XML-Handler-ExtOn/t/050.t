#use Test::More qw( no_plan);
use Test::More tests=>10;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::Handler::ExtOn';
    use_ok 'XML::Filter::SAX1toSAX2';
    use_ok 'XML::Parser::PerlSAX';
    use_ok 'XML::SAX::Writer';
}

sub create_parser {
    my $name = shift;
    my $xml  = shift;
    my $str1;
    my $w1          = XML::SAX::Writer->new( Output         => \$str1 );
    my $psax_filter = $name->new( Handler                   => $w1 );
    my $sax2_filter = XML::Filter::SAX1toSAX2->new( Handler => $psax_filter );
    my $parser      = XML::Parser::PerlSAX->new( Handler    => $sax2_filter );
    $parser->parse( Source => { String => $xml } );
    return $psax_filter, \$str1;
}

my ( $filter, $res ) = create_parser( 'MyHandler1', <<EOT );
<?xml version="1.0"?>
<Document xmlns="http://test.com/defaultns" xmlns:xlink='http://www.w3.org/1999/xlink'>
    <p var1="1" var2="2"><test_def_ns_uri/>
        <def xmlns="http://debug">
         <a xlink:at2="1" xlink:at1="3" />
        <test_def_ns_uri/>
        </def>
        <def xmlns="">
        <test_def_ns_uri/>
        <attr xlink:var1="1" xlink:var2="3" at1="1" at2="2"/>
        </def>
    </p>
    <test_def_ns_uri/>
    <la op="12" po="eu">ooo</la>
    </Document>
EOT

is_deeply $filter->{__DEF_NAME},
  [
    'http://test.com/defaultns',     'http://debug',
    'http://www.w3.org/2000/xmlns/', 'http://test.com/defaultns'
  ],
  'name space scope';
is_deeply $filter->{__XLINK},
  [
    {
        'at1' => '3',
        'at2' => '1'
    },
    {
        'var1' => '1',
        'var2' => '3'
    }
  ],
  'check prefixes';
#print Dumper $filter->{_by_defaultns};
is_deeply $filter->{_by_defaultns}, [
          {
            'var1' => '1',
            'var2' => '2'
          },
          {
            'op' => '12',
            'po' => 'eu'
          }
        ], 'check attr by default ns_uri';
my ( $filter2, $res2 ) = create_parser( 'MyHandler2', <<EON );
<?xml version="1.0"?>
<root>
    <embed />
    <aa mkd="12">
        <testembd />
    </aa>
    <ext_xml/>
</root>
EON
ok ! $filter2->{testembd_present}, 'test skip_content';
ok $filter2->{ok_present}, 'test mk_element handle';
is $filter2->{_PIC},2,'check elemnts from mk_from_xml';
#diag $$res2;
exit;
package MyHandler1;
use base 'XML::Handler::ExtOn';
sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name eq 'test_def_ns_uri' ) {
        push @{ $self->{__DEF_NAME} }, $elem->default_uri;
    }
    my $attr_by_pref1 = $elem->attrs_by_prefix('xlink');
    if ( keys %{$attr_by_pref1} ) {
        push @{ $self->{__XLINK} }, $attr_by_pref1;
    }
    if ( defined $elem->ns->get_prefix( 'http://test.com/defaultns' ) ) {
    my $attr2 = $elem->attrs_by_ns_uri('http://test.com/defaultns');
    if ( keys %{$attr2} ) {
        push @{ $self->{_by_defaultns} }, $attr2;
    }
    }
    return $elem
}

package MyHandler2;
use warnings;
use strict;
use base 'XML::Handler::ExtOn';

sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name eq 'embed' ) {
        $elem->add_namespace( '', "http://default" );
        $elem->add_content( $self->mk_element("ok") );
    }
    if ( $elem->local_name eq 'aa') {
        $elem->skip_content
    }
    if ( $elem->local_name eq 'testembd') {
        $self->{testembd_present} = 1
    }
    if ( $elem->local_name eq 'ok') {
        $self->{ok_present} = 1
    }
    if ( local_name $elem eq 'ext_xml') {
        $elem->delete_element->skip_content;
        return [ $self->mk_from_xml('<pic />'), $elem]
    
    }
    if ( local_name $elem eq 'pic') {
        $self->{_PIC}++ ;
    }


}
sub on_end_element {
    my ( $self, $elem ) = @_;
        if ( local_name $elem eq 'ext_xml') {
        return  [$elem,$self->mk_from_xml('<pic />')];
    }

}
package MyHandler;
use Data::Dumper;
use strict;
use warnings;
use base 'XML::Handler::ExtOn';

sub on_start_element {
    my ( $self, $elem ) = @_;

    #    warn "defult uri for :". $elem->local_name. " = ". $elem->default_uri;
    if ( $elem->local_name eq 'p' ) {
        $elem->add_namespace( ''    => "http://localhost/doc_com" );
        $elem->add_namespace( 'odd' => 'http://ofddd.com/ns' );
        my $odd = $elem->attrs_by_prefix('odd');
        %$odd = ( odd1 => 1, odd2 => 2 );
    }
    if ( $elem->local_name eq 'a' ) {

        #        $elem->skip_content->delete_element;
        #        $elem->skip_content;
        #        $elem->delete_element;
    }
    if ( $elem->local_name eq 'pe' ) {
        $elem->add_namespace( 'ixo', 'http://ixxxx.com' );
        warn $elem->default_ns_uri;
        my $oxo =
          $elem->mk_element("oxo")
          ->add_content( $self->mk_element('age')->delete_element );
        %{ $oxo->attrs_by_prefix('ixo') } = ( 1 => 11, 2 => 22 );
        $elem->add_content($oxo);
    }
    return $elem;
}

sub on_end_element {
    my $self = shift;
    my ( $elem, $data ) = @_;
    if ( $elem->local_name eq 'a' ) {
        my @res = ();
        @res = ( $self->mk_element('and') );
        return [ $elem, @res, ];
    }
    if ( $elem->local_name eq 'Documents' ) {
        return [ $elem, $self->mk_from_xml(&return_xml) ];
    }
    1

#    warn "End Element:" .Dumper([$elem->set_prefix,$elem->set_ns_uri]);#to_sax2);
#    warn "End Element:data" .Dumper($data);
#    warn "End Element:ns" .Dumper($elem->ns->get_map);
#    warn "End Element:" . Dumper($data, $elem);
}

sub return_xml {
    return <<EOT;
<?xml version="1.0"?>
<Documents xmlns="http://test.com/defaultns" xmlns:nodef='http://zag.ru' xmlns:xlink='http://www.w3.org/1999/xlink'>
    <a href="sdsd">TTT<pe>Ooee</pe></a>test
    <p defaulttest="1" xlink:attr="1" xlink:attr2="1">test</p>
</Documents>
EOT
}

sub on_characters {
    my $self = shift;
    my ( $elem, $str ) = @_;
    $elem->{__chars} .= $str;
    return $str;
}

