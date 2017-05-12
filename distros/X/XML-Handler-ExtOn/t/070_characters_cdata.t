#use Test::More qw( no_plan);
use Test::More tests=>6;
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

sub create_parser_no_parse {
    my $name = shift;
    my $str1;
    my $w1          = XML::SAX::Writer->new( Output => \$str1 );
    my $psax_filter = $name->new( Handler           => $w1 );
    return $psax_filter, \$str1;
}

my $str;
my ( $filter, $res ) = create_parser_no_parse('MyHandler1');
$filter->start_document;
my $s_elem =
  $filter->mk_element("a")
  ->add_content( $filter->mk_from_xml("<p/>"),
    $filter->mk_cdata(\"00000"), $filter->mk_characters("**"));
$filter->start_element($s_elem);
$filter->start_cdata( );
$filter->characters( { Data => "asdasdad" } );
$filter->end_cdata();
$filter->end_element();
$filter->end_document;
is ( '00000asdasdad', $filter->{CDTAAAA}, 'test cd_data');
is ( '**', $filter->{CHARS}, 'test characters');
#diag $$res;
#diag $filter->{CDTAAAA};
exit;

package MyHandler1;
use base 'XML::Handler::ExtOn';
use strict;
use warnings;

sub on_start_element {
    my ( $self, $elem ) = @_;

    return $elem;
}
sub on_cdata {
    my $self = shift;
    my $elem = shift;
    my $string = shift;
    $self->{CDTAAAA} .= $string;
    return $string
}
sub on_characters {
    my $self = shift;
    my $elem = shift;
    my $string = shift;
    $self->{CHARS} .= $string;
    return $string
    
}

