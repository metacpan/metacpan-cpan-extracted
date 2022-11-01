package pEFL::Elm::Menu;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;

our @ISA = qw(Exporter ElmMenuPtr);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL::Elm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

require XSLoader;
XSLoader::load('pEFL::Elm::Menu');

sub add {
    my ($class,$parent) = @_;
    my $widget = elm_menu_add($parent);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_genitems, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}

*new = \&add;

package ElmMenuPtr;

use pEFL::Eina;
use pEFL::PLSide;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);

sub items_get_pv {
    my ($obj) = @_;
    my $list = $obj->items_get();
    my @array = pEFL::Eina::list2array($list,"ElmMenuItemPtr");
    return @array;
}

sub item_add {
    my ($obj,$parent,$icon,$label,$func,$data) = @_;
    $icon = $icon || "";
    $label = $label || "";
    my $id = pEFL::PLSide::save_gen_item_data( $obj,undef,$func,$data );
    my $widget = _elm_menu_item_add($obj,$parent,$icon,$label,$id);
    return $widget;
}

# Preloaded methods go here.

1;
__END__
=head1 NAME

pEFL::Elm:Menu

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $menu = pEFL::Elm::Menu->add($win);
  $menu->item_add(undef, undef, "first item", \&select, 123);
  my $menu_it = $menu->item_add(undef, "mail-reply-all","second item", undef,undef);
  $menu->item_add($menu_it,"object-rotate-left","menu 1",undef,undef);
  [...]
  my @items = $menu_it->items_get_pv();
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Menu widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Menu.html 

For instructions, how to use pEFL::Elm::Menu, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Menu gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_menu_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Menu.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
