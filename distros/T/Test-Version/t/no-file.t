#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Version version_ok => { ignore_unindexable => 0 };


dies_ok { version_ok( 'corpus/nofile/nofile.pm' ) }
	'file "corpus/nofile/nofile.pm" does not exist'
	;

done_testing;
