#!/usr/bin/perl -w
use strict;

use Test::More  tests => 7;
use File::Spec::Functions qw(splitpath);

#----------------------------------------------------------------------------

#01
use_ok 'VCS::Lite::Repository';

my $rep = VCS::Lite::Repository->new('example');

#02
isa_ok($rep, 'VCS::Lite::Repository', "Successful return from new");

my @contents = $rep->traverse( 'name');

#03
is_deeply(\@contents, [qw/mariner.txt scripts/], 'Simple list' );

@contents = $rep->traverse( 'name', recurse => 1);

#04
is_deeply(\@contents, [qw/mariner.txt scripts/, 
		[qw/vldiff.pl vlmerge.pl vlpatch.pl/]], 'Recursive list');

@contents = $rep->traverse( sub { $_[0]->name,$_[0]->latest}, recurse => 1);

#05
is_deeply(\@contents, [
	'mariner.txt' => 3,
	'scripts' => 1,
	[ 'vldiff.pl' => 1,
	  'vlmerge.pl' => 1, 
	  'vlpatch.pl' => 1,
	] ], "User sub, flattened pairs");
	
@contents = $rep->traverse( sub { $_[0]->name, {
		latest => $_[0]->latest,
		store => $_[0]->store,
		param => $_[1]} }, recurse => 1, params => 'foo');

#06
is_deeply(\@contents, [
	'mariner.txt' => {
		latest => 3,
		store => 'VCS::Lite::Store::Storable',
		param => 'foo'},
	'scripts' => {
		latest => 1,
		store => 'VCS::Lite::Store::Storable',
		param => 'foo'},
	[ 'vldiff.pl' => {
		latest => 1,
		store => 'VCS::Lite::Store::Storable',
		param => 'foo'},
	  'vlmerge.pl' => {
	  	latest => 1,
		store => 'VCS::Lite::Store::Storable',
		param => 'foo'},
	  'vlpatch.pl' => {
	  	latest => 1, 
		store => 'VCS::Lite::Store::Storable',
		param => 'foo'},
	] ], "More complex return val, single param");
	
@contents = $rep->traverse( sub { $_[0]->name, {
		latest => $_[0]->latest,
		store => $_[0]->store,
		first => $_[1],
		second => $_[2]} }, recurse => 1, params => [qw/foo bar/]);

#07
is_deeply(\@contents, [
	'mariner.txt' => {
		latest => 3,
		store => 'VCS::Lite::Store::Storable',
		first => 'foo',
		second => 'bar'},
	'scripts' => {
		latest => 1,
		store => 'VCS::Lite::Store::Storable',
		first => 'foo',
		second => 'bar'},
	[ 'vldiff.pl' => {
		latest => 1,
		store => 'VCS::Lite::Store::Storable',
		first => 'foo',
		second => 'bar'},
	  'vlmerge.pl' => {
	  	latest => 1,
		store => 'VCS::Lite::Store::Storable',
		first => 'foo',
		second => 'bar'},
	  'vlpatch.pl' => {
	  	latest => 1, 
		store => 'VCS::Lite::Store::Storable',
		first => 'foo',
		second => 'bar'},
	] ], "More complex return val, multi param");
