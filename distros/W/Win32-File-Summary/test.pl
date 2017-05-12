# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Win32::File::Summary;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
my $file = $ARGV[0] || 'data\w.doc';
my $STR = Win32::File::Summary->new($file);
my $iscorOS = $STR->IsWin2000OrNT();
my $IsOOoFile = $STR->IsOOoFile();
print "IsOOoFile: $IsOOoFile\n";
print "This OS is the correct one\n";
my $isStgfile = $STR->IsStgFile();
print "The file can contains a storage object. $isStgfile\n";
if($isStgfile) { print "The file can contains a storage object. $isStgfile\n"; }
#my $isNTFS=$STR->IsNTFS();
print "The filesystem is NTFS\n" if $STR->IsNTFS();
my $setoemCDP=1;
$STR->SetOEMCP($setoemCDP);	# 1 if shown in DOS window, 0 for file output
my $result = $STR->Read();
if(ref($result) eq "SCALAR")
{
	my $err = $STR->GetError();
	print "The Error: " . $$err  . "\n";
	exit;
}

my $tt = $STR->_GetTitles();
my @titles = @{ $tt };
print "Titles: " . join(' | ',@titles);
print "\n";

my %hash = %{ $result };
if($setoemCDP == 1) {
	open(FH, ">file.txt");
}
foreach my $key (keys %hash)
{
	if($setoemCDP == 1) {
		print FH "$key=" . $hash{$key} . "\n";
	}
	print "$key=" . $hash{$key} . "\n";
}
if($setoemCDP == 1) {
	close FH;
}