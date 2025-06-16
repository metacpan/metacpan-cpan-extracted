package pEFL::Elm::GenlistItemClass;

use strict;
use warnings;

require Exporter;
use pEFL::Evas::Object;
use pEFL::Elm::Object;
use pEFL::PLSide;

our @ISA = qw(Exporter ElmGenlistItemClassPtr);

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
XSLoader::load('pEFL::Elm::GenlistItemClass');

sub new {
    my ($class) = @_;
    my $widget = elm_genlist_item_class_new();
    #$widget->smart_callback_add("del", \&pEFL::PLSide::cleanup, $widget);
    return $widget;
}

package ElmGenlistItemClassPtr;

#our @ISA = qw(ElmObjectPtr EvasObjectPtr);

sub text_get {
    my ($obj, $func) = @_;

    pEFL::PLSide::gen_text_get($obj,$func);
    $obj->_elm_genlist_item_class_text_get();
}

sub content_get {
    my ($obj, $func) = @_;
	
    pEFL::PLSide::gen_content_get($obj,$func);
    $obj->_elm_genlist_item_class_content_get();
}

sub state_get {
    my ($obj, $func) = @_;

    pEFL::PLSide::gen_state_get($obj,$func);
    $obj->_elm_genlist_item_class_state_get();
}

sub del {
    my ($obj, $func) = @_;

    pEFL::PLSide::gen_del($obj,$func);
    # The del callback was already defined at creation of the GenlistItemClass!!!
    #$obj->_elm_genlist_item_class_state_get();
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Elm:GenlistItemClass

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $list = pEFL::Elm::Genlist->new($win);
  $list->multi_select_set(1);
  my $itc = pEFL::Elm::GenlistItemClass->new();
  $itc->style("default");
  $itc->text_get(\&_text_get);
  $itc->content_get(\&_content_get);
  $itc->del(\&del_cb);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary GenlistItemClass widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__GenlistItemClass.html 

For instructions, how to use pEFL::Elm::GenlistItemClass, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::GenlistItemClass gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_genlist_item_class_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__GenlistItemClass.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
