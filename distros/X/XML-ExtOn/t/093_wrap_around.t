#===============================================================================
#
#  DESCRIPTION:  Test wrap around feature
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id: 093_wrap_around.t 845 2010-10-13 08:11:10Z zag $
#use Test::More 'no_plan';    # last test to print

use Test::More tests => 15;    # last test to print
use strict;
use warnings;
use Data::Dumper;
use XML::Flow;

BEGIN {
    use_ok 'XML::ExtOn', 'create_pipe';
    use_ok 'XML::ExtOn::Writer';
}

sub create_p {
    my $name = shift || 'XML::ExtOn';
    my $xml  = shift;
    my %args = @_;
    my $str1;
    my $w1          = XML::ExtOn::Writer->new( Output => \$str1 );
    my $psax_filter = $name->new( %args, );
    my $p           = create_pipe( $psax_filter, $w1 );
    $p->parse($xml);
    return $psax_filter, $str1;

}

sub is_deeply_xml {
    my ( $got, $exp, @params ) = @_;
    unless ( is_deeply xml_ref($got), xml_ref($exp), @params ) {
        diag "got:", "<" x 40;
        diag $got;
        diag "expected:", ">" x 40;
        diag $exp;

    }
}

sub xml_ref {
    my $xml = shift;
    my %tags;

    #collect tags names;
    map { $tags{$_}++ } $xml =~ m/<(\w+)/gis;

    #make handlers
    our $res;
    for ( keys %tags ) {
        my $name = $_;
        $tags{$_} = sub {
            my $attr = shift || {};
            return $res = {
                name    => $name,
                attr    => $attr,
                content => [ grep { ref $_ } @_ ]
            };
          }
    }
    my $rd = new XML::Flow:: \$xml;
    $rd->read( \%tags );
    $res;

}

my $xml1 = '<xml><test_wrap/></xml>';
my ( $f5, $s5 ) = create_p( '', $xml1 );
is_deeply_xml( $s5, $xml1, 'simply parse' );

my ( $f51, $s51 ) = create_p( 'Filter1', '<xml><delete/></xml>' );
is_deeply_xml( $s51, '<xml />', 'delete element' );

my ( $f2, $s2 ) = create_p( 'Filter1', '<xml><skip><a /></skip></xml>' );
is_deeply_xml(
    $s2,
    '<xml><skip /></xml>',
    'check skip content(on_start_element)'
);

#skip content and add after element
my ( $f3, $s3 ) =
  create_p( 'Filter1', '<xml><skip_delete><a /><c /></skip_delete></xml>' );
is_deeply_xml( $s3, '<xml />',
    'check skip content and delete element (on_start_element)' );

#skip content and add after element
my ( $f4, $s4 ) = create_p( 'Filter2', '<xml><before><a/></before></xml>' );
is_deeply_xml( $s4, '<xml><test1/><test/></xml>',
    'skip content and add after element' );

my ( undef, $s04 ) =
  create_p( 'Filter2', '<xml><insert_to>test</insert_to></xml>' );
is_deeply_xml(
    $s04,
    '<xml><around1><around2><insert_to /></around2></around1></xml>',
    'skip text and two insert_to'
);

#skip content and add after element
my ( $f01, $s01 ) =
  create_p( 'Filter2', '<xml1><b><test_from_xml/></b></xml1>' );
is_deeply_xml $s01,
  '<xml1><b><pic_before /><test_from_xml /><pic_after /></b></xml1>',
  'add tags befiore and after from xml';

my ( undef, $s06 ) =
  create_p( 'Filter2', '<xml><over><item_06 /><item_07/></over></xml>' );
is_deeply_xml ($s06, '<xml><over><on><item_06 /><item_07 /></on></over></xml>','mk_start and mk_stop');
my ( $f1, $s1 ) = create_p( 'Filter1', '<xml></xml>' );
my $ex_start =
  $f1->__expand_on_start(
    $f1->mk_element("a")->insert_to( $f1->mk_element("v") )
      ->insert_to( $f1->mk_element('b') ) );
is scalar @$ex_start, 4, 'ex_start: count for 2 insert_to';
is_deeply [ map { ref($_) } @$ex_start ], [ 'HASH', 'HASH', 'HASH', 'HASH' ],
  'ex_start: return array';
is $ex_start->[0]->{type}, 'START_ELEMENT',
  'ex_start: type of insert_to first event';

my $el1 =
  $f1->mk_element("c")
  ->wrap_around( $f1->mk_element("v"), $f1->mk_element("e") );
my $ex_start1 = $f1->__expand_on_start($el1);

is_deeply [
    map {
        ref($_) eq 'HASH'
          ? [ $_->{data}->local_name, $_->{type} ]
          : $_->local_name
      } @$ex_start1
  ],
  [
    [ 'c', 'EV_START_ELEMENT' ],
    [ 'c', 'STACK' ],
    [ 'v', 'START_ELEMENT' ],
    [ 'e', 'START_ELEMENT' ]
  ],
  'ex_start:wrap around start';

my $ex_start2 = $f1->__expand_on_end($el1);
is_deeply [
    map {
        ref($_) eq 'HASH'
          ? [ $_->{data}->local_name, $_->{type} ]
          : $_->local_name
      } @$ex_start2
  ],
  [
    [ 'e', 'END_ELEMENT' ],
    [ 'v', 'END_ELEMENT' ],
    [ 'c', 'STACK' ],
    [ 'c', 'EV_END_ELEMENT' ]
  ],
  'ex_end:wrap around end';

package Filter1;
use base 'XML::ExtOn';

sub on_start_element {
    my $self  = shift;
    my $el    = shift;
    my $lname = $el->local_name;
    if ( $lname eq 'wrap' ) {
        $el->insert_to( $el->mk_element("a") );
    }
    elsif ( $lname eq 'skip' ) {
        $el->skip_content;
    }
    elsif ( $lname eq 'skip_delete' ) {
        $el->skip_content->delete_element;
    }
    elsif ( $lname eq 'delete' ) {
        $el->delete_element;
    }

    $self->{$lname}++;

    $el;
}

package Filter2;
use warnings;
use strict;
use Test::More;
use Data::Dumper;
use base 'XML::ExtOn';

sub on_start_element {
    my $self  = shift;
    my $el    = shift;
    my $lname = $el->local_name;
    if ( $lname eq 'insert_to' ) {
        $el->insert_to( $self->mk_element("around1"),
            $self->mk_element("around2") );
        $el->skip_content();
    }
    elsif ( $lname eq 'test_from_xml' ) {

        #        $el->delete_element->skip_content;
        #        $el->skip_content;

        #        $el->delete_element->skip_content;
        return [ $self->mk_from_xml("<pic_before />"), $el ];

    }
    elsif ( $lname eq 'before' ) {
        $el->delete_element->skip_content;
        return [ $self->mk_element("test1"), $el ];
    }
    elsif ( $lname eq 'test_wrap' ) {
        $el->wrap_around( $el->mk_element("a"), $el->mk_element("b") );

#     diag Dumper [ map { ref($_) eq 'HASH' ? $_->{data}->local_name : $_->local_name }
#      @$el->_wrap_around_start ]
    }
    elsif ( $lname eq 'test_froms_xml' ) {
        $el->skip_content;
    } elsif ( $lname eq 'item_06') {
        return [ $self->mk_start_element( $self->mk_element("on")),$el ]
    }

    $self->{$lname}++;
    $el;
}

sub on_end_element {
    my $self = shift;
    my $el   = shift;

    #    warn Dumper $el;

    die " $self empty stack" . Dumper( [ map { [ caller($_) ] } ( 0 .. 4 ) ] )
      if ref($el) eq 'HASH';

    my $lname = $el->local_name;

    #    warn "aa" . Dumper $el unless $lname;
    #    warn "on_end " . $lname;
    if ( $lname eq 'test_from_xml' ) {
        return [ $el, $self->mk_from_xml("<pic_after />") ];
    }
    elsif ( $lname eq 'before' ) {
        return [ $el, $self->mk_element("test") ];
    } elsif ( $lname eq 'over') {
        return [ $self->mk_end_element( $self->mk_element("on")), $el,  ]
    }
    $el;

}

