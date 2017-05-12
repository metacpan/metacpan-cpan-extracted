#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Xtract;

# Prepare
my $from = catfile('t', 'data', 'Foo-Bar.sqlite');
my $to   = catfile('t', '02_new_to');
ok( -f $from, 'Found --from file' );
clear($to);
ok( ! -f $to, 'Cleared --to file' );





#####################################################################
# Basic Constructor

my $dsn = "DBI:SQLite:$from";
SCOPE: {
	# Constructor call
	my $object = Xtract->new(
		from  => $dsn,
		user  => '',
		pass  => '',
		to    => $to,
		index => 1,
		argv  => [ ],
	);
	isa_ok( $object, 'Xtract' );
	is( $object->from,  $dsn, '->from ok'  );
	is( $object->user,  '',   '->user ok'  );
	is( $object->pass,  '',   '->pass ok'  );
	is( $object->to,    $to,  '->to ok'    );
	is( $object->index, 1,    '->index ok' );
	is( $object->sqlite_cache, undef, '->sqlite_cache ok' );
	is( ref($object->argv), 'ARRAY', '->argv ok' );
	is( $object->publish, undef, '->publish begins undefined' );
}
