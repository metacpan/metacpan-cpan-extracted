package pEFL::Ecore::Evas;

use strict;
use warnings;

require Exporter;

use pEFL::Evas::Canvas;
#use pEFL::Evas::Object;

our @ISA = qw(Exporter EcoreEvasPtr);

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
XSLoader::load('pEFL::Ecore::Evas');

sub new {
	my ($class, $engine_name,$x,$y,$w,$h,$extra_options) = @_;
	my $ee = ecore_evas_new($engine_name,$x,$y,$w,$h,$extra_options);
	return $ee;
}


sub sdl_new {
	my ($class, $name,$w,$h,$fullscreen,$hwsurface,$noframe,$alpha) = @_;
	my $ee = ecore_evas_sdl_new($name,$w,$h,$fullscreen,$hwsurface,$noframe,$alpha);
	return $ee;
}


sub gl_sdl_new {
	my ($class, $name,$w,$h,$fullscreen, $noframe) = @_;
	my $ee = ecore_evas_gl_sdl_new($name,$w,$h,$fullscreen,$noframe);
	return $ee;
}


sub evas_fb_new {
	my ($class, $disp_name, $rotation, $w, $h) = @_;
	my $ee = ecore_evas_fb_new($disp_name,$rotation,$w,$h);
	return $ee;
}


sub wayland_shm_new {
	my ($class, $disp_name,$parent,$x,$y,$w,$h,$frame) = @_;
	my $ee = ecore_evas_wayland_shm_new($disp_name,$parent,$x,$y,$w,$h,$frame);
	return $ee;
}


sub wayland_egl_new {
	my ($class, $disp_name,$parent,$x,$y,$w,$h,$frame) = @_;
	my $ee = ecore_evas_wayland_egl_new($disp_name,$parent,$x,$y,$w,$h,$frame);
	return $ee;
}


sub drm_new {
	my ($class, $device,$parent,$x,$y,$w,$h) = @_;
	my $ee = ecore_evas_drm_new($device,$parent,$x,$y,$w,$h);
	return $ee;
}


sub gl_drm_new {
	my ($class, $device, $parent, $x, $y, $w, $h) = @_;
	my $ee = ecore_evas_gl_drm_new($device,$parent,$x,$y,$w,$h);
	return $ee;
}


sub  buffer_new {
	my ($class, $w, $h) = @_;
	my $ee = ecore_evas_buffer_new($w,$h);
	return $ee;
}


sub ews_new {
	my ($class, $x, $y, $w, $h) = @_;
	my $ee = ecore_evas_ews_new($x,$y,$w,$h);
	return $ee;
}

sub extn_socket_new {
	my ($class, $w, $h) = @_;
	my $ee = ecore_evas_extn_socket_new($w,$h);
	return $ee;
}

# sub add {
#     my ($class,$parent) = @_;
#     my $widget = evas_object_line_add($parent);
#     $widget->smart_callback_add("del", \&pEFL::PLSide::cleanup, $widget);
#     return $widget;
# }
# 
# *new = \&add;

package EcoreEvasPtr;

use pEFL::PLSide;

our @ISA = qw();

sub callback_resize_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "resize");
    $ee->_ecore_evas_callback_resize_set($func);
}

sub callback_move_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "move");
    $ee->_ecore_evas_callback_move_set($func);
}

sub callback_show_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "show");
    $ee->_ecore_evas_callback_show_set($func);
}

sub callback_hide_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "hide");
    $ee->_ecore_evas_callback_hide_set($func);
}

sub callback_delete_request_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "delete_request");
    $ee->_ecore_evas_callback_delete_request_set($func);
}

sub callback_destroy_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "destroy");
    $ee->_ecore_evas_callback_destroy_set($func);
}

sub callback_focus_in_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "focus_in");
    $ee->_ecore_evas_callback_focus_in_set($func);
}

sub callback_focus_out_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "focus_out");
    $ee->_ecore_evas_callback_focus_out_set($func);
}

sub callback_sticky_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "sticky");
    $ee->_ecore_evas_callback_sticky_set($func);
}

sub callback_unsticky_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "unsticky");
    $ee->_ecore_evas_callback_unsticky_set($func);
}

sub callback_mouse_in_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "mouse_in");
    $ee->_ecore_evas_callback_mouse_in_set($func);
}

sub callback_mouse_out_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "mouse_out");
    $ee->_ecore_evas_callback_mouse_out_set($func);
}

sub callback_pre_render_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "pre_render");
    $ee->_ecore_evas_callback_pre_render_set($func);
}

sub callback_post_render_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "post_render");
    $ee->_ecore_evas_callback_post_render_set($func);
}

sub callback_pre_free_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "pre_free");
    $ee->_ecore_evas_callback_pre_free_set($func);
}

sub callback_state_change_set {
    my ($ee,$func) = @_;
    pEFL::PLSide::register_ecore_evas_event_cb( $ee, $func, "state_change");
    $ee->_ecore_evas_callback_state_change_set($func);
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Ecore::Evas

=head1 DESCRIPTION

This module is a perl binding to the Ecore Evas wrapper.

Ecore Evas is a set of functions that make it easy to tie togethers ecore's
main loop and input handling to evas.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Ecore__Evas__Group.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
