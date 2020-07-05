package Translate::Fluent::Elements::SelectExpression;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has [qw(inline_expression default_variant)] => (
  is  => 'ro',
  default => sub { undef },
);

has variant_list => (
  is => 'ro',
  default => sub { bless {}, 'Translate::Fluent::Elements::_variantlist' },
);

around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  $args{ inline_expression } = $args{ InlineExpression };
  $args{ default_variant}    = delete $args{ variant_list }{ DefaultVariant };

  $args{ default_variant}->{Identifier}
      = $args{ default_variant }->{VariantKey}->{Identifier};
  delete $args{default_variant}->{VariantKey};

  my %list;
  if ($args{variant_list}->{variant}) {
    for my $variant (@{ $args{variant_list}->{variant} }) {
      $variant = Translate::Fluent::Elements->create(
          Variant => {
            Identifier  => $variant->{VariantKey}->{Identifier},
            Pattern     => $variant->{Pattern},
          }
        );
      $list{ $variant->identifier } = $variant;
    }
  }

  if (%list) {
    $args{ variant_list }
      = bless \%list, 'Translate::Fluent::Elements::_variantlist';
  }

  $class->$orig( %args );
};

sub translate {
  my ($self, $variables) = @_;

  my $selector = $self->inline_expression->translate( $variables );
  
  if (my $var = $self->variant_list->{ $selector }) {
    return $var->translate( $variables );
  } else {
    return $self->default_variant->translate( $variables );
  }

}


package Translate::Fluent::Elements::_variantlist;

1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

this package implements a translate method, but it is not that interesting

=cut

