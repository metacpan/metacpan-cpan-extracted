package WWW::BackpackTF::MarketItem;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.002001';

sub new{
	my ($class, $name, $content) = @_;
	$content->{name} = $name;
	bless $content, $class
}

sub name         { shift->{name} }
sub last_updated { shift->{last_updated} }
sub quantity     { shift->{quantity} }
sub value        { shift->{value} }

1;
__END__

=encoding utf-8

=head1 NAME

WWW::BackpackTF::MarketItem - Class representing market item information

=head1 SYNOPSIS

  use WWW::BackpackTF;
  use Data::Dumper qw/Dumper/;
  use POSIX qw/strftime/;

  my $bp = WWW::BackpackTF->new(key => '...');
  my @items = $bp->get_market_prices;
  my $item = $items[0];
  say 'Name: ', $item->name;
  say strftime 'Last updated on: %c', localtime $item->last_updated;
  say 'Quantity available on market: ', $item->quantity;
  say 'Value of item: $', sprintf '%.2f', $item->value / 100;

=head1 DESCRIPTION

WWW::BackpackTF::MarketItem is a class representing Steam Community
Market price information about an item.

=head2 METHODS

=over

=item B<name>

The name of the item.

=item B<last_updated>

The timestamp of this information, as seconds since unix epoch.

=item B<quantity>

How many items of this kind are there on the SCM.

=item B<value>

The price this item is selling for, in cents (USD 0.01).

=back

=head1 SEE ALSO

L<http://backpack.tf/api/docs/IGetMarketPrices>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
