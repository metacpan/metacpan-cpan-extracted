package pEFL::Elm::WidgetItem;

use strict;
use warnings;

require Exporter;
use pEFL::Evas::Object;
use pEFL::Elm::Object;

our @ISA = qw(Exporter ElmWidgetItemPtr);

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
XSLoader::load('pEFL::Elm::WidgetItem');

package ElmWidgetItemPtr;

use pEFL::Eina;
use Carp;

our @ISA = qw();

# Preloaded methods go here.

sub access_order_get_pv {
    my ($obj) = @_;
    my $list = $obj->access_order_get();
    my @array = pEFL::Eina::list2array($list,"EvasObjectPtr");
    return @array;
}

sub part_content_get_pv {
	my ($obj,$part) = @_;
	my $content = $obj->part_content_get($part);
	my $class = ElmObjectPtr::widget_type_get($content);
	if ($class =~ /^Elm_/) {
		my $pclass = $class;
		$pclass =~ s/_//g;
		$pclass = $pclass . "Ptr";
		bless($content,$pclass);
	}
	return $content;
}

sub signal_callback_add {
    my ($obj,$emission,$source,$func,$data) = @_;
    my $id = undef; 
    $id = pEFL::PLSide::get_item_signal_id( $obj, $emission, $source, $func);
    
    if (defined($id)) {
        croak "You can only create a single signal with the same emission, source and function. Sorry \n";
    }
    else {
        $id = pEFL::PLSide::save_item_signal_data( $obj, $emission, $source, $func,$data );
        my $widget = _elm_object_item_signal_callback_add($obj,$emission,$source,$func,$id);
        return $id;
    }
}

sub signal_callback_del {
    my ($obj,$emission,$source,$func) = @_;
    my $id = pEFL::PLSide::get_item_signal_id( $obj, $emission, $source, $func);
    my $parent = $obj->widget_get();
    my $parentaddr = $$parent;
    
    if (defined($id)) {
        my $cstructaddr = $pEFL::PLSide::EdjeSignals{"$parentaddr###items"}[$id]{cstructaddr};
        my $success = $obj->_elm_object_signal_callback_del($emission,$source, $cstructaddr);
        
        undef $pEFL::PLSide::EdjeSignals{"$parentaddr###items"}[$id];
    }
    else {
        croak "Deleting signal was not possible. Could not find signal of $obj with \n Emission: $emission \n Source $source \n Function " . pEFL::PLSide::get_func_name($func) . "\n";
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Elm:WidgetItem

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $it->disabled_set(1);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary WidgetItem widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__WidgetItem.html 

For instructions, how to use pEFL::Elm::WidgetItem, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::WidgetItem gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_object_item_" at the beginning of the c functions.

=head1 SPECIFICS OF THE BINDING

There is a special version of $widget_item->content_get() and $widget_item->part_content_get($part) with the name $widget_item->content_get_pv() and $widget_item->part_content_get_pv($part) that try to bless the returned EvasObject to the appropriate perl class. In fact the C class is fetched by ElmObjectPtr::widget_type_get and translated to the PerlClass through deleting underscores and adding "Ptr". It should work with all Elm_*-Widgets for which a perl binding exist. Nevertheless it is not guaranteed to work in all cases.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__WidgetItem.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
