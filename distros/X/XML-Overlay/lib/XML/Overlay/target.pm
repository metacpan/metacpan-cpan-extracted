package XML::Overlay::target;

use strict;
use warnings;

use base qw/Class::XML/;

__PACKAGE__->has_attributes(qw/xpath/);
__PACKAGE__->has_children('action' => 'XML::Overlay::action');

sub action_closure {
  my ($self, $context) = @_;
  my @targets = $context->findnodes($self->xpath);
  return sub { } unless @targets;
  return
    sub {
      foreach ($self->action) {
        $_->do(@targets);
      }
    };
}

1;
