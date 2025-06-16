package pEFL::PLSide;

use strict;
use warnings;

require Exporter;

use pEFL;
use pEFL::Evas;
use Scalar::Util qw(blessed refaddr);
use Carp;

our @ISA = qw(Exporter EvasObjectPtr);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Elm2 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

require XSLoader;
XSLoader::load('pEFL::PLSide');

###################
# General Callbacks (Smart_Cbs, Evas_Events, Tooltip::Content_Cbs)
###################

our %Callbacks;

sub register_smart_cb {
	my ($obj, $event, $func, $data) = @_;

	my $objaddr = $$obj;
	my $funcname = get_func_name($func);
	my $key = "$event###$funcname";

	# Note: We don't save the object itself, becaus we don't want to increase
	# the refcount of the object!!!
	my $pclass = blessed($obj);

	my $func_struct ={	pclass => $pclass,
						function => $func,
						data => $data,
						cstructaddr => ''
	};

	$Callbacks{$objaddr}{$key} = $func_struct;
}

*register_cb = \&register_smart_cb;

sub cleanup {
	my ($widget) = @_;
	my $objaddr = $$widget;
	warn "Cleanup Callbacks of widget with adress $objaddr\n" if ($pEFL::Debug);
	my $cbs = $Callbacks{$objaddr};
	foreach my $key (keys %$cbs) {
	next unless (defined($key));
	warn "Delete callback with key: $key\n" if ($pEFL::Debug);

		# Free the cstruct on C side
		my $cstructaddr = $Callbacks{$objaddr}{$key}{cstructaddr};
		pEFL::PLSide->_free_perl_callback($cstructaddr);

		# Delete the callback on the Perl side
		delete($Callbacks{$objaddr}{$key});
	}
	warn "\n" if ($pEFL::Debug);
}


###################
# Format Callbacks
# There is only one callback per widget
# used by: ElmSlider, ElmProgressbar (and in the future hopefully ElmCalendar :-S)
###################

our %Format_Cbs;

sub register_format_cb {
	my ($obj, $func) = @_;

	#my $objaddr = refaddr($obj);
	my $objaddr = $$obj;
	my $func_struct ={
						function => $func,
						cstructaddr => ''
	};

	$Format_Cbs{$objaddr} = $func_struct;
}

sub cleanup_format_cb {
	my ($widget) = @_;

	#my $objaddr = refaddr($widget);
	my $objaddr = $$widget;
	warn "Cleanup Form Callback with key: $objaddr\n" if ($pEFL::Debug);

	# Free the cstruct on C side
	my $cstructaddr = $Format_Cbs{$objaddr}{cstructaddr};
	warn "TODO: Free c struct at $objaddr (not implemented yet :-S)\n" if ($pEFL::Debug);
	#pEFL::PLSide->_free_perl_callback($cstructaddr);

	# Delete the callback on the Perl side
	warn "Delete \%pEFL::PLSide::Format_Cbs hash value with key $objaddr\n" if ($pEFL::Debug);
	delete($Format_Cbs{$objaddr});
}

#################
# Genlist Item Class
##################

our %GenItc;
our %GenItems;

sub gen_text_get {
	my ($itc, $func) = @_;

	my $itcaddr = $$itc;
	$GenItc{$itcaddr}{'text_get'} = $func;
}

sub gen_content_get {
	my ($itc, $func) = @_;

	my $itcaddr = $$itc;
	$GenItc{$itcaddr}{'content_get'} = $func;
}

sub gen_state_get {
	my ($itc, $func) = @_;

	my $itcaddr = $$itc;
	$GenItc{$itcaddr}{'state_get'} = $func;
}

sub gen_del {
	my ($itc, $func) = @_;

	my $itcaddr = $$itc;
	$GenItc{$itcaddr}{'del'} = $func || sub {};
}

sub save_gen_item_data {
	my ($obj, $data, $func, $func_data) = @_;
	my $objaddr = $$obj;
	# Note: We don't save the object itself, becaus we don't want to increase
	# the refcount of the object!!!
	my $pclass = blessed($obj);

	my $struct = {
		data => $data,
		func => $func,
		func_data => $func_data,
		pclass => $pclass,
		cstructaddr => '',
		signals => [],
	};
	my @items = ();
	if ( $GenItems{$objaddr} ) {
		@items = @{ $GenItems{$objaddr} };
	}
	push @items, $struct;
	
	$GenItems{$objaddr} = \@items;

	return $#items;
}

sub cleanup_genitems {
	my ($widget) = @_;
	
	my $objaddr = $$widget;
	my $raddr = refaddr($widget);
	
	# Workaround:
	# Problem: If we delete $item->cstructaddr, in the "del_cb" call of the GenlistItem (the callback is defined automatically
	# and can be supplemented by a user-defined callback through $itc->del()) the perl_gendata struct cannot not be accessed any more :-( )
	# Solution: If widget is a genlist we have to delete the Genlistitems. Thereby the perl hash and c struct is freed by the del callback
	# of the GenlistItemClass (see call_perl_gen_del in PLSide.c)
	# TODO: Would be this solution possible with other widgets with items (there is call_perl_gen_del also used, if user deletes an item
	# automatically (e.g. Toolbar (done), CtxPopupItem (not possible), IndexItem (done), ListItem (done), HoverselItem (done), MenuItem (done), 
	# PopupItem (not possible), EntryContextMenuItem (done, no del_cb))
	my $pclass = blessed($widget);
	if (	$pclass eq "ElmGenlistPtr" || $pclass eq "pEFL::Elm::Genlist" ||
			$pclass eq "ElmComboboxPtr" || $pclass eq "pEFL::Elm::Combobox" ||
			# CtxPopup doesn't work because in the del_cb data seems not to be defined :-|
			#$pclass eq "ElmCtxpopupPtr" || $pclass eq "pEFL::Elm::Ctxpopup" ||
			$pclass eq "ElmListPtr" || $pclass eq "pEFL::Elm::List" ) {
		warn "Clear GenItems of Genlist/Combobox/List\n" if ($pEFL::Debug); 
		$widget->clear();

	}
	elsif ($pclass eq "ElmIndexPtr" || $pclass eq "pEFL::Elm::Index") {
		warn "Clear GenItems of Index\n" if ($pEFL::Debug);
		$widget->item_clear();
	}
	elsif ($pclass eq "ElmHoverselPtr" || $pclass eq "pEFL::Elm::Hoversel" ||
			$pclass eq "ElmMenuPtr" || $pclass eq "pEFL::Elm::Menu") {
		warn "Delete GenItems of Hoversel/Menu\n" if ($pEFL::Debug);
		my @items = $widget->items_get_pv;
		foreach my $item (@items) {
			$item->del();
		}
	}
	elsif ($pclass eq "ElmToolbarPtr" || $pclass eq "pEFL::Elm::Toolbar") {
		warn "Delete GenItems of Toolbar\n" if ($pEFL::Debug);
		my $item;
		while ($item=$widget->last_item_get()) {
			$item->del();
		}
	}
	# Note: The data passed to $item->pop_cb_set is not (!) passed to 
	#	item_del_cb!!!! Therefore at the moment there is no possibility
	#	to delelte popped items individually :-S
	# TODO: Implement elm_object_item_data_set|get and try it again
	#elsif ($pclass eq "ElmNaviframePtr" || $pclass eq "pEFL::Elm::Naviframe") {
	#	warn "Delete NaviframeItems\n" if ($pEFL::Debug);
	#	my $item;
	#	while ($item=$widget->bottom_item_get()) {
	#		$item->del();
	#	}
	#}
	else {
		warn "Delete GenItems of Popup/Ctxpopup/EntryContextMenu/NaviframeItem\n" if ($pEFL::Debug);
	}
	
	###########################
	# This is only important for ElmPopupItems, ElmCtxpopup, NaviframeItem and perhaps EntryContextMenuItem :-)
	# Anyway, it doesn't hurt to check and possibly (if still exists) delete perl/xs things for safety twice
	###########################
	foreach my $item ( @{ $GenItems{$objaddr} } ) {
		next unless (defined($item));

		# Free the cstruct on C side
		if ($item->{cstructaddr}) {
			warn "Free c struct at $objaddr\n" if ($pEFL::Debug);
			my $cstructaddr = $item->{cstructaddr};
			pEFL::PLSide->_free_perl_gendata($cstructaddr);
		}
	}


	# Delete the callback on the Perl side
	# Really relevant also only for ElmPopupItems,ElmCtxpopupItems and perhaps EntryContextMenuItem
	warn "Delete \%pEFL::PLSide::GenItems hash value(s) with key: $objaddr\n\n" if ($pEFL::Debug);
	delete($GenItems{$objaddr});
}


###################
# Entry - Markup_Filter_Cbs
####################

our %MarkupFilter_Cbs;

sub register_markup_filter_cb {
	my ($obj, $func, $data) = @_;

	my $objaddr = $$obj;
	my $funcname;
	if ($func eq "limit_size" || $func eq "accept_set") {
		$funcname = $func;
	}
	else {
		$funcname = get_func_name($func);
	}

	my $func_struct ={	function => $func,
						data => $data,
						cstructaddr => ''
	};
	$MarkupFilter_Cbs{$objaddr}{$funcname} = $func_struct;
}

sub cleanup_markup_filters {
	my ($widget) = @_;
	my $objaddr = $$widget;
	my $cbs = $MarkupFilter_Cbs{$objaddr};
	foreach my $key (keys %$cbs) {
		next unless (defined($key));
		warn "Delete markup filter callback with key: $key\n" if ($pEFL::Debug);

		# Free the cstruct on C side
		my $cstructaddr = $MarkupFilter_Cbs{$objaddr}{$key}{cstructaddr};
		#TODO
		pEFL::PLSide->_free_perl_callback($cstructaddr);

		# Delete the callback on the Perl side
		delete($MarkupFilter_Cbs{$objaddr}{$key});
	}
}

#######################
# Edje signals
#######################

our %EdjeSignals;

sub save_signal_data {
	my ($obj, $emission, $source, $func, $data) = @_;

	my $objaddr = $$obj;
	my $pclass = blessed($obj);
	my $struct = {
		emission => $emission,
		source => $source,
		data => $data,
		function => $func,
		pclass => $pclass,
	};
	my @signals = ();
	if ( $EdjeSignals{$objaddr} ) {
		@signals = @{ $EdjeSignals{$objaddr} };
	}
	push @signals, $struct;

	$EdjeSignals{$objaddr} = \@signals;
	return $#signals;
}

sub get_signal_id {
	my ( $obj, $emission, $source, $func) = @_;
	my $objaddr = $$obj;
	my $funcname = get_func_name($func);

	my @signals = ();
	@signals = @{ $EdjeSignals{$objaddr} } if ($EdjeSignals{$objaddr});
	my $signal_id = undef;
	my $i = 0;
	foreach my $signal (@signals) {
		next unless (defined($signal));
		my $sfuncname = get_func_name($signal->{function});
		if (($signal->{emission} eq $emission) && ($signal->{source} eq $source) && ($sfuncname eq $funcname) ) {
			$signal_id = $i;
			last;
		}
		$i++;
	}
	return $signal_id;
}

sub cleanup_signals {
	my ($widget) = @_;

	my $objaddr = $$widget;
	print "Cleanup Signals from widget with adress $objaddr\n" if ($pEFL::Debug);

	my $cbs = $EdjeSignals{$objaddr};
	foreach my $key (@$cbs) {
		next unless (defined($key));
		warn "Delete Edje Signal of Layout $widget, \n\tFunction : " . $key->{function} . "\n\tEmission: " . $key->{emission} . "\n\tSource " . $key->{source} .  "\n\n" if ($pEFL::Debug);

		# Free the cstruct on C side
		my $cstructaddr = $key->{cstructaddr};
		pEFL::PLSide->_free_perl_signal_callback($cstructaddr);
	}

	# Delete the callback on the Perl side
	delete($EdjeSignals{$objaddr});

	# TODO: Cleanup item signals if @EdjeSignals{$objaddr###items} exists
	my @item_signals = ();

	if ($EdjeSignals{"$objaddr###items"}) {

		@item_signals = @{ $EdjeSignals{"$objaddr###items"} } ;

		foreach my $signal (@item_signals) {
			next unless (defined($signal));
			warn "Delete Edje Signal of Item of widget with address $signal->{objaddr}, \n\t Function : " . $signal->{function} . "\n\tEmission: " . $signal->{emission} . "\n\tSource " . $signal->{source} .	"\n\n" if ($pEFL::Debug);

			# Free the cstruct on C side
			my $cstructaddr = $signal->{cstructaddr};
			pEFL::PLSide->_free_perl_signal_callback($cstructaddr);
		}

		# Delete the callback on the Perl side
		delete($EdjeSignals{"$objaddr###items"});
	}

}


sub get_item_signal_id {
	my ( $obj, $emission, $source, $func) = @_;
	my $parent = $obj->widget_get();
	my $parentaddr = $$parent;
	my $objaddr = $$obj;
	my $funcname = get_func_name($func);

	my @signals = ();
	@signals = @{ $EdjeSignals{"$objaddr###items"} } if ($EdjeSignals{"$objaddr###items"});
	my $signal_id = undef;
	my $i = 0;
	foreach my $signal (@signals) {
		next unless (defined($signal));
		my $sfuncname = get_func_name($signal->{function});
		if (($signal->{objaddr} == $objaddr ) && ( $signal->{emission} eq $emission) && ($signal->{source} eq $source) && ($sfuncname eq $funcname) ) {
			$signal_id = $i;
			last;
		}
		$i++;
	}
	return $signal_id;
}

sub save_item_signal_data {
	my ($obj, $emission, $source, $func, $data) = @_;

	my $parent = $obj->widget_get();
	my $parentaddr = $$parent;
	my $pclass = blessed($obj);
	my $struct = {
		objaddr => $$obj || 0,
		emission => $emission,
		source => $source,
		data => $data,
		function => $func,
		pclass => $pclass,
	};
	my @signals = ();
	if ( $EdjeSignals{"$parentaddr###items"} ) {
		@signals = @{ $EdjeSignals{"$parentaddr###items"} };
	}
	push @signals, $struct;

	$EdjeSignals{"$parentaddr###items"} = \@signals;
	return $#signals;
}

##############################
# Ecore Evas Event
#############################

our %EcoreEvasEvent_Cbs;

sub register_ecore_evas_event_cb {
	my ($obj, $func,$event) = @_;

	# The key is the object address of the C Ecore_Evas struct, because
	# we don't have a data pointer where we can store the objectaddress of the perl scalar
	# The "IV-Pointeradress" of the C struct is saved in the SV of the referenced scalar
	# TODO: Perhaps it is always useful to use the adress of the C struct???
	my $objaddr = $$obj;
	$EcoreEvasEvent_Cbs{$objaddr}{$event} = $func;
}

# TODO: Add this to a ecore_evas_event (pre_free, destroy, delete_request??)
sub cleanup_ecore_evas_event_cb {
	my ($widget) = @_;

	my $objaddr = $$widget;
	warn "Delete Ecore Evas Event Callbacks with key: $objaddr\n\n" if ($pEFL::Debug);

	# Free the cstruct on C side
	#my $cstructaddr = $Format_Cbs{$objaddr}{cstructaddr};
	#pEFL::PLSide->_free_perl_callback($cstructaddr);

	# Delete the callback on the Perl side
	delete($EcoreEvasEvent_Cbs{$objaddr});
}


##############################
# Ecore EventHandler
#############################

our @EcoreEventHandler_Cbs;

sub register_ecore_event_handler_cb {
	my ($type,$func, $data) = @_;

	my $struct = {	function => $func,
					data => $data,
					type => $type};
	push @EcoreEventHandler_Cbs, $struct;

	return $#EcoreEventHandler_Cbs;

}

##############################
# Ecore Tasks (Timer, idler, poller, animator, etc)
#############################

our @EcoreTask_Cbs;

sub register_ecore_task_cb {
	my ($func, $data) = @_;

	my $struct = {	function => $func,
					data => $data };
	push @EcoreTask_Cbs, $struct;

	return $#EcoreTask_Cbs;

}

# TODO: Passe das an den Array Aufbau an und Add this to a ecore_timer_del etc.
sub cleanup_ecore_task_cb {
	my ($widget) = @_;

	my $objaddr = $$widget;
	warn "Delete Ecore Evas Event Callbacks with key: $objaddr\n\n" if ($pEFL::Debug);

	# Free the cstruct on C side
	#my $cstructaddr = $Format_Cbs{$objaddr}{cstructaddr};
	#pEFL::PLSide->_free_perl_callback($cstructaddr);

	# Delete the callback on the Perl side
	#delete($EcoreTask_Cbs{$objaddr});
}


####################
# SmartClasses
####################

our %SmartClasses;



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::PLSide

=head1 DESCRIPTION

This module contains internal functions that are needed to connect c callbacks with
the passed perl callback functions (as registering perl callback, saving perl callback data in
a hash, freeing perl callback data and freeing the c struct, which saves the data to find the
appropriate perl data ...).

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
