
use strict;
use XML::Simple::Tree;
use Test::More tests => 5;

my @exp1 = (
  [ 'sanfrancisco', 0, 'leaf' ],
  [ 'la', 0, 'leaf' ],
  [ 'emily', 0, 'leaf' ],
  [ 'new_years_2003', 0, 'leaf' ],
  [ 'wtc', 0 ],
  [ 'Holiday_party_2001', 1 ],
  [ 'brooklyn_bridge_at_night', 2, 'leaf' ],
  [ 'ed_last_day_at_cheetahmail', 0 ],
  [ 'chicago_and_indiana', 1 ],
  [ 'ed_kesa_wedding', 1, 'leaf' ]
);

my @exp2 = (
  [ 'c', 2, 'leaf' ],
  [ 'b', 1],
  [ 'f', 3],
  [ 'g', 3, 'leaf' ],
  [ 'e', 2 ],
  [ 'i', 3, 'leaf'],
  [ 'h', 2 ],
  [ 'd', 1],
  [ 'a', 0]
);



my $obj1 = XML::Simple::Tree->new(
  file => 't/data/t1.xml', 
  node_key => 'dir',
  target_key => 'name'
);

my @t1;

$obj1->set_do_node(
  sub {
    my $self = shift;

    my $cnode = $self->get_cnode();
    my $target_key = $self->get_target_key();
  
    push (@t1, [$cnode->{$target_key}[0], $self->get_level()]); 
  }
);


$obj1->set_do_leaf(
  sub {
    my $self = $obj1;

#    push (@{$t1[$#t1]}, 'leaf');
    my $pnode = $self->get_pnode();
    my $node_key = $self->get_node_key();

    push (@{$t1[$#t1]}, 'leaf')
      if ($self->get_pos() ==  $#{$pnode->{$node_key}}  or $self->get_level() == 0);
  }
);
$obj1->traverse();

isa_ok($obj1, 'XML::Simple::Tree');

is_deeply(\@t1, \@exp1, 'traverse');

my $obj2 =
    XML::Simple::Tree->new( file => 't/data/base.xml',
                            node_key => 'dir',
                            target_key => 'name'
);

$obj2->set_do_node(
  sub {
    my $self = shift;

    my $cnode = $self->get_cnode();
    my $target_key = $self->get_target_key();

    push (@t1, [$cnode->{$target_key}[0], $self->get_level()]);
  }
);


$obj2->set_do_leaf(
  sub {
    my $self = $obj2;

    my $pnode = $self->get_pnode();
    my $node_key = $self->get_node_key();

    push (@{$t1[$#t1]}, 'leaf')
      if ($self->get_pos() ==  $#{$pnode->{$node_key}} );
  }
);
$obj2->traverse();

isa_ok($obj2, 'XML::Simple::Tree');

my $obj3 = XML::Simple::Tree->new(
  file => 't/data/t4.xml',
  node_key => 'dir',
  target_key => 'name'
);

my @t2;

$obj3->set_do_node(
  sub {
    my $self = shift;

    my $cnode = $self->get_cnode();
    my $target_key = $self->get_target_key();

    push (@t2, [$cnode->{$target_key}[0], $self->get_level()]);
  }
);


$obj3->set_do_leaf(
  sub {
    my $self = $obj3;

    my $pnode = $self->get_pnode();
    my $node_key = $self->get_node_key();

    push (@{$t2[$#t2]}, 'leaf')
      if ($self->get_pos() ==  $#{$pnode->{$node_key}} );
  }
);
$obj3->post_traversal();

isa_ok($obj3, 'XML::Simple::Tree');

is_deeply(\@t2, \@exp2, 'traverse');

