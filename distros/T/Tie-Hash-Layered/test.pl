# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..28\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Hash::Layered;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my %test1 = ( foo => 'bar', bob => 'sprite' );
my %test2 = ( bob => 'joey');


my %hash;

# test that we can tie it
tie %hash, 'Tie::Hash::Layered', (\%test1, \%test2);
print "ok 2\n";


 
# test that the lowest vaue in the chain works
if ($hash{'foo'} eq 'bar'){
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

# test that higher values override it
if ($hash{'bob'} eq 'joey'){
	print "ok 4\n";
} else {
	print "not ok 4\n";
}

# now test that we can affect the hashes directly
$test1{'quux'} = 'fleeg';

if ($hash{'quux'} eq 'fleeg'){
	print "ok 5\n";
} else {
	print "not ok 5\n";
}

# ... even the higher ones
$test2{'quux'} = 'quirka';

if ($hash{'quux'} eq 'quirka'){
	print "ok 6\n";
} else {
	print "not ok 6\n";
}


# ok now check that we can store
$hash{'mutt'} = 'ley';

# .. and that that value only goes in the upper most hash
if ($hash{'mutt'} eq 'ley')
{
	print "ok 7\n";
} else {
	print "not ok 7\n";
}



# .. and it's associated hash

if ($test2{'mutt'} eq 'ley')
{
	print "ok 8\n";
} else {
	print "not ok 8\n";
}


# .. and not the lower ones

if ($test1{'mutt'} eq 'ley')
{
	print "not ok 9\n";
} else {
	print "ok 9\n";
}


# check DELETE
# .. should return what we would have FETCHed

if ((delete $hash{'quux'}) eq 'quirka')
{
	print "ok 10\n";
} else {
	print "not ok 10\n";
}


# .. that it actually deletes it
if ($hash{'quux'} eq 'fleeg')
{
	print "ok 11\n";
} else {
	print "not ok 11\n";
}

delete $hash{'mutt'};

unless (defined $hash{'mutt'})
{
	print "ok 12\n";
} else {
	print "not ok 12\n";
}

$hash{'quux'} = 'quirka';


# check CLEAR
%hash = ();

if ($hash{'quux'} eq 'fleeg')
{
	print "ok 13\n";
} else {
	print "not ok 13\n";
}



# check EXISTS
# ... first with a key that exists
if (exists $hash{'quux'})
{
	print "ok 14\n";
}else{
	print "not ok 14\n";
}

# .. and one that doesn't
unless (exists $hash{'this was written on a plane'})
{
	print "ok 15\n";
} else {
	print "not ok 15\n";
}


# check FIRSTKEY
if (each(%hash) eq 'foo')
{
	print "ok 16\n";
} else {
	print "not ok 16\n";
}


# now check that we can get each key
# using NEXTKEY

my $test = 17;
# check that all the keys come out
my @keys  = qw(foo quux bob mutt);

$hash{'mutt'} = 'mailer';



foreach my $key (keys %hash) 
{
	if ($key eq shift @keys)
	{
		print "ok ".($test++)."\n";
	} else {
		print "not ok ".($test++)."($key)\n";

	}
}




# and that that works on the specific values


# then check that we can ...
# push
my %test3 = (mutt=>'ley');
tied(%hash)->push(\%test3);

if ($hash{'mutt'} eq 'ley')
{
	print "ok 21\n";	
} else {
	print "not ok 21\n";
}


# pop
tied(%hash)->pop();

if ($hash{'mutt'} eq 'mailer')
{
	print "ok 22\n";	
} else {
	print "not ok 22\n";
}


# unshift
my %test4 = (slub => 'slob');
tied(%hash)->unshift(\%test4);

if ($hash{'slub'} eq 'slob')
{
	print "ok 23\n";	
} else {
	print "not ok 23\n";
}


# shift
tied(%hash)->shift();

unless (defined $hash{'slub'})
{
	print "ok 24\n";	
} else {
	print "not ok 24\n";
}




# more shift 
my $hashref = tied(%hash)->shift();



unless (defined $hash{'bob'})
{
	print "ok 25\n";	
} else {
	print "not ok 25\n";
}

# check to see if the shift worked
if ($hashref->{bob} eq 'sprite')
{
	print "ok 26\n";
} else {
	print "not ok 26\n";
}
my $hashref = tied(%hash)->shift();

# shift some data onto the hash
tied(%hash)->push({mutt=>'mailer'});
tied(%hash)->push({mutt=>'ley'});


# more pop
my $hashref2 = tied(%hash)->pop();

if ($hash{'mutt'} eq 'mailer')
{
	print "ok 27\n";	
} else {
	print "not ok 27\n";
}

# check to see if the shift worked
if ($hashref2->{mutt} eq 'ley')
{
	print "ok 28\n";
} else {
	print "not ok 28\n";

}


exit 0;
