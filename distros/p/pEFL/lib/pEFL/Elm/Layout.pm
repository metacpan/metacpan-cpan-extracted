package pEFL::Elm::Layout;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;

our @ISA = qw(Exporter ElmLayoutPtr);

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
XSLoader::load('pEFL::Elm::Layout');

sub add {
    my ($class,$parent) = @_;
    my $widget = elm_layout_add($parent);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}


*new = \&add;

package ElmLayoutPtr;

use pEFL::Eina;
use Carp;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);

# Preloaded methods go here.

sub content_swallow_list_get_pv {
    my ($obj) = @_;
    my $list = $obj->content_swallow_list_get();
    my @array = pEFL::Eina::list2array($list,"String");
    # TODO: Free EinaList (see docs!)
    return @array;
}

sub signal_callback_add {
    my ($obj,$emission,$source,$func,$data) = @_;
    my $objaddr = $$obj;
     
    my $id = undef; $id = pEFL::PLSide::get_signal_id( $obj, $emission, $source, $func);
    
    if (defined($id)) {
        croak "You can only create a single signal with the same emission, source and function. Sorry \n";
    }
    else {
        $id = pEFL::PLSide::save_signal_data( $obj, $emission, $source, $func,$data );
        my $widget = _elm_layout_signal_callback_add($obj,$emission,$source,$func,$id);
        return $id;
    }
}

sub signal_callback_del {
    my ($obj,$emission,$source,$func) = @_;
    my $id = pEFL::PLSide::get_signal_id( $obj, $emission, $source, $func);
    my $objaddr = $$obj;
    
    if (defined($id)) {
        my $cstructaddr = $pEFL::PLSide::EdjeSignals{$objaddr}[$id]{cstructaddr};
        my $success = $obj->_elm_layout_signal_callback_del($emission,$source, $cstructaddr);
        
        undef $pEFL::PLSide::EdjeSignals{$objaddr}[$id];
    }
    else {
        croak "Deleting signal was not possible. Could not find signal of $obj with \n Emission: $emission \n Source $source \n Function " . pEFL::PLSide::get_func_name($func) . "\n";
    }
}

1;
__END__
=head1 NAME

pEFL::Elm:Layout

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $widget = pEFL::Elm::Layout->add($parent);
  my @content_swallows = $widget->content_swallow_list_get_pv(1);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Layout widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Layout.html 

For instructions, how to use pEFL::Elm::Layout, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Layout gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_layout_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Layout.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
