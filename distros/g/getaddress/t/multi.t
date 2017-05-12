# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl getaddress.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { use_ok('getaddress') };

use Encode qw(from_to);
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $datafile = './data/QQWry.Dat';

my %address;
open my $ad, '<', 't/address.txt' or die "Can't read the file: $!";
while (my $line = <$ad>) 
{
	$line =~ s/^\s*//; 
	$line =~ s/\s*$//;
	next unless ($line); 
	my ($ip, $address) = split /\t/, $line;
	$address{$ip} = $address; 
}

my $str;
open my $fp, '<', 't/ip.txt' or die "Can't read the file: $!";
while (my $line = <$fp>)
{
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;
	next unless ($line);
	$str = &ipwhere ($line, $datafile);
	from_to($str, "gbk", "utf8");
#	warn "$line\t$str\n";
	is($str, $address{$line}, "multi ip addresses test.");
}
close($fp);

done_testing(698);
