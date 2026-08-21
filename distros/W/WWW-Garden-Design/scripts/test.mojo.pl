#!/usr/bin/env perl

use feature ':5.10';
use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use WWW::Garden::Design::Database::MojoDriver;

# ----------------------------

my($driver)	= WWW::Garden::Design::Database::MojoDriver -> new;
my($sql)	= 'select * from attribute_types';

say 'arrays(): ';
say map{join(', ', @$_) . "\n"} $driver -> arrays($sql) -> each;
say 'hashes{}: ';
my($item) = $driver -> hashes($sql, 'name') -> each;

my($count) = 0;

for (keys %$item)
{
	say ++$count, ': ', Dumper($_);
}

#say map{join(', ', %$_) . "\n"} @keys;
#say map{join(', ', %$_) . "\n"} $driver -> hashes($sql, 'name') -> each;
