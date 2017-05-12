#!/usr/bin/perl

# gxml2html: generic, template-based XML to HTML conversion tool
# version 2.2
# Copyright (C) 1999-2001 Josh Carter <josh@multipart-mixed.com>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

#
# Global vars
#
use vars ('$gxml',
		  '%config',
		  '%remappings',
		  '%modtimes',
		  '$baseDir',
		  '$workDir',
		  '$finalDir',
		  '$templateDir',
		  '$templatesChanged',
		  '$currentFile',
		  '$output',
		  '$debugMode',
		  );

# Stuff that comes with Perl and/or CPAN
use strict;
use Cwd;
use Getopt::Long;
use File::Copy;
use XML::GXML; # of course

$baseDir = cwd();

#
# Figure out our configuration
#
%config = ReadConfig();

#
# Create new GXML object
#
$gxml = new XML::GXML(\%config);

#
# Check template mod times
#
$templatesChanged = $gxml->TemplateMgr()->CheckModified();
$gxml->TemplateMgr()->UpdateModified();

#
# Assemble the list of files to process
#
$baseDir = cwd();
chdir($workDir);
my $fileListRef = XML::GXML::Util::GetFileList();
chdir($baseDir);

#
# Itererate over the file list and format/copy 
# each item as appropriate.
#
foreach my $filename (@$fileListRef)
{
	chdir($baseDir);

	$currentFile = $filename;

	my $source    = File::Spec->catfile($workDir, $filename);
	my $dest      = File::Spec->catfile($finalDir, $filename);
	my $sourcemod = (stat $source)[9];
	my $changed;

	# If the destination file exists and the source file hasn't been
	# modified since the last time we were run, skip the file. BUT, if
	# a template changed, we want to still processes all .xml files.
	if ((-f $dest) && (defined($modtimes{$filename})) && 
		($sourcemod == $modtimes{$filename}))
	{
		$changed = 0;
	}
	else
	{
		$changed = 1;
		$modtimes{$filename} = $sourcemod;
	}

	if ($filename =~ /\.xml$/)
	{
		(my $htmldest = $dest) =~ s/\.xml$/\.html/;
		next unless (!-f $htmldest || $changed || $templatesChanged);

		print "processing XML file $filename...\n";
		
		$gxml->ProcessFile($source, $htmldest);

		# also copy the XML source in case someone wants it.
		HandleSomeOtherFile($source, $dest);
	}
	else
	{
		next unless $changed;

		print "copying file $filename...\n";
		
		HandleSomeOtherFile($source, $dest);
	}
}

# Now flush the mod times back out to the .modtimes file.
XML::GXML::Util::SaveModtimes(File::Spec->catfile($workDir, '.modtimes'), \%modtimes);

print "\nall done!\n\n";


#######################################################################
# END OF MAIN; subroutines from here down
#######################################################################


#
# HandleSomeOtherFile
#
# Just copy the file verbatim to the result directory.
#
sub HandleSomeOtherFile
{
	my ($source, $dest) = @_;

	# Change to dest directory and back to create 
	# any necessary directories...
	XML::GXML::Util::ChangeToDirectory($dest);
	
	chdir($baseDir);

	# Achtung! If the source and dest directories are the same, we do
	# *not* want to copy a file onto itself. File::Copy will blow away
	# the file in question. That would be a Very Bad Thing(tm).
	#
	# NOTE: I don't know if this works on non-*nix platforms, but it's
	# the recommended way to do it, according to the Perl Cookbook.
	my ($srcdev, $srcnode) = stat $source;
	my ($dstdev, $dstnode) = stat $dest;
	return if (($srcdev == $dstdev) && ($srcnode == $dstnode));

	# ...and then make File::Copy do something useful with itself.
	copy($source, $dest) or print "couldn't copy $source: $!\n";
}


#
# ReadConfig
#
# Scan our command line params looking for configuration directives,
# then look for more config stuff in .gxml2html files in either this
# directory or the source file directory.
#
sub ReadConfig
{
	my ($force, $noHTML, $dashConvert, %remappings,
		$templateDir, $urlPrefix, $configFile);

	# First, grab any command line params. These override anything
	# found in a configuration file.
	my %options = ("debug"		=> \$debugMode,
				   "nohtml"		=> \$noHTML,
				   "dash"		=> \$dashConvert,
				   "work"		=> \$workDir,
				   "source"		=> \$workDir,
				   "final"		=> \$finalDir,
				   "dest"		=> \$finalDir,
				   "templates"	=> \$templateDir,
				   "urlprefix"	=> \$urlPrefix,
				   "force"		=> \$force,
				   "config"		=> \$configFile);

	# Thank goodness for standard perl modules.
	GetOptions(\%options, "debug", "nohtml", "dash", "work=s",
			   "source=s", "final=s", "dest=s", "templates=s",
			   "urlprefix=s", "config=s", "force");

	# Now try digging for config files in case we didn't get any
	# command line params. Look in work file directory first,
	# otherwise in the directory of this script.
	if (defined $configFile)
	{
		# user passed it in
	}
	if ((defined $workDir) && 
		(-f File::Spec->catfile($workDir, '.gxml2html')))
	{
		$configFile = File::Spec->catfile($workDir, '.gxml2html');
	}
	elsif (-f File::Spec->catfile(File::Spec->curdir, '.gxml2html'))
	{
		$configFile = File::Spec->catfile(File::Spec->curdir, '.gxml2html');
	}
	
	if ($configFile)
	{
		my $line;

		open(CONFIG, $configFile);

		while ($line = <CONFIG>)
		{
			chomp($line);

			# Only set options which exist but whose values are
			# not yet defined.
			if (($line =~ /^\s*(\w+)[\s:=]+(\S+)/) &&
				(exists $options{$1} && !defined ${$options{$1}}))
			{
				${$options{$1}} = $2;
			}
			elsif ($line =~ /^\s*<(\S+)>[\s:=]*<?([^\s>]*)>?/)
			{
				# tag remappings of the form <premap> <aftermap>
				XML::GXML::Util::Log("remapping $1 to $2");
				$remappings{$1} = $2;
			}
		}

		close(CONFIG);
	}
		
	# If none of that worked, just make up stuff.
	$workDir = File::Spec->catdir(File::Spec->curdir, 'work')
		unless defined $workDir;
	$finalDir = File::Spec->catdir(File::Spec->curdir, 'final')
		unless defined $finalDir;
	$templateDir = File::Spec->catdir(File::Spec->curdir, 'templates')
		unless defined $templateDir;
	$urlPrefix = '/' unless defined $urlPrefix;

	die "source directory does not exist\n" unless -d $workDir;
	die "output directory does not exist\n" unless -d $finalDir;
	die "templates directory does not exist\n" unless -d $templateDir;

	# Load the modification times of the stuff we're processing into
	# the %modtimes hash. We'll use this later to determine if we
	# really need to process the file.
	unless ($force)
	{
		XML::GXML::Util::LoadModtimes(File::Spec->catfile($workDir, '.modtimes'), \%modtimes);
	}

	XML::GXML::Util::Log("source directory    : $workDir");
	XML::GXML::Util::Log("output directory    : $finalDir");
	XML::GXML::Util::Log("templates directory : $templateDir");
	XML::GXML::Util::Log("base directory      : $baseDir");

	return ('work'			=> $workDir,
			'final'			=> $finalDir,
			'templateDir'	=> $templateDir,
			'remappings'	=> \%remappings,
			'urlprefix'		=> $urlPrefix,
			'dashConvert'	=> $dashConvert,
			'debugMode'		=> $debugMode,
			'html'			=> 1,
			);
}

