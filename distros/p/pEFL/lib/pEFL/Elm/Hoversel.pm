package pEFL::Elm::Hoversel;

use strict;
use warnings;

require Exporter;
use pEFL::Elm::Button;
use pEFL::Elm::Object;
use pEFL::Evas;

our @ISA = qw(Exporter ElmHoverselPtr);

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
XSLoader::load('pEFL::Elm::Hoversel');

sub add {
    my ($class,$parent) = @_;
    my $widget = elm_hoversel_add($parent);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_genitems, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}

*new = \&add;

package ElmHoverselPtr;

use pEFL::Eina;
use pEFL::Elm::ObjectItem;

our @ISA = qw(ElmButtonPtr ElmObjectPtr EvasObjectPtr);

sub item_add {
    my ($obj,$label,$icon_file,$icon_type,$func,$data) = @_;
    my $id = pEFL::PLSide::save_gen_item_data( $obj,undef,$func,$data );
    my $widget = _elm_hoversel_item_add($obj,$label,$icon_file,$icon_type,$id);
    return $widget;
}

sub items_get_pv {
    my ($obj) = @_;
    my $list = $obj->items_get();
    my @array = pEFL::Eina::list2array($list,"ElmObjectItemPtr");
    return @array;
}

# Preloaded methods go here.

1;
__END__
=head1 NAME

pEFL::Elm:Hoversel

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $widget = pEFL::Elm::Hoversel->add($parent);
  [...]
  my @items = $widget->items_get_pv(1);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Hoversel widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Hoversel.html 

For instructions, how to use pEFL::Elm::Hoversel, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Hoversel gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_hoversel_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Hoversel.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
