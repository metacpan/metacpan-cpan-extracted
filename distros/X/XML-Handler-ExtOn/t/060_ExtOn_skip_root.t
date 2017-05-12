#use Test::More qw( no_plan);
use Test::More tests=>6;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::Handler::ExtOn';
    use_ok 'XML::Filter::SAX1toSAX2';
    use_ok 'XML::Parser::PerlSAX';
    use_ok 'XML::Handler::ExtOn::IncXML';
    use_ok 'XML::SAX::Writer';
}

sub create_parser {
    my $name = shift;
    my $xml  = shift;
    my %args = @_;
    my $str1;
    my $w1          = XML::SAX::Writer->new( Output         => \$str1 );
    my $psax_filter = $name->new( %args, Handler                   => $w1 , );
    my $skip_filter = XML::Handler::ExtOn::IncXML->new( Handler => $psax_filter );
    my $sax2_filter = XML::Filter::SAX1toSAX2->new( Handler => $skip_filter );
    my $parser      = XML::Parser::PerlSAX->new( Handler    => $sax2_filter );
    $parser->parse( Source => { String => $xml } );
    return $psax_filter, $str1;
}

my ( $filter, $res ) = create_parser( 'MyHandler1', <<EOT,);
<test_root> <test_root></test_root><elem1/><elem2/></test_root>
EOT
is $filter->{__EXISTS}, 1, 'check skip root';

package MyHandler1;
use Data::Dumper;
use base 'XML::Handler::ExtOn';
sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name eq 'test_root') {
        $self->{__EXISTS}++
    }
    return $elem
}

