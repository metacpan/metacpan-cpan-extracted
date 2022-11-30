package pEFL::Edje::Object;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::PLSide;

our @ISA = qw(Exporter EdjeObjectPtr);

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
XSLoader::load('pEFL::Edje::Object');

sub add {
	my ($class,$evas) = @_;
	my $widget = edje_object_add($evas);
	$widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
	$widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
	return $widget;
}

*new = \&add;

package EdjeObjectPtr;

use Carp;

our @ISA = qw(EvasObjectPtr);

sub signal_callback_add {
	my ($obj,$emission,$source,$func,$data) = @_;
	my $id = undef; $id = pEFL::PLSide::get_signal_id( $obj, $emission, $source, $func);
	
	if (defined($id)) {
		croak "You can only create a single signal with the same emission, source and function. Sorry \n";
	}
	else {
		$id = pEFL::PLSide::save_signal_data( $obj, $emission, $source, $func,$data );
		my $widget = _edje_object_signal_callback_add($obj,$emission,$source,$func,$id);
		return $id;
	}
}

sub signal_callback_del {
	my ($obj,$emission,$source,$func) = @_;
	my $id = pEFL::PLSide::get_signal_id( $obj, $emission, $source, $func);
	my $objaddr = $$obj;
	
	if (defined($id)) {
		my $cstructaddr = $pEFL::PLSide::EdjeSignals{$objaddr}[$id]{cstructaddr};
		my $success = $obj->_edje_object_signal_callback_del($emission,$source, $cstructaddr);
		
		undef $pEFL::PLSide::EdjeSignals{$objaddr}[$id];
	}
	else {
		croak "Deleting signal was not possible. Could not find signal of $obj with \n Emission: $emission \n Source $source \n Function " . pEFL::PLSide::get_func_name($func) . "\n";
	}
}

sub message_handler_set {
	my ($obj,$func,$data) = @_;
	pEFL::PLSide::register_cb($obj,"messageSent",$func,$data);
	$obj->_edje_object_message_handler_set($func);
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Edje::Object

=head1 SYNOPSIS

  use pEFL::Edje;
  [...]
  my $edje_obj = pEFL::Edje::Object->add($parent);
  [...]

=head1 DESCRIPTION

This module is a perl binding to Edje ojects. It contains functions that deal with Edje layouts and its components

For more informations see L<< https://www.enlightenment.org/develop/legacy/api/c/start#group__Edje__Object__Group.html >>

For instructions, how to use pEFL::Edje::Object, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Edje::Object gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "edje_object_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<< https://www.enlightenment.org/develop/legacy/api/c/start#group__Edje__Object__Group.html >>

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
