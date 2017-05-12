#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Data::Dumper;

use Gtk2 '-init';
use Xacobeo::GObject;

Xacobeo::GObject->register_package( 'Gtk2::Entry' =>
	properties => [
		Glib::ParamSpec->object(
			'ui-manager',
			'UI Manager',
			"The UI Manager that provides the UI.",
			'Gtk2::UIManager',
			['readable', 'writable'],
		),
	],
);


exit main() unless caller;


sub main {

	my $count = 0;
	

	my $object = __PACKAGE__->new();
	$object->signal_connect('notify::ui-manager', sub {
		++$count;
	});
	is($count, 0);
	
	my $ui1 = Gtk2::UIManager->new();
	my $ui2 = Gtk2::UIManager->new();

	is($object->get_ui_manager, undef, "Property not set yet");
	
	$object->set_ui_manager($ui1);
	is($object->get_ui_manager, $ui1, "Property is set");
	is($object->ui_manager, $ui1, "Property is set");
	is($count, 1);
	
	$object->set_ui_manager($ui2);
	is($object->get_ui_manager, $ui2, "Property is changed");
	is($count, 2);
	
	# Doesn't fire an notify signal
	$object->ui_manager($ui1);
	is($object->get_ui_manager, $ui1, "Property is changed");
	is($object->ui_manager, $ui1, "Property is set");
	is($count, 2);
	return 0;
}
