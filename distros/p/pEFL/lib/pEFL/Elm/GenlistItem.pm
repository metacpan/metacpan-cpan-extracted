package pEFL::Elm::GenlistItem;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::ObjectItem;

our @ISA = qw(Exporter ElmGenlistItemPtr);

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
XSLoader::load('pEFL::Elm::GenlistItem');


package ElmGenlistItemPtr;

use pEFL::Eina;

our @ISA = qw(ElmObjectItemPtr);

# Preloaded methods go here.

sub selected_items_get_pv {
    my ($obj) = @_;
    my $list = $obj->selected_items_get();
    my @array = pEFL::Eina::list2array($list,"ElmGenlistItemPtr");
    return @array;
}

sub subitems_get_pv {
    my ($obj) = @_;
    my $list = $obj->subitems_get();
    my @array = pEFL::Eina::list2array($list,"ElmGenlistItemPtr");
    return @array;
}

1;
__END__

=head1 NAME

pEFL::Elm:GenlistItem

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $widget = pEFL::Elm::GenlistItem->add($parent);
  my $index = $widget->item_index_get();
  my @subitems = $widget->subitems_get_pv();
  my @selected = $widget->selected_items_get_pv();
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary GenlistItem widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__GenlistItem.html 

For instructions, how to use pEFL::Elm::GenlistItem, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::GenlistItem gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_genlist_item_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__GenlistItem.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
