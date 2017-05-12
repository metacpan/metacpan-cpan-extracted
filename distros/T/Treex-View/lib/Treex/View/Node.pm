package Treex::View::Node;
our $AUTHORITY = 'cpan:MICHALS';
$Treex::View::Node::VERSION = '1.0.0';
# ABSTRACT: Wrapper around Treex::Core::Node

use Moose;
BEGIN { $ENV{NO_FS_CLASSES} = 1; }
use Treex::PML::Schema;
use Treex::PML::Instance;
use Treex::Core::TredView;
use Scalar::Util qw(blessed);
use namespace::autoclean;

=head1 NAME

Treex::View::Node - This is L<Treex::Core::Node> wrapper

=head1 SYNOPSIS

   use Treex::View::Node;
   my $root = Treex::View::Node->new( node => $treex_root );

=head1 DESCRIPTION

Wrapper around regular L<Treex::Core::Node> to provide L<TO_JSON>
method used for converting Treex structure to simple Perl hashes and
arrays.

=head1 IMPORTED CONSTANTS

=over 2

=item PML_STRUCTURE_DECL

=item PML_CONTAINER_DECL

=item PML_SEQUENCE_DECL

=item PML_LIST_DECL

=item PML_ALT_DECL

=item PML_CDATA_DECL

=item PML_CHOICE_DECL

=item PML_CONSTANT_DECL

=item PML_ELEMENT_DECL

=back

=head1 METHODS

=cut

has 'node' => ( is => 'ro', isa => 'Treex::Core::Node', required => 1 );

has 'labels' => (
  is  => 'rw',
  isa => 'Treex::Core::TredView::Labels',
);

=head2 traverse_data

Will traverse data and dumps structures to hashes and arrays

=cut

sub traverse_data {
  my ( $self, $decl, $value ) = @_;
  my $data;
  my $decl_is = $decl->get_decl_type;

  if ( $decl_is == PML_STRUCTURE_DECL ) {
    my @members = grep {
            ( !defined( $_->get_role ) or $_->get_role ne '#CHILDNODES' )
        and ( ( $_->get_content_decl && $_->get_content_decl->get_role || '' ) ne '#TREES' )
    } $decl->get_members;
    $data = {};
    for (@members) {
      my $n = $_->get_knit_name;
      my $v = $value->{$n};
      my $d = $_->get_knit_content_decl;
      $data->{$n} = ( defined($v) and !$d->is_atomic ) ? $self->traverse_data( $d, $v ) : $v;
    }
  }
  elsif ( $decl_is == PML_CONTAINER_DECL ) {
    my @attrs = $decl->get_attributes;
    $data = {};
    for (@attrs) {
      my $n = $_->get_name;
      $data->{$n} = $value->{$n};
    }
    my $knit_content_decl = $decl->get_knit_content_decl;
    my $content_decl      = $decl->get_content_decl;
    my $role              = ( $content_decl && $content_decl->get_role ) || '';
    if ( defined($content_decl) and $role ne '#CHILDNODES' and $role ne '#TREES' ) {
      if ( $knit_content_decl and defined( $value->{'#content'} ) ) {
        $data->{'#content'}
          = $knit_content_decl->is_atomic
          ? $value->{'#content'}
          : $self->traverse_data( $knit_content_decl, $value->{'#content'} );
      }
      else {
        $data->{'#content'} = undef;
      }
    }
  }
  elsif ( $decl_is == PML_SEQUENCE_DECL ) {
    my @elems = $decl->get_elements;
    $data = [];
    my $idx = 0;
    my %pos;
    for (@elems) {
      $pos{ $_->get_name } = $idx++;
      push @{$data}, [ $_->get_name, ];
    }
    for ( @{ $value->elements_list } ) {
      my $n = $_->name;
      my $v = $_->value;
      my $e = $decl->get_element_by_name($n);
      my $p = $pos{$n};                         # position

      push @{ $data->[$p] }, $self->traverse_data( $e, $v );
    }
  }
  elsif ( $decl_is == PML_ELEMENT_DECL ) {
    my $content_decl = $decl->get_knit_content_decl;
    my $compact = !defined($value) or $content_decl->is_atomic;
    $data = { '#value' => $compact ? $value : $self->traverse_data( $content_decl, $value ) };
  }
  elsif ( $decl_is == PML_LIST_DECL || $decl_is == PML_ALT_DECL ) {
    if ( $decl_is == PML_ALT_DECL and ( !blessed $value or !$value->isa('Treex::PML::Alt') ) ) {
      $value = Treex::PML::Alt->new($value);
    }
    my $content_decl = $decl->get_knit_content_decl;
    my $atomic       = $content_decl->is_atomic;
    my $ordered      = ( $decl_is == PML_LIST_DECL and $decl->is_ordered );
    my $i            = 0;
    $data = [];
    for my $v ( $value->values ) {
      push @$data,
        {
        '#value' => $atomic ? $v : $self->traverse_data( $content_decl, $v ),
        ( $ordered ? ( '#pos' => $i++ ) : () ),
        };
    }
  }
  elsif ( $decl_is == PML_CHOICE_DECL || $decl_is == PML_CONSTANT_DECL || $decl_is == PML_CDATA_DECL ) {
    confess("Traversing atomic type");
  }
  else {
    die "Unhandled data type: $decl";
  }

  return $data;
}

=head2 TO_JSON

Called by L<JSON> package while converting blessed items

=cut

sub TO_JSON {
  my $self = shift;

  my $n    = $self->node;
  my $data = {
    id    => $n->id,
    depth => int( $n->level ),
    ( $n->does('Treex::Core::Node::Ordered') ? ( order => int( $n->ord ) ) : () ),    # force ord to be integer
    data => $self->traverse_data( $n->type, $n ),
  };

  $n->deserialize_wild;                                                               # We want to see wild :)
  if ( $n->wild ) {
    $data->{data}->{wild_dump} = $n->wild;
  }

  ## some fake values to stop warnings
  $n->{'_shift_down'}  = 0;
  $n->{'_shift_right'} = 0;
  $n->{_tree_depth}    = 0;
  $n->{_depth}         = 0;

  if ( $n->is_root ) {
    $n->{_precomputed_labels} = $self->labels->root_labels($n);
    $n->{_precomputed_hint}   = '';
  }
  else {
    $n->{_precomputed_buffer} = $self->labels->node_labels( $n, $n->get_layer );
    $n->{_precomputed_hint} = Treex::Core::TredView->node_hint( $n, $n->get_layer );
    $self->labels->set_labels($n);
  }
  $data->{labels}   = $n->{_precomputed_labels};
  $data->{hint}     = $n->{_precomputed_hint};
  $data->{parent}   = $n->parent ? $n->parent->id : undef;
  $data->{firstson} = $n->firstson ? $n->firstson->id : undef;
  $data->{rbrother} = $n->rbrother ? $n->rbrother->id : undef;
  $data->{lbrother} = $n->lbrother ? $n->lbrother->id : undef;

  #my @children = $n->is_leaf ? () : (map {__PACKAGE__->new(node=>$_, labels=>$self->labels)} $n->children);
  #$data->{children} = \@children if @children;

  return $data;
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 AUTHOR

Michal Sedlak E<lt>sedlak@ufal.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Michal Sedlak

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
