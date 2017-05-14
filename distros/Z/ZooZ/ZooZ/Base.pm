
package ZooZ::Base;

# This package acts as a base package for the following
# classes:
#   ZooZ::Callbacks
#   ZooZ::varRefs
#
# It basically keeps track of which widgets are associated
# with those objects so when we delete something (ex. a callback
# or a variable), we can update the corresponding widget.

use strict;

1;

sub addWidget {
  my ($self, $key, $widget) = @_;

  $self->{WIDGET}{$key} = $widget;
}

sub removeWidget {
  my ($self, $key) = @_;

  my $w = delete $self->{WIDGET}{$key};
  $w    = undef;
}
