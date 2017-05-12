#!/usr/local/bin/perl
#
#	@(#)ct_sql.pl	1.2	8/7/95

# Using the special one step query routine ct_sql().

use Sybase::CTlib;

$d = new Sybase::CTlib mpeppler, password;

# ct_sql() returns a 'reference' to an array:
$ref = $d->ct_sql("select * from master..sysprocesses");

foreach $line (@$ref)  # 'de-reference' the pointer
{
    print "@$line\n";
}

# We can also pass a subroutine as the second argument to ct_sql(), and
# it will be called with each row:

sub print_sql {
    print "@_\n";
}

$ref = $d->ct_sql("select * from master..sysprocesses", \&print_sql );

# This time $ref does not point to the results array, because each row
# has been handled by the "callback" proc &print_sql().

# This same call can also be written using an 'anonymous' sub:

$ref = $d->ct_sql("select * from master..sysprocesses", sub { print "@_\n"; } );




