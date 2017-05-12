#!/usr/bin/perl -w
# Copyright (c) 2002-2005 the World Wide Web Consortium :
#       Keio University,
#       Institut National de Recherche en Informatique et Automatique,
#       Massachusetts Institute of Technology.
# written by Olivier Thereaux <ot@w3.org> for W3C
#
# $Id: logprocess.pl,v 1.10 2005/09/09 06:33:11 ot Exp $
#########################

use strict;
use Getopt::Long qw(GetOptions);
use W3C::LogValidator ();

my $conffile = '';
my %conf;
my $OutputTo;
my $SendTo;
$conf{"verbose"}=1;

GetOptions('q|quiet'      => sub { $conf{"verbose"} = 0; },
           'v|verbose'    => sub { $conf{"verbose"} = 2; },
           'd|debug'      => sub { $conf{"verbose"} = 3; },
           'f|config=s'   => \$conffile,
           'help|h|?'     => sub { usage(1); exit 0 },
	   'HTML'         => sub { $conf{"UseOutputModule"} = "W3C::LogValidator::Output::HTML"; },
	   'email'	  => sub { $conf{"UseOutputModule"} = "W3C::LogValidator::Output::Mail"; },
	   'o|output=s'	  => \$OutputTo,
	   's|sendto=s'	  => \$SendTo	   
          ) or usage(1);

$conf{"OutputTo"} = $OutputTo if ($OutputTo); 
$conf{"ServerAdmin"} = $SendTo if ($SendTo); 

W3C::LogValidator->new($conffile, \%conf)->process();

sub usage
{
	print "Usage: logprocess.pl [options]


 General options are: 
   -h/--help			help. what you're reading now.
   -f/--config <filename>	to read a specific config file. strongly suggested.

 Verbosity options are (default - no option - is between quiet and verbose):
   -q/--quiet			quiet. not verbose. useful for cron'd usage.
   -v/--verbose 		verbose. lots of blah blah.
   -d/--debug			even more verbose than verbose, for debug purpose.

 Output choices are (default - nothing specified -  is command-line output):
   --HTML			trigger output in HTML
   --email			trigger output as mail sent to maintainer
   -o/--output <filename>	choose where to save output
	the output will go to console if not specified
  -s/--sendto <email>		choose where to send the e-mail 
	In e-mail output mode, if neither this nor ServerAdmin (in the config)
	is specified then the output will fall-back to console


 Note: 
  All these options can be configured through the config file. 
  Setting an option overrides the choice made in the config file.

";
	exit 0;
}
