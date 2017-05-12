#!/usr/bin/perl

use strict;
use vars qw{$HANDLE};
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More;
use Test::Database;
BEGIN {
	my $handle = (Test::Database->handles('mysql'))[0];
	if ( $handle ) {
		plan( tests => 3 );
	} else {
		plan( skip_all => 'No MySQL connection available' );
	}
}

use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use Xtract ();

# Can we find a test handle?
my $handle = 
# Command row data
my @data = (
	[ 1, 'a', 'one'   ],
	[ 2, 'b', 'two'   ],
	[ 3, 'c', 'three' ],
	[ 4, 'd', 'four'  ],
);

# Locate the output database
my $to = catfile('t', '11_mysql_to');
clear($to, "$to.gz", "$to.bz2", "$to.lz");

# Create the Xtract object
my $object = Xtract->new(
	from  => $ENV{XTRACT_MYSQL_DSN},
	user  => $ENV{XTRACT_MYSQL_USER},
	pass  => $ENV{XTRACT_MYSQL_PASSWORD},
	to    => $to,
	index => 1,
	trace => 0,
	argv  => [ ],
);
isa_ok( $object, 'Xtract' );

# Run the extract
ok( $object->run, '->run ok' );

#is_deeply(
#	$publish->dbh->selectall_arrayref('select * from simple3'),
#	\@data,
#	'simple3 data ok',
#);
