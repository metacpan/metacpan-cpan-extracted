#! /usr/local/bin/perl -w

# This script writes the .htaccess files - see the README

use strict;
package main;
use vars qw($installdir);

my $conf="cvswebconfig.pl";
require $conf; # defines $installdir

unless (-d "$installdir") {
    die "Cannot find config $conf";
}

my $tag = "Location";
my $confdir = $installdir."/etc";
my $htpasswd = $confdir."/htpasswd";
my $htgroup = $confdir."/htgroup";

my $access = new Access;

$access->setOverwrite(1);

#	DIRECTORY, ./cvs-web/read/, valid-user, "Read access", .../htpasswd, .../htgroup, Basic, ExecCGI

$access->write($tag, $installdir.'/read', 'valid-user', 
		"CVSWeb - Read Permision", $htpasswd, $htgroup,
		'Basic', 'ExecCGI',
	      );

$access->write($tag, $installdir.'/edit', 'group edit', 
		"CVSWeb - Edit Permision", $htpasswd, $htgroup,
		'Basic', 'ExecCGI',
	      );

$access->write($tag, $installdir.'/admin', 'group admin', 
		"CVSWeb - Admin Permision", $htpasswd, $htgroup,
		'Basic', 'ExecCGI',
	      );

$access->write($tag, $installdir.'/lib', 'group admin', 
		"CVSWeb - Admin Permision", $htpasswd, $htgroup,
		'Basic', 'ExecCGI',
	      );

$access->write($tag, $installdir.'/etc', 'group admin', 
		"CVSWeb - Admin Permision", $htpasswd, $htgroup,
		'Basic', 'ExecCGI',
	      );

$access->write($tag, $installdir.'/', 'valid-user', 
		"CVSWeb - Read Permision", $htpasswd, $htgroup,
		'Basic', '',
	      );

$access->write($tag, $cvswebedit_state, 'group admin', 
		"CVSWeb - Admin Permision", $htpasswd, $htgroup,
		'Basic', '',
	      );

$access->write($tag, $cvswebcreate_state, 'group admin', 
		"CVSWeb - Admin Permision", $htpasswd, $htgroup,
		'Basic', '',
	      );

$access->write($tag, $tempdir, 'group admin', 
		"CVSWeb - Admin Permision", $htpasswd, $htgroup,
		'Basic', '',
	      );


exit(0);

package Access;
my @ISA = qw(Exporter);
use FileHandle;
my $overwrite = 0;

sub setOverwrite($) {
  $overwrite = shift;
}

sub new($$) {
   my $class = shift;
   my $self = {};
   return bless $self, $class;
}

sub write($$$$$$$) {
#	DIRECTORY, /cvs-web, valid-user, "Read access", .../htpasswd, .../htgroup, Basic, ExecCGI
	my ($self, $tag, $filename, $require,
		$authName, $authUserFile, $authGroupFile,
		$authType, $options
	   ) = @_;

	my $htaccess = $filename."/.htaccess.txt";
	if (-f $htaccess) {
	  if ($overwrite) {
	    die "$htaccess file already exists. Delete all htaccess files before running\n";
	  } else {
	    print "Overwriting $htaccess\n";
	  }
	} else {
	  print "Writing $htaccess\n";
        }

	my $fh = new FileHandle($htaccess, "w");
        if (!$fh) {
	  die "Can't write to $htaccess - $!";
	}

	print $fh "# Written by $0 ".localtime(). "\n";
	print $fh "<Files *>\n";
	print $fh "  AuthType ".$authType."\n";
	print $fh "  AuthName ".'"'.$authName.'"'."\n";
	print $fh "  AuthUserFile ".'"'.$authUserFile.'"'."\n";
	print $fh "  AuthUserGroup ".'"'.$authGroupFile.'"'."\n";
        print $fh "  Options ".$options."\n";
        print $fh "  require ".$require."\n";
        print $fh "</Files>\n";

	close $fh;
}
