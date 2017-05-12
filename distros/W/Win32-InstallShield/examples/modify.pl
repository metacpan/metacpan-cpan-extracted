#!/usr/bin/env perl
#
# This is an example script for Win32::InstallShield.
# It does not perform any useful function, beyond
# demonstrating usage.
#

use Win32::InstallShield;
use strict;
use warnings;

main();

sub main {
	my $is = Win32::InstallShield->new( 'installer.ism' );

	# the module can perform 3 basic operations on an ism file,
	# add, delete and update. it always operates on a single row
	# at a time. modification functions always return 1 on success
	# and 0 on failure
	
	### ADD ###
	# all of the following function calls are equivilent
	$is->AddProperty('TestProperty', 'TestValue', 'TestComment');
	
	$is->AddProperty({ 
			Property	=>'TestProperty',
			Value		=> 'TestValue',
			ISComments	=> 'TestComment',
	});

	$is->add_property( [ 'TestProperty', 'TestValue', 'TestComment' ] );

	$is->add_row( 'Property', [ 'TestProperty', 'TestValue', 'TestComment' ] );

	### DELETE ###
	# deletes take the same arguments as adds, but only key columns
	# are required. all of the below are equivilent
	$is->DelProperty('TestProperty');

	$is->DelProperty('TestProperty', 'TestValue', 'TestComment');

	### UPDATE ###
	# updates take the same arguments as adds. any columns that
	# are undef will not be modified. key columns CANNOT be modified,
	# you must delete and re-add the row.
	$is->UpdateProperty('TestProperty', 'NewValue');
	$is->UpdateProperty({
		Property	=> 'TestProperty',
		Value		=> 'NewValue',
	});

	# here's how to modify a key column. you can't simply call update,
	# because it uses the key values you supply to lookup the row. be wary
	# of modifying key columns, since you need to then update any foreign
	# keys as well
	my $dialog = $is->getHash_Dialog('AdminWelcome');
	$is->DelDialog('AdminWelcome');
	$dialog->{'Dialog'} = 'AdminTakeOffHoser';
	$is->AddDialog( $dialog );

	# this example demonstrates getting an existing row,
	# and updating one of the values. specifically, it will
	# append the version major number to the product name
	my $version = $is->getHash_Property('ProductVersion');
	my $name = $is->getHash_Property('ProductName');

	my ($major) = ($version->{'Value'} =~ /^(\d+)/);
	
	$name->{'Value'} .= " $major";
	
	$is->UpdateProperty( $name );
	
	### SAVE ###
	# save the modifications that we've made to the same
	# filename that we originally loaded.
	$is->savefile();

	# you can also save to an alternate filename
	$is->savefile( 'modified.ism' );
}
