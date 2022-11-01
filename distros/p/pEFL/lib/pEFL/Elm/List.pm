package pEFL::Elm::List;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;
use pEFL::Elm::ListItem;

our @ISA = qw(Exporter ElmListPtr);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Elm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

require XSLoader;
XSLoader::load('pEFL::Elm::List');

sub add {
    my ($class,$parent) = @_;
    my $widget = elm_list_add($parent);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_genitems, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}

*new = \&add;

package ElmListPtr;

use pEFL::Eina;
use pEFL::PLSide;

our @ISA = qw(EvasObjectPtr ElmObjectPtr);

sub item_insert_before {
    my ($obj,$before,$label,$icon,$end,$func,$func_data) = @_;
    my $id = pEFL::PLSide::save_gen_item_data( $obj,undef,$func,$func_data );
    my $widget = _elm_list_item_insert_before($obj,$before,$label,$icon,$end, $id);
    return $widget;
}

sub item_insert_after {
    my ($obj,$after,$label,$icon,$end,$func,$func_data) = @_;
    my $id = pEFL::PLSide::save_gen_item_data( $obj,undef,$func,$func_data );
    my $widget = _elm_list_insert_after($obj,$after,$label,$icon,$end,$id);
    return $widget;
}

sub item_prepend {
    my ($obj, $label,$icon,$end,$func,$func_data) = @_;
    my $id = pEFL::PLSide::save_gen_item_data( $obj,undef,$func,$func_data );
    my $widget = _elm_list_item_prepend($obj,$label,$icon,$end,$id);
    return $widget;
}

sub item_append {
    my ($obj,$label,$icon, $end, $func,$func_data) = @_;
    my $id = pEFL::PLSide::save_gen_item_data( $obj,undef,$func,$func_data );
    my $widget = _elm_list_item_append($obj,$label,$icon,$end,$id);
    return $widget;
}

sub items_get_pv {
    my ($obj) = @_;
    my $list = $obj->items_get();
    my @array = pEFL::Eina::list2array($list,"ElmListItem");
    return @array;
}

sub selected_items_get_pv {
    my ($obj) = @_;
    my $list = $obj->selected_items_get();
    my @array = pEFL::Eina::list2array($list,"ElmListItem");
    return @array;
}

# Preloaded methods go here.

1;
__END__
=head1 NAME

pEFL::Elm:List

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $list = pEFL::Elm::List->add($parent);
  $list->resize(320,300);
  $list->mode_set(ELM::LIST_LIMIT);
  $list->item_append("Text item",undef, undef,undef,undef);

  my $icon = pEFL::Elm::Icon->add($list);
  $icon->standard_set("chat");
  $list->item_append("Icon item", $icon, undef,undef,undef);

  my $button = pEFL::Elm::Button->add($list);
  $button->text_set("Button");

  my $itembutton = $list->item_append("Button item", undef, $button, undef,undef);
  $list->go();
  $list->show();
  [...]
  my @items = $list->items_get_pv();
  @items = $list->selected_items_get_pv();
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary List widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__List.html 

For instructions, how to use pEFL::Elm::List, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::List gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_list_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__List.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
