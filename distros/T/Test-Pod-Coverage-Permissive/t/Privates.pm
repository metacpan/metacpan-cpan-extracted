package Privates;

sub foo {}
sub bar {}
sub baz {}
sub INTERNAL_THING {}
sub INTERNAL_DOODAD {}

1;
__END__

# test module - three subs, one without, one with an item, one with a head2

=head2 Methods

=over

=item foo

this is foo

=back

=head2 bar

The bar is just a throwaway.

=head2 baz

baz is very important

=cut

