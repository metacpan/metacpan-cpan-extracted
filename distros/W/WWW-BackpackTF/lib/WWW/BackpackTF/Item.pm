package WWW::BackpackTF::Item;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.002001';

sub new{
	my ($class, $name, $content) = @_;
	$content->{name} = $name;
	bless $content, $class
}

sub name       { shift->{name} }
sub defindex   { wantarray ? @{shift->{defindex}} : shift->{defindex}->[0] }
sub price {
	my ($self, $quality, $tradable, $craftable, $priceindex) = (@_, 6, 1, 1);
	$tradable = $tradable ? 'Tradable' : 'Non-Tradable';
	$craftable = $craftable ? 'Craftable' : 'Non-Craftable';
	my $price = shift->{prices}->{$quality}->{$tradable}->{$craftable};
	defined $priceindex ? $price->{$priceindex} : $price->[0]
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::BackpackTF::Item - Class representing item information

=head1 SYNOPSIS

  use WWW::BackpackTF qw/VINTAGE GENUINE UNUSUAL/;
  use Data::Dumper qw/Dumper/;

  my $bp = WWW::BackpackTF->new(key => '...');
  my @items = $bp->get_prices;
  my $item = $items[0];
  say 'Name: ', $item->name;
  say 'Linked defindexes: ', join ' ', $item->defindex;
  say 'Price of Unique, Tradable, Craftable version: ', $item->price;
  say 'Price of Vintage, Tradable, Craftable version: ',                Dumper $item->price(VINTAGE);
  say 'Price of Vintage, Non-Tradable, Craftable version: ',            Dumper $item->price(VINTAGE, 0);
  say 'Price of Genuine, Non-Tradable, Non-Craftable version: ',        Dumper $item->price(GENUINE, 0, 0);
  say 'Price of Unusual, Tradable, Craftable version with effect 10: ', Dumper $item->price(UNUSUAL, 1, 1, 10);

=head1 DESCRIPTION

WWW::BackpackTF::Item is a class representing price information about an item.

=head2 METHODS

=over

=item B<name>

The name of the item.

=item B<defindex>

In list context, a list of defindexes linked to the item. In scalar context, the first such defindex.

=item B<price>([I<$quality>, [I<$tradable>, [I<$craftable>, [I<$priceindex>]]]])

The price of an item. Takes four optional arguments: the quality (defaults to 6, which is Unique), the tradability of the item (defaults to true), the craftability of an item (defaults to true), and the priceindex (crate series/unusual effect, defaults to none).

Returns an hashref with the following keys/values:

=over

=item B<currency>

The currency the item's price is in.

=item B<value>

The price.

=item B<value_high>

If present, the upper range of the price range.

=item B<value_raw>

The price in the lowest currency, without rounding. Only present if get_prices was called with a true value for $raw.

=item B<last_update>

Timestamp of last price update.

=item B<difference>

The difference bitween the former price and the current price. 0 if the current price is new.

=back

=back

=head1 SEE ALSO

L<http://backpack.tf/api/IGetPrices>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
