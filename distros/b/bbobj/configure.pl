#!/usr/bin/perl

## $Id: configure.pl,v 1.2 2002/07/14 06:43:06 dshanks Exp $

use File::Copy;

my $line;

## read in the current user to use as a default
my $bbuser = $ENV{'USER'} || 'bbuser';

## request the user id for the BigBrother user
print "Big Brother User: [$bbuser] ";
while ( not defined ( $line = readline(STDIN) ) ) { }
chomp $line;
if ($line) { $bbuser = $line; }

## build the default BigBrother home directory
my $bbhome = $opts->{'d'} || "/home/$bbuser/bb";

## request the user id for the BigBrother home directory
print "Big Brother Home Directory: [$bbhome] ";
while ( not defined ( $line = readline(STDIN) ) ) { }
chomp $line;
if ($line) { $bbhome = $line; }

## read in the current set of environment variables
my $ENV1 = \%ENV;

## Initial a reference for a second set of variables
my $ENV2 = {};
my $Config;

## Set the BBHOME environment variable: this is set after we save the current set
$ENV{'BBHOME'} = $bbhome;

if ( -d $bbhome ) {
  ## Just because we have a valid directory name doesn't mean we have files to read
  ## here we check for the BogBrother definition scripts, no point continuing if 
  ## they don't exist
  unless ( -x "$bbhome/etc/bbdef.sh" ) {
    die ( "Cannot execute $bbhome/etc/bbdef.sh");
  }
  ## Change into the BigBrother home directory
  chdir $bbhome;

  ## Run the script and print out the new environment to a list
	my @env = qx|. $bbhome/etc/bbdef.sh;set|;
  ## Iterate throught the list; if the variable existed in the original environment set
  ## go past it, if it did not, save it into ENV2 reference
	foreach my $el ( @env ) {
		chomp $el;
		$el =~ /^\s*(.*?)\s*=\s*(.*)/;
		unless ( exists $ENV1->{$1} ) { 
			my $name = $1;
			my $valu = $2;
			if ( $valu =~ /^\'(.*)\'$/ ) {
				$valu = $1;
			}
			$ENV2->{$name} = $valu; 
		}
	}
  ## Make sure the BBHOME vriable makes it into the config
  $ENV2->{'BBHOME'} = $bbhome;
	
  ## change back to the original directory
	chdir $ENV1->{'PWD'}."";

  ## change into the Object directory
  chdir "Object";

  ## Check for current instances of the Config.pm
	my $ConfigFile = "Config.pm";
	if ( -e $ConfigFile ) {
		foreach my $i ( 1 .. 100 ) {
			if ( -e $ConfigFile.".".$i ) {
				if ( $i eq "100" ) { 
					die("ERROR: Too Many Backup Files\n");
				} else {
					next; 
				}
			} else {
				move($ConfigFile,$ConfigFile.".".$i);
				last;
			}
		}	
	}

  ## Create the content for the Config.pm
	my $script = q|package BigBrother::Object::Config;

sub new {
	my $class = shift();
	my $self = {
|;

	foreach my $key ( sort keys %$ENV2 ) {
		$script .= qq|\t\t$key => q[$ENV2->{$key}],\n|;
	};

	$script .= qq|\t};
	return bless(\$self,\$class);
}
1;
|;

  ## Now send the new file to the system
	open FH, ">$ConfigFile" or die("ERROR: Could not open Config.pm for writing\n");
		print FH $script;
	close FH;
} else {
	die("ERROR: Brother Home directory is invalid\n");
}

exit();
