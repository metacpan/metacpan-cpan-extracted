# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use lib 'lib';
BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::HashDefaults;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my %defaults1 = qw( v1 1 v2 1 );
my %defaults2 = qw( v2 2 v3 2 );
my %defaults3 = qw( v3 3 v4 3 );

my %h;
tie %h, 'Tie::HashDefaults', \%defaults1, \%defaults2, \%defaults3;


# override all fields
$h{'v1'} = 'h';
$h{'v2'} = 'h';
$h{'v3'} = 'h';
$h{'v4'} = 'h';

# add field:
$h{'w'} = 'h';

my $res = '';
for ( sort keys %h ) { $res .= "$_=$h{$_};"; }
$res .= "\n";
%h=();
for ( sort keys %h ) { $res .= "$_=$h{$_};"; }

print
$res eq "v1=h;v2=h;v3=h;v4=h;w=h;\nv1=1;v2=1;v3=2;v4=3;"
? "ok 2\n"
: "not ok 2\n";


