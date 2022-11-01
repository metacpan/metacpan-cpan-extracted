package pEFL::Elm::Slider;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;

our @ISA = qw(Exporter ElmSliderPtr);

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
XSLoader::load('pEFL::Elm::Slider');

sub add {
    my ($class,$parent) = @_;
    my $widget = elm_slider_add($parent);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_format_cb, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}

*new = \&add;

package ElmSliderPtr;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);

sub units_format_function_set {
    my ($obj, $func) = @_;
    pEFL::PLSide::register_format_cb( $obj, $func);

    $obj->_elm_slider_units_format_function_set($func);
}

sub indicator_format_function_set {
    my ($obj, $func) = @_;
    pEFL::PLSide::register_format_cb( $obj, $func);

    $obj->_elm_slider_indicator_format_function_set($func);
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Elm:Slider

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $sl = pEFL::Elm::Slider->add($win);
  $sl->size_hint_align_set(EVAS_HINT_FILL,0.5);
  $sl->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
  $sl->indicator_format_function_set(\&indicator_format, undef);
  $bx->pack_end($sl);
  $sl->show();
  [...]
  sub indicator_format {
      my ($val) = @_;
      my $str = "Val is $val";
      return $str;
  }
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Slider widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Slider.html 

For instructions, how to use pEFL::Elm::Slider, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Slider gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_slider_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Slider.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
