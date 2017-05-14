#!/usr/local/bin/perl

#----------------------------------------------------------------------
# Edit the lines below to customise
#----------------------------------------------------------------------

# Where the main files are stored
$libDir = "/usr/local/lib/xisofs";

# Where the main binary is sym-linked to
$binDir = "/usr/local/bin";

# Where the perl executable is, leave blank for PATH
$perlPath = "";

#----------------------------------------------------------------------
# Nothing below here should need changing
#----------------------------------------------------------------------

($who) = getpwuid($>);

if ($who ne 'root')
{
	print "You need to be 'root' to run this script, not '$who'\n";
	exit 1;
}

if ($perlPath eq '')
{
	chomp($perlPath = `which perl`);
	unless (-e $perlPath)
	{
		print "Cannot find perl executable on PATH, either set PATH to point to perl\nexecutable, or edit this script and alter the \$perlPath variable\n";
		exit 1;
	}
}

print <<EOT;

xisofs v1.3 Installation Script
(c) Copyright 1997 Steve Sherwood

Library Dir      : $libDir
Executable Dir   : $binDir
Perl Executable  : $perlPath
EOT

if (-d $libDir)
{
	if (-r "$libDir/VERSION")
	{
		open(IN,"$libDir/VERSION");
		$_ = <IN>;
		close(IN);

		if (/^xisofs/)
		{
			print "Previous Version : $_\n";
		}
		else
		{
			print "\nWARNING : $libDir exists, but does not contain a\n          recognised version of xisofs\n";
		}
	}
	else
	{
		print "\nWARNING : $libDir exists, but does not contain a\n          recognised version of xisofs\n"
	}
}

print "\nAre you sure you wish to install (y/n) ? ";
$_ = <STDIN>;

unless (/^y/)
{
	print "\nInstallation Aborted\n";
	exit 1;
}

foreach ($libDir,$binDir)
{
	unless (-d $_)
	{
		print "Creating Dir : $_\n";
		system("mkdir -p $_");
	}
}

print "Copying System Files\n";
system("cp -r * $libDir");

print "Sym-Linking\n";
unlink("$binDir/xisofs") if (-e "$binDir/xisofs");
system("ln -s $libDir/xisofs.pl $binDir/xisofs");

print "Updating\n";
open(IO, "+<$libDir/xisofs.pl");
@lines = <IO>;
seek(IO,0,0);
foreach(@lines)
{
	s/xyzzy/$libDir/g;
	s/yyzzy/$perlPath/g;
	print IO $_;
}
close(IO);

print "\nInstallation Complete. type 'xisofs' to start.\n";
exit;
