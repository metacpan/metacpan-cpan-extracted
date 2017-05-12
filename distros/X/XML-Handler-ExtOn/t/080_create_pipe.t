#$Id: 080_create_pipe.t 368 2008-11-24 09:55:03Z zag $

#use Test::More qw( no_plan);

use Test::More tests => 4;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::Handler::ExtOn', 'create_pipe';
    use_ok 'XML::SAX::Writer';
}

my $str;
my $w1     = XML::SAX::Writer->new( Output => \$str );
my $h1     = new MyHandler1::;
my $filter = create_pipe( 'MyHandler1', $h1, $w1 );
$filter->parse('<root><p>TEST</p></root>');
is $h1->{CHARS}, 'TEST', 'test create pipe with object';
is $h1->{COUNT}, 2,      'use pipe with filter name';

package MyHandler1;
use base 'XML::Handler::ExtOn';
use strict;
use warnings;

sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name eq 'p' ) {
        $self->{COUNT} = ++$elem->attrs_by_name->{'count'};
    }
    return $elem;
}

sub on_characters {
    my $self   = shift;
    my $elem   = shift;
    my $string = shift;
    $self->{CHARS} .= $string;
    return $string

}

