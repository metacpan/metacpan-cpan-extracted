#! /usr/bin/perl -w

# #(@) $Id: example.pl 1.3 Mon, 27 Mar 2006 02:20:00 +0200 mxp $
# Example program illustrating the use of User::Utmp.

use lib './blib/lib', './blib/arch';
use Getopt::Std;
use User::Utmp qw(:constants);
use Socket;
use strict;

my %options; getopts('f:hux', \%options);

my @utmp;
my %ut_type = (BOOT_TIME()     => "BOOT_TIME",
	       DEAD_PROCESS()  => "DEAD_PROCESS",
	       EMPTY()         => "EMPTY",
	       INIT_PROCESS()  => "INIT_PROCESS",
	       LOGIN_PROCESS() => "LOGIN_PROCESS",
	       NEW_TIME()      => "NEW_TIME",
	       OLD_TIME()      => "OLD_TIME",
	       RUN_LVL()       => "RUN_LVL",
	       USER_PROCESS()  => "USER_PROCESS");

###############################################################################

if ($options{h})
{
   print "Usage: $0 [-f <file>] [-hux]\n";
   print <<EOT;

       -f <file> Use alternative utmp/utmpx file named <file>
       -h        Show this help message and exit
       -u        Show only records of type USER_PROCESS
       -x        Use utmpx
EOT
    exit;
}

if ($options{f})
{
   if ($options{x} && User::Utmp::HAS_UTMPX())
   {
      User::Utmp::utmpxname($options{f});
   }
   else
   {
      User::Utmp::utmpname($options{f});
   }
}

if ($options{x})
{
   if (User::Utmp::HAS_UTMPX())
   {
      @utmp = User::Utmp::getutx();
   }
   else
   {
      die "Utmpx is not available on your system.";
   }
}
else
{
   @utmp = User::Utmp::getut();
}

print scalar(@utmp), " elements total\n\n";

foreach my $entry (@utmp)
{
   unless ($options{u} and $entry->{"ut_type"} != USER_PROCESS)
   {
      while (my ($key, $value) = each(%$entry))
      {
	 if ($value)
	 {
	    if ($key eq "ut_type")
	    {
	       $value = $ut_type{$value};
	    }
	    elsif ($key eq "ut_addr")
	    {
	       $value = gethostbyaddr($value, AF_INET) .
		   " (" . join(".", unpack("C4", $value)) . ")";
	    }
	    elsif ($key eq "ut_time" and $value)
	    {
	       $value = scalar(localtime($value));
	    }
	    elsif ($key eq "ut_tv" and $value) # utmpx only
	    {
	       $value = localtime($value->{tv_sec}) .
		   " (" . $value->{tv_usec} . " µs)";
	    }
	    elsif ($key eq "ut_exit")
	    {
	       my @s;

	       while (my ($k, $v) = each(%$value))
	       {
		  push @s, "$k: $v";
	       }

	       $value = join ", ", @s;
	    }
	 }
	 else
	 {
	    $value = "-";
	 }

	 printf "%10s: %s\n", $key, $value;
      }

      print "\n";
   }
}
