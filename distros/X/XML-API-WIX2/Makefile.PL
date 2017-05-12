use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use Data::Dumper;

# Find the installed location of WiX and update the module.

my $default = "C:\\Program Files\\Windows Installer XML v2\\doc";
print "This module supports the Windows Installer XML verion 2.\n";
print "You must have already installed WiX for this module to work properly.\n";
print "If you have not already done so please download WiX version 2 from:\n";
print "http://wix.sourceforge.net\n";
print "\n";
print "Please enter the directory where the wix.xsd file is located. This is \n";
print "typically the doc directory under the installation location of WiX.\n";
print "\n";
print "Directory [$default]: ";

my $dir = <STDIN>;
my $wix_dir = undef;
chomp $dir;
if ($dir =~ m#^$#)
{
	$wix_dir = $default;
}
else
{
	$wix_dir = $dir;
}
$wix_dir =~ s#\\#/#g;
$wix_dir =~ s#//#/#g;

# Check that the wix.xsd file exists in that directory.
my @files;
if (-d $wix_dir)
{
	opendir (DIR, $wix_dir) or
		die "Error: Cannot open directory \"$wix_dir\" for reading: $!\n";
	@files = grep { m#^wix\.xsd$#i } readdir(DIR);
	closedir DIR;
}

if ($#files != 1)
{
	warn "Warning: wix.xsd not found in passed directory.\n";
	warn "         This module may not work as expected.\n";
}

open (FILE, "<lib/XML/API/WIX2.pm") or
	die "Error: Cannot open \"lib/XML/API/WIX2.pm\" for reading: $!\n";
my @file_data = <FILE>;
close FILE;

# Try and make sure the file is readable 
chmod 0666, "lib/XML/API/WIX2.pm";
open (FILE, ">lib/XML/API/WIX2.pm") or
	die "Error: Cannot open \"lib/XML/API/WIX2.pm\" for writing: $!\n";
foreach my $line (@file_data)
{
	$line =~ s#my \$m_wix_dir = ".*";#my \$m_wix_dir = "$wix_dir";#;
	print FILE $line;
}
close FILE;

WriteMakefile(
	'NAME'		=> 'XML::API::WIX2',
	'VERSION_FROM'	=> 'lib/XML/API/WIX2.pm',
	'AUTHOR'	=> 'R Bernard Davison (rbdavison@cpan.org)',
	'ABSTRACT'	=> 'This module is an extension of XML::API that can be used to create Windows Installer XMl source files.',
	'PREREQ_PM'	=> {
		'XML::API'	=>	'0.09',
		},
);
