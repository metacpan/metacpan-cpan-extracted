#
# $Id: test.pl,v 1.1.1.1 2002/08/01 15:03:59 fhe Exp $
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use YAML::LoadFileCached qw(LoadFileCached CacheStatistics);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

$failed = 0;

open OUT, ">./test.yaml" or die "Could'nt create YAML file: $!\n";
print OUT q~scalar: abcdefg
list:
  - 1
  - 2
  - 3
  - 4
  - 5
~;
close OUT;

# 2: Make sure the file can be read correctly.
$data = LoadFileCached('./test.yaml');
if(($data->{'scalar'} ne 'abcdefg') || (scalar @{$data->{'list'}} != 5))
	{
	print "not ";
	$failed++;
	}

print "ok 2\n";

# 3: Make sure caching works.
for(1 .. 500) 
	{
	$data = LoadFileCached('./test.yaml');
	}

$stat = CacheStatistics('./test.yaml');
if($stat->{'read'} != 1 || $stat->{'cached'} != 500)
	{
	print "not ";
	$failed++;
	}

print "ok 3\n";

#
# Lets give it a rest - or the timestamp of the YAML fil
# will never change ;)
#
sleep 1;

# 4: Make sure, that the rereading-mechanism works.

open OUT, ">./test.yaml" or die "Could'nt create YAML file: $!\n";
print OUT q~scalar: xyz
list:
  - 1
  - 2
~;
close OUT;

for(1 .. 500)
	{
	$data = LoadFileCached('./test.yaml');
	}

$stat = CacheStatistics('./test.yaml');
if($stat->{'read'} != 2 || $stat->{'cached'} != 999 ||
   $data->{'scalar'} ne 'xyz' || (scalar @{$data->{'list'}} != 2))
	{
	print "not ";
	$failed++;
	}

print "ok 4\n";

unlink './test.yaml' or die "Could'nt remove YAML file: $!\n";

exit $failed;
