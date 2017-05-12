#use Test::More qw( no_plan);

use Test::More tests => 3;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::ExtOn', 'create_pipe';
    use_ok 'XML::ExtOn::Writer';
}

sub create_p {
    my $name = shift;
    my $xml  = shift;
    my %args = @_;
    my $str1;
    my $w1 = XML::ExtOn::Writer->new( Output => \$str1 );
    my $psax_filter = $name->new( %args );
    my $p = create_pipe( 'MyHandler1', $psax_filter, $w1 );
    $p->parse($xml);
    return $psax_filter, $str1;

}

sub create_p1 {
    my $name = shift;
    my $xml  = shift;
    my %args = @_;
    my $str1;
    my $w1 = XML::ExtOn::Writer->new( Output => \$str1 );
    my $psax_filter = $name->new( %args, );
    my $p = create_pipe( $psax_filter, $w1 );
    $p->parse($xml);
    return $psax_filter, $str1;

}

my ( $filter, $res ) = create_p( 'MyHandler2', <<EOT, );
<xml><to_delete><a/></to_delete><elem2></elem2></xml>
EOT

is $filter->{__EXISTS}, 2, 'test intsert_to';

my ( $filter1, $res1 ) = create_p1( 'MyHandler3', <<EOT, );
<xml><wrap><a/></wrap><wrap><a/></wrap></xml>
EOT
package MyHandler1;
use Data::Dumper;
use base 'XML::ExtOn';
use Test::More;

sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name eq 'elem2' ) {
        my $wrapper =
          $self->mk_element("test")->add_content( $self->mk_element("ok") );
        $elem->insert_to($wrapper);
    }
    elsif ( $elem->local_name eq 'to_delete' ) {
        $elem->delete_element;
    }
    return $elem;
}

sub on_end_element {
    my ( $self, $elem ) = @_;
    my $lname = $elem->local_name;
    $elem;
}

package MyHandler2;
use Data::Dumper;
use base 'XML::ExtOn';

sub on_start_element {
    my ( $self, $elem ) = @_;
    if ( $elem->local_name =~ /^ok|test$/ ) {
        $self->{__EXISTS}++;
    }
    return $elem;
}

package MyHandler3;
use Data::Dumper;
use base 'XML::ExtOn';
use Test::More;

sub on_start_element {
    my ( $self, $elem ) = @_;
    my $lname = $elem->local_name;
    if ( $elem->local_name eq 'a' ) {
        return [ $self->mk_start_element( $self->mk_element("B") ), $elem ];
    }
    return $elem;
}

sub on_end_element {
    my ( $self, $elem ) = @_;
    my $lname = $elem->local_name;
    if ( $lname eq 'wrap' ) {
#        diag "Wrap";
        return [  $self->mk_end_element( $self->mk_element("B") ), $elem ];
    }
    return $elem;
}

