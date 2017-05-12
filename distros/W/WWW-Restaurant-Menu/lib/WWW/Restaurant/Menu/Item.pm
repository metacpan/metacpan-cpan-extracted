#
# WWW::Restaurant::Menu::Item class
#
# (C) 2004-2005 Julian Mehnle <julian@mehnle.net>
# $Id: Item.pm,v 1.6 2005/01/15 15:48:35 julian Exp $
#
##############################################################################

=head1 NAME

WWW::Restaurant::Menu::Item - A Perl base class for menu items on restaurant
online menus.

=cut

package WWW::Restaurant::Menu::Item;

=head1 VERSION

0.11

=cut

our $VERSION = '0.11';

use warnings;
use strict;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 SYNOPSIS

    use WWW::Restaurant::Menu::Item;
    
    # The following sub-classes are also provided:
    # WWW::Restaurant::Menu::Item::Starter
    # WWW::Restaurant::Menu::Item::Meal
    # WWW::Restaurant::Menu::Item::Dessert
    # WWW::Restaurant::Menu::Item::Drink
    
    # Construction:
    my $item = WWW::Restaurant::Menu::Item[::<Subclass>]->new(
        name        => 'French Fries',
        price       => '1.80'
    );
    
    # Methods:
    my $name        = $item->name;
    my $price       = $item->price;

=head1 DESCRIPTION

This is a Perl base class for menu items on restaurant online menus.

=cut

# Actors:
########################################

sub new;

# Accessors:
########################################

sub name;
sub price;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS WWW::Restaurant::Menu::Item

Creates a new C<WWW::Restaurant::Menu::Item> object.  C<%options> is a list of
key/value pairs representing any of the following options:

=over

=item B<name>

REQUIRED.  A string denoting the name/description of the menu item.

=item B<price>

A unit-less numerical value denoting the price of the menu item.

=item B<currency>

A string denoting the currency of the price.

=back

=cut

sub new {
    my ($class, %options) = @_;
    my $item = bless(\%options, $class);
    return $item;
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<name>: RETURNS SCALAR

Returns a string denoting the name/description of the menu item.

=cut

sub name {
    my ($self) = @_;
    return $self->{name};
}

=item B<price>: RETURNS SCALAR

Returns a unit-less numerical value denoting the price of the menu item.  The
currency is that of the menu containing the item.

=cut

sub price {
    my ($self) = @_;
    return $self->{price};
}

=back

=cut


package WWW::Restaurant::Menu::Item::Starter;
use base qw(WWW::Restaurant::Menu::Item);

package WWW::Restaurant::Menu::Item::Meal;
use base qw(WWW::Restaurant::Menu::Item);

package WWW::Restaurant::Menu::Item::Dessert;
use base qw(WWW::Restaurant::Menu::Item);

package WWW::Restaurant::Menu::Item::Drink;
use base qw(WWW::Restaurant::Menu::Item);


package WWW::Restaurant::Menu::Item;

=head1 SEE ALSO

For COPYRIGHT and LICENSE information, see L<WWW::Restaurant::Menu::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
