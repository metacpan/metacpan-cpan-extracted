#$Id: 080_create_pipe.t 845 2010-10-13 08:11:10Z zag $

#use Test::More qw( no_plan);
use Test::More tests => 6;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::ExtOn', 'create_pipe';
    use_ok 'XML::ExtOn::Writer';
}

my $str;
my $w1     = XML::ExtOn::Writer->new( Output => \$str );
my $h1     = new MyHandler1::;

#check paraents 

#exit;
my $filter = create_pipe( 'MyHandler1', $h1, $w1 );
$filter->parse('<root><p>TEST</p></root>');
ok $str, 'is results';
is $h1->{CHARS}, 'TEST', 'test create pipe with object';
is $h1->{COUNT}, 2,      'use pipe with filter name';

my $filter2 = create_pipe( 'MyHandler2', 'MyHandler2', 'MyHandler2' );
my $h2      = new MyHandler1::;
my $filter3 = create_pipe( $filter2, $h2 );
$filter3->parse('<root><p>TEST</p></root>');
is $h2->{COUNT}, 4, 'check pipe';

my $filter4 = create_pipe(   'MyHandler2',  'TestNS' );
$filter4->parse('<root><p>TEST</p></root>');

package TestNS;
use base 'XML::ExtOn';
use strict;
use warnings;
use Data::Dumper;

sub on_start_document {
    my $self = shift;
    $self->SUPER::on_start_document(@_);
    $self->on_start_prefix_mapping( tlink => 'http://zag.ru' );
}

sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name eq 'p' ) {
        my $new_elem = $self->mk_element('name');
        my $attrs    = $new_elem->attrs_by_ns_uri('http://zag.ru');
        $attrs->{1} = 1;

    }
    return $elem;
}

package MyHandler2;
use base 'XML::ExtOn';
use strict;
use warnings;

sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name eq 'p' ) {
        $self->{COUNT} = ++$elem->attrs_by_name->{'count'};
    }
    return $elem;
}
1;

package MyHandler1;
use base 'XML::ExtOn';
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
1;

