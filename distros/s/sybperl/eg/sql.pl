#!/usr/local/bin/perl
#
#	@(#)sql.pl	1.2	10/2/95

# Using the special one step query routine sql().

use Sybase::DBlib;

$d = new Sybase::DBlib mpeppler, password;

# sql() returns a 'reference' to an array:
$ref = $d->sql("select * from master..sysprocesses");

foreach $line (@$ref)  # 'de-reference' the pointer
{
    print "@$line\n";
}

# We can also pass a subroutine as the second argument to sql(), and
# it will be called with each row:

sub print_sql {
    print "@_\n";
}

$ref = $d->sql("select * from master..sysprocesses", \&print_sql );

# This time $ref does not point to the results array, because each row
# has been handled by the "callback" proc &print_sql().

# This same call can also be written using an 'anonymous' sub:

$ref = $d->sql("select * from master..sysprocesses", sub { print "@_\n"; } );




