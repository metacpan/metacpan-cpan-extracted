# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Web::Scaffold;
*query2hash = \&Web::Scaffold::query2hash;

do './recurse2txt';	# load Dumper

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub gotexp {
  my($got,$exp) = @_;
  if ($exp =~ /\D/) {
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
  } else {
    print "got: $got, exp: $exp\nnot "
        unless $got == $exp;
  }
  &ok;
}

################################################################
################################################################

$ENV{REQUEST_METHOD}	= '';
$ENV{QUERY_STRING}	= '';
$ENV{CONTENT_LENGTH}	= '';

## test 2	check zero length return
print "non-zero return length\nnot "
	if &query2hash;
&ok;

$ENV{REQUEST_METHOD}	= 'get';

## test 3	check zero length return
print "non-zero return length\nnot "
	if &query2hash;
&ok;

my $query = 'once=upon&a=time&there=were&three=little%20bears';
$ENV{QUERY_STRING}	= $query;

## test 4	check valid query array return
my %exp = (qw(
	once	upon
	a	time
	there	were),
	three	=> 'little bears',
);
my %query = &query2hash;
gotexp(Dumper(\%query),Dumper(\%exp));

$ENV{REQUEST_METHOD}	= 'post';
$ENV{QUERY_STRING}	= '';

## test 5	check zero length return
print "non-zero return length\nnot "
	if &query2hash;
&ok;

## test 6 - 7	read query from STDIN
local *KR;
my $pid = open (KR,'-|');
die "COULD NOT FORK\n" unless defined $pid;
unless ($pid) {	# child
  $| = 1;
  print STDOUT $query;
  exit;
}
$ENV{CONTENT_LENGTH}	= length($query);
%query = ();
local *STDINSAV;
open STDINSAV, "<&STDIN"	|| die "can't save STDIN\n";
open STDIN, "<&KR"		|| die "can't dup KID\n";
%query = &query2hash;
open STDIN, "<&STDINSAV"	|| die "can't restore STDIN\n";

print $@, "\nnot " if $@;
&ok;

gotexp(Dumper(\%query),Dumper(\%exp));
