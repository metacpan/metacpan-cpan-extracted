# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Win32::Fonts::Info;
use Data::Dumper;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
my @arr;
my $F = Win32::Fonts::Info->new();
my $chsets = $F->CharSets();
my %chs=%{$chsets};
#sleep(15);
my $sum=0;
#foreach (keys %chs)
#{
#	print "Charset: " . $_ . " = " . $chs{$_} . "\n";
#}

my $ret = $F->EnumFontFamilies($chs{DEFAULT_CHARSET});
@arr = @$ret;
#%chs=%{$ret};
#foreach (keys %chs)
#{
#	print "The Charsets: " . $_ . " = " . $chs{$_} . "\n";
#	$sum+=$chs{$_};
#}
my $truetypefonts = $F->GetTrueTypeFonts();
my $vectorf = $F->GetVectorFonts();
my $rasterf = $F->GetRasterFonts();
#print " " . keys %{$truetypefonts};
my $fontinfo;
$sum=$F->NumberOfFontFamilies();
$fontinfo=$F->GetFontInfoTTF("TestFont");
print "The FontInfo: $fontinfo\n";
if(!$fontinfo)
{
	print "ERROR: " . $F->GetError() . "\n";
}
exit;
foreach (keys %{$truetypefonts})
{
	print $_ . "=" . %{$truetypefonts}->{$_} . "\n";
	$fontinfo=$F->GetFontInfoTTF(%{$truetypefonts}->{$_});
	foreach (keys %{$fontinfo})
	{
		print $_ . " = " . %{$fontinfo}->{$_} . "\n";
	}
	print "\n";
}

foreach (keys %{$vectorf})
{
	print "Vector: " . $_ . "=" . %{$vectorf}->{$_} . "\n";
	#my $fontinfo=$F->GetFontInfo(%{$truetypefonts}->{$_},2,$sum);
	
}
foreach (keys %{$rasterf})
{
	print "Raster: " . $_ . "=" . %{$rasterf}->{$_} . "\n";
	#my $fontinfo=$F->GetFontInfo(%{$truetypefonts}->{$_},2,$sum);
	
}

print "Number of installed Fonts: $sum\n";
