package WWW::BackpackTF::Listing;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.002001';

sub new{
	my ($class, $content) = @_;
	bless $content, $class
}

sub id         { shift->{id} }
sub currencies { shift->{currencies} }
sub item       { shift->{item} }
sub details    { shift->{details} }
sub bump       { shift->{bump} }
sub created    { shift->{created} }
sub intent     { shift->{intent} }
sub is_selling { shift->intent == 1 }
sub is_buying  { shift->intent == 0 }

1;
__END__

=encoding utf-8

=head1 NAME

WWW::BackpackTF::Listing - Class representing a classified listing

=head1 SYNOPSIS

  use WWW::BackpackTF;
  use Data::Dumper qw/Dumper/;
  use POSIX qw/strftime/;

  my $bp = WWW::BackpackTF->new(key => '...');
  my $steamid = $ARGV[0];
  my @listings = $bp->get_user_listings($steamid);
  my $listing = $listings[0];

  say 'Item: ', Dumper $listing->item;
  say 'The user is selling this item' if $listing->is_selling;
  say 'The user is buying this item'  if $listing->is_buying;
  my %currencies = %{$listing->currencies};
  say 'Price: ', join ' + ', map { "$currencies{$_} $_" } keys %currencies;
  say 'Details: ', $listing->details;
  say 'Created at: ',     strftime '%c', localtime $listing->created;
  say 'Last bumped at: ', strftime '%c', localtime $listing->bump;

=head1 DESCRIPTION

WWW::BackpackTF::Listing is a class representing a classified listing.

=head2 METHODS

=over

=item B<item>

The item being sold, as a hashref. Contains keys like C<defindex> and
C<quality>.

=item B<currencies>

The price of the listing, as a hashref. The keys are the internal
names of the currencies (can be identified using B<get_currencies> in
L<WWW::BackpackTF>) and the values are the amounts.

=item B<details>

The message on the listing

=item B<bump>

UNIX timestamp of when the listing was last bumped.

=item B<created>

UNIX timestamp of when the listing was created.

=item B<id>

The internal ID of the listing.

=item B<is_selling>

True if the user is selling this item.

=item B<is_buying>

True if the user is buying this item.

=item B<intent>

1 if the user is selling the item, 0 if the user is buying.

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
