#!/usr/bin/env perl

use feature 'say';
use strict;
use warnings;
use Test::More;
use Test::More::UTF8;
use Text::Tradition;
use Text::Tradition::Directory;

my $mysql_connect_info = $ENV{TT_MYSQL_TEST};
plan skip_all => 'Please set TT_MYSQL_TEST to an appropriate db to run this test'
	unless $mysql_connect_info;

my @dbconnect = split( /;/, $mysql_connect_info );
my $dsn = 'dbi:mysql:';
my $user;
my $pass;
foreach my $item ( @dbconnect ) {
	my( $k, $v ) = split( /=/, $item );
	if( $k eq 'user' ) {
		$user = $v;
	} elsif( $k eq 'password' ) {
		$pass = $v;
	} else {
		$dsn .= "$item;";
	}
}

my $dir = Text::Tradition::Directory->new( 'dsn' => $dsn, 
    'extra_args' => { 'user' => $user, 'password' => $pass, 'create' => 1,
	dbi_attrs => { 'mysql_enable_utf8' => 1 } },
    );

my $scope = $dir->new_scope();

my $utf8_t = Text::Tradition->new(
	'input' => 'Self',
	'file'  => 't/data/florilegium_graphml.xml' );
my $uuid = $dir->save( $utf8_t );
foreach my $tinfo( $dir->traditionlist ) {
	next unless $tinfo->{id} eq $uuid;
	like( $tinfo->{name}, qr/\x{3b2}/, "Tradition name encoded correctly" );
}

done_testing();
