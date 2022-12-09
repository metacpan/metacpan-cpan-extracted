package pEFL::Elm::Theme;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;

our @ISA = qw(Exporter ElmThemePtr);

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
XSLoader::load('pEFL::Elm::Theme');

sub new {
    my ($class) = @_;
    my $widget = elm_theme_new();
    return $widget;
}

sub color_class_list_pv {
    my ($obj) = @_;
    my $list = $obj->color_class_list();
    my @array = pEFL::Eina::list2array($list,"String");
    pEFL::Elm::Theme::color_class_list_free($list);
    return @array;
}

sub name_available_list_new_pv {
    my ($obj) = @_;
    my $list = $obj->name_available_list_new();
    my @array = pEFL::Eina::list2array($list,"String");
    pEFL::Elm::Theme::name_available_list_free($list);
    return @array;
}


package ElmThemePtr;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);

sub color_class_list_pv {
    my ($obj) = @_;
    my $list = $obj->color_class_list();
    my @array = pEFL::Eina::list2array($list,"String");
    pEFL::Elm::Theme::color_class_list_free($list);
    return @array;
}

sub overlay_list_get_pv {
    my ($obj) = @_;
    my $list = $obj->overlay_list_get();
    my @array = pEFL::Eina::list2array($list,"String");
    return @array;
}

sub extension_list_get_pv {
    my ($obj) = @_;
    my $list = $obj->extension_list_get();
    my @array = pEFL::Eina::list2array($list,"String");
    return @array;
}


sub list_get_pv {
    my ($obj) = @_;
    my $list = $obj->list_get();
    my @array = pEFL::Eina::list2array($list,"String");
    return @array;
}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Elm::Theme

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $theme = pEFL::Elm::Theme->new();
  $theme->extension_add(undef,"./theme_button_style_custom.edj");
  my $btn = pEFL::Elm::Button->add($parent);
  $button->style_set("custom");
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Theme widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Theme.html 

For instructions, how to use pEFL::Elm::Theme, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Theme gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_theme_" at the beginning of the c functions.

=head2 SPECIFICS OF THE BINDING

Some Elm_Theme methods can be called as class functions (especially for example C<< pEFL::Elm::Theme::extension_add("./theme_button_style_custom.edj") >> or C<< pEFL::Elm::Theme::overlay_add("./theme_button.edj") >>). In this case the method is called on the default theme. In the original C API the same is possible by passing NULL as theme (e.g. C<< elm_theme_extension_add(NULL,"./theme_button_style_custom.edj") >> or C<< elm_theme_overlay_add(NULL,"./theme_button.edj") >>). In contrast to C in the Perl binding you don't need to pass C<< undef >> when using the class functions!

There are perl value methods C<< $theme->color_class_list_pv() >>, C<< $theme->overlay_list_get_pv() >>, C<< $theme->extension_list_get_pv >>, C<< $theme->list_get_pv >>, C<< pEFL::Elm::Theme::name_available_list_new_pv() >> and C<< pEFL::Elm::Theme::color_class_list_pv() >> that convert the returned Eina_List * to a Perl array (and frees the Eina_List).

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Theme.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
