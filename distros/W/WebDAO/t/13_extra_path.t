package TestContainer;
use strict;
use warnings;
use WebDAO::Container;
use base 'WebDAO::Container';

1;

package TestTraverse;
use strict;
use warnings;
use WebDAO;
use base 'WebDAO';

sub Test {
    my $self = shift;
    return $self;
}

sub Return1 {
    my $self = shift;
    return 1;
}

sub Index_x {
    my $self = shift;
    return $self;
}

1;

package main;
use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 14;


BEGIN {
    use_ok('WebDAO::SessionSH');
    use_ok('WebDAO::Engine');
    use_ok('WebDAO::Container');
    use_ok('WebDAO::Test');
}

my $ID = "extra";
ok my $session = ( new WebDAO::SessionSH::),
  "Create session";
$session->U_id($ID);

my $eng = new WebDAO::Engine:: session => $session;
our $tlib = new WebDAO::Test eng => $eng;

our $sess = $eng->_session;
our $eng1 = $eng;

$eng->register_class(
    'WebDAO::Container' => 'testmain',
    'TestTraverse'      => 'traverse',
    'TestContainer'     => 'testcont'
);

#test traverse

my $main = $eng->_create_( 'main2', 'testmain' );
$eng->_add_childs_($main);
isa_ok my $trav_obj = $eng->_create_( 'traverse', 'traverse' ),
  'TestTraverse', 'create traverse object';
$main->_add_childs_($trav_obj);
$trav_obj->__extra_path( [ 1, 2, 3 ] );
my $traverse_url = $trav_obj->url_method('Test');
isa_ok $tlib->resolve_path( $traverse_url ), 'TestTraverse',
  "resolve_path1 $traverse_url";
my $traverse_url1 = $trav_obj->url_method();
isa_ok $tlib->resolve_path(  $traverse_url1 ), 'TestTraverse',
  "resolve_path2 $traverse_url1";
isa_ok my $t_cont1 = $eng->_create_( 'test_cont', 'testcont' ),
  'TestContainer', 'test containter';
isa_ok my $comp = $eng->_create_( 'el1', 'traverse' ), 'TestTraverse',
  'create elem';
$t_cont1->_add_childs_($comp);
$eng->_add_childs_($t_cont1);
my $t_url = $comp->url_method('Return1');
is $tlib->resolve_path( $t_url ), 1, "test resolve $t_url";
isa_ok my $comp1 = $eng->_create_( 'el_extra', 'traverse' ), 'TestTraverse',
  'create elem with extra1';
$comp1->__extra_path( [ 'extra1', 'extra2' ] );
$t_cont1->_add_childs_($comp1);
my $t_url2 = $comp1->url_method('Return1');
is $tlib->resolve_path( $t_url2 ), 1, "test resolve $t_url2";
my $t_url3 = $comp1->url_method();
isa_ok $tlib->resolve_path( $t_url3 ), 'TestTraverse',
  "test resolve $t_url3";

