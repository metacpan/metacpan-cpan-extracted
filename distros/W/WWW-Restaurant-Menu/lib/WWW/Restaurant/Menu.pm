#
# WWW::Restaurant::Menu class
#
# (C) 2004-2005 Julian Mehnle <julian@mehnle.net>
# $Id: Menu.pm,v 1.6 2005/01/15 15:47:06 julian Exp $
#
##############################################################################

=head1 NAME

WWW::Restaurant::Menu - An abstract Perl base class for querying online menus
of restaurants.

=cut

package WWW::Restaurant::Menu;

=head1 VERSION

0.11

=cut

our $VERSION = '0.11';

use warnings;
use strict;

use UNIVERSAL qw(isa);

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 SYNOPSIS

=head2 Online restaurant menu querying:

    use WWW::Restaurant::Menu;
    
    # Construction:
    my $menu = WWW::Restaurant::Menu->new(%options);
    
    # Get all menu items, in order:
    my @items       = $menu->items;
    
    # Get menu items by class:
    my @starters    = $menu->starters;
    my @meals       = $menu->meals;
    my @desserts    = $menu->desserts;
    my @drinks      = $menu->drinks;
    
    # Get currency of item prices:
    my $currency    = $menu->currency;

=head2 Deriving new restaurant menu classes:

    package WWW::Restaurant::<CC>::<City>::<Restaurant>::Menu[::<Submenu>];
    # CC          ISO 3166 "alpha 2" country code
    #             <http://ftp.ics.uci.edu/pub/ietf/http/related/iso3166.txt>.
    # City        Name of the city where the restaurant is located.
    # Restaurant  Name of the restaurant (unique within that city, if possible).
    # Submenu     A special menu, like "Breakfast", "Lunch", "HappyHour"...

    use base qw(WWW::Restaurant::Menu);
    
    sub currency {
        return "$some_currency";  # Return currency of item prices.
    }
    
    sub query {
        my ($self) = @_;
        # Populate $self->{items} with WWW::Restaurant::Menu::Item objects:
        ...
        return $self->{items};
    }

=head1 DESCRIPTION

This is an abstract Perl base class for querying online menus of restaurants.
It should be sub-classed for functionality specific to restaurants.

=cut

# Actors:
########################################

sub new;

# Methods:
########################################

sub items;
sub starters;
sub meals;
sub desserts;
sub drinks;

sub currency;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS WWW::Restaurant::Menu

Creates a new C<WWW::Restaurant::Menu> object from the given options.  No
options are supported by this base class.

=cut

sub new {
    my ($class, %options) = @_;
    my $menu = bless(\%options, $class);
    return $menu;
}

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<items>: RETURNS (WWW::Restaurant::Menu::Item, ...)

Returns a list of B<WWW::Restaurant::Menu::Item> (or derivative) objects
representing I<all> the items on this menu, in the order they appear on the
menu.

=cut

sub items {
    my ($self) = @_;
    $self->query()
        if not defined($self->{items});
    return @{ $self->{items} };
}

=item B<starters>: RETURNS (WWW::Restaurant::Menu::Item::Starter, ...)

=item B<meals>:    RETURNS (WWW::Restaurant::Menu::Item::Meal, ...)

=item B<desserts>: RETURNS (WWW::Restaurant::Menu::Item::Dessert, ...)

=item B<drinks>:   RETURNS (WWW::Restaurand::Menu::Item::Drink, ...)

Returns a list of objects representing the items of the requested class that
are on this menu, in the order they appear on the menu.

=cut

sub starters {
    my ($self) = @_;
    return grep(isa($_, 'WWW::Restaurant::Menu::Item::Starter'), $self->items);
}

sub meals {
    my ($self) = @_;
    return grep(isa($_, 'WWW::Restaurant::Menu::Item::Meal'), $self->items);
}

sub desserts {
    my ($self) = @_;
    return grep(isa($_, 'WWW::Restaurant::Menu::Item::Dessert'), $self->items);
}

sub drinks {
    my ($self) = @_;
    return grep(isa($_, 'WWW::Restaurant::Menu::Item::Drink'), $self->items);
}

=item B<currency>: RETURNS SCALAR

Returns a string denoting the currency of the item prices on the menu.

=cut

sub currency {
    die("Not implemented, method must be defined in sub-class");
}

=back

=cut

sub query {
    die("Not implemented, method must be defined in sub-class");
}

=head1 SEE ALSO

For COPYRIGHT and LICENSE information, see L<WWW::Restaurant::Menu::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
