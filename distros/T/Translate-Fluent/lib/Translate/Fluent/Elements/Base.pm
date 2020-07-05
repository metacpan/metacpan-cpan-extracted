package Translate::Fluent::Elements::Base;

use Moo;

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  my %args = ref $args[0] ? %{ $args[0] } : @args;

  for my $k (keys %args) {
    my $val = delete $args{ $k };

    if (ref $val eq 'HASH') {
       
      my $res = Translate::Fluent::Elements->create(
          $k, $val
        );
    
      $val = $res if $res;

    } elsif (ref $val eq 'ARRAY') {
      my @items;
      for my $item ( @$val ) {
        my ($type) = keys %$item;
        my $itemval = ref $item->{$type}
                        ? $item->{$type} 
                        : { text => $item->{$type} };
        my $res = Translate::Fluent::Elements->create(
            $type => $itemval
          );

        push @items, $res ? $res : $item;
      }

      $val = \@items;
    }

    $args{ "\L$k" } = $val;
  }

  return $class->$orig( %args );
};

1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=cut

