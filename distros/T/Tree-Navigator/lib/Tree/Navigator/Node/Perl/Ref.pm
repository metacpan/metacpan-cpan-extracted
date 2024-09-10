package Tree::Navigator::Node::Perl::Ref;
use utf8;
use Moose;
extends 'Tree::Navigator::Node';

use Scalar::Util     qw/reftype blessed/;
use List::Util       qw/min/;
use Params::Validate qw/validate HASHREF ARRAYREF SCALARREF/;
use namespace::autoclean;

use constant MAX_CHILDREN => 99;

sub MOUNT {
  my ($class, $mount_args) = @_;
  my @mount_point = %{$mount_args->{mount_point} || {}};
  $mount_args->{mount_point} = validate(@mount_point , {
    ref     => {type => HASHREF | ARRAYREF},
    exclude => {type => SCALARREF, isa => 'Regexp', optional => 1},
   });
}


sub _find_ref {
  my $self  = shift;
  my $path = $self->path || "" ;
  my $ref = $self->mount_point->{ref};
  
  foreach my $fragment (split m[/], $path) {
    my $reftype = reftype $ref;
    if ($reftype eq 'ARRAY') {
      $ref = $ref->[$fragment];
    }
    elsif ($reftype eq 'HASH') {
      $ref = $ref->{$fragment};
    }
    elsif ($reftype eq 'SCALAR' || $reftype eq 'REF') {
      $ref = $$ref;
    }
    else {
      die "no such path in data : '$path'";
    }
  }

  return $ref;
}


# inner hashrefs, arrayrefs and scalarrefs are considered 'children';
# other data are considered 'attributes'
sub _ref_is_child {
  my $ref = shift;
  my $reftype = reftype $ref || ''; 
  return $reftype =~ /^(?:HASH|ARRAY|SCALAR|REF)$/;
}


sub _children {
  my $self = shift;
  $self->_find_children_and_attrs;
  return $self->{children};
}

sub _attributes {
  my $self = shift;
  $self->_find_children_and_attrs;
  return $self->{attributes};
}

sub _find_children_and_attrs {
  my $self  = shift;
  my $ref = $self->_find_ref;
  my @children;
  my %attrs;

  my $reftype = reftype $ref;
  if ($reftype eq 'ARRAY') { 
    my @indices = 0 .. min($#$ref, MAX_CHILDREN);
    for my $i (@indices) {
      my $val = $ref->[$i];
      if (_ref_is_child($val)) {
        push @children, $i
      } else {
        $attrs{$i} = $val;
      }
    }
  }
  elsif ($reftype eq 'HASH')  {
    my @keys = keys %$ref;
    my $regex = $self->mount_point->{exclude};
    @keys = grep {$_ !~ $regex} @keys if $regex;
    for my $k (@keys) {
      my $val = $ref->{$k};
      if (_ref_is_child($val)) {
        push @children, $k
      } else {
        $attrs{$k} = $val;
      }
    }
    @children = sort {lc($a) cmp lc($b)} @children;
  }
  elsif ($reftype eq 'SCALAR' || $reftype eq 'REF')  {
    @children = '$';
  }
  my $blessed = blessed $ref;
  $attrs{isa} //= $blessed if $blessed;
  $self->{children}   = \@children;
  $self->{attributes} = \%attrs;
}


sub _child {
  my ($self, $child_path) = @_;
  my $class = ref $self;

  # check if child exists
  my $ref = $self->_find_ref;
  my $child_ok;
  my $reftype = reftype $ref;

  if    ($reftype eq 'ARRAY')                       { $child_ok = exists $ref->[$child_path] }
  elsif ($reftype eq'HASH')                         { $child_ok = exists $ref->{$child_path} }
  elsif ($reftype eq 'SCALAR' || $reftype eq 'REF') { $child_ok = $child_path eq '$'         }

  $child_ok or die "no child '$child_path' in " . $self->full_path;

  return $class->new(
    mount_point => $self->mount_point, 
    path        => $self->_join_path($self->path, $child_path),
   );
}


__PACKAGE__->meta->make_immutable;


1; # End of Tree::Navigator::Node::Perl::Ref


__END__

=encoding utf8

=head1 NAME

Tree::Navigator::Node::Perl::Ref - navigating in a perl datastructure

=cut


