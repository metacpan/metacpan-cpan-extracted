package XML::Overlay::action;

use strict;
use warnings;
use base qw/Class::XML/;

my %act;

__PACKAGE__->has_attributes(qw/type attribute/);

foreach (qw/setAttribute getAttribute removeAttribute/) {
  $act{$_} = 'attr_action';
}

foreach (qw/appendChild/) {
  $act{$_} = 'node_action';
}

foreach (qw/insertBefore insertAfter removeChild/) {
  $act{$_} = 'parent_action';
}

$act{'delete'} = 'delete_self';

sub do {
  my ($self, @target) = @_;
  my $meth = $act{$self->type};
  die "No method found for type ".$self->type unless $meth;
  foreach (@target) {
    $self->$meth($_);
  }
}

sub attr_action {
  my ($self, $target) = @_;
  my $action = $self->type;
  $target->$action($self->attribute, $self->string_value);
}

sub node_action {
  my ($self, $target) = @_;
  my $action = $self->type;
  foreach ($self->getChildNodes) {
    $target->$action($_);
  }
}

sub parent_action {
  my ($self, $target) = @_;
  my $action = $self->type;
  my @add = ($action eq 'insertAfter'
               ? reverse $self->getChildNodes
               : $self->getChildNodes);
  foreach (@add) {
    $target->getParentNode->$action($_,$target);
  }
}

sub delete_self {
  my ($self, $target) = @_;
  $target->getParentNode->removeChild($target);
}

1;
