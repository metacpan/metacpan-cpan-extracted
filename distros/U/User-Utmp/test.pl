# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use User::Utmp qw(:constants);
use POSIX qw(ttyname);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$user = getlogin || getpwuid($<) || $ENV{USER};
$term = ttyname(undef);
$term =~ s|^/dev/||;

###############################################################################

$test = 2;

unless (UTMP_FILE && -z UTMP_FILE)
{
   @utmp = User::Utmp::getut();

   $found = 0;

   foreach $entry (@utmp)
   {
      if ($entry->{ut_type} == USER_PROCESS)
      {
	 $found++ if $entry->{ut_user} eq $user;
	 $found++ if $entry->{ut_line} =~ $term;
      }
   }

   print $found ? "" : "not ", "ok 2 ";

   if (not $found)
   {
      print "(Could not find utmp entry for user $user and/or line $term)";
   }

   print "\n";
}
else
{
   print "skipped $test (empty utmp file)\n";
}

###############################################################################

$test++;

if (User::Utmp::HAS_UTMPX())
{
   $entry = User::Utmp::getutxline($term);

   $found = 0;

   if ($entry)
   {
      $found++ if $entry->{ut_user} eq $user;
      $found++ if $entry->{ut_line} =~ $term;
   }

   print $found ? "" : "not ", "ok $test ";

   if (not $found)
   {
      print "(Could not find utmpx entry for user $user and/or line $term)";
   }

   print "\n";

}
else
{
   print "skipped $test (utmpx not available on this system)\n";
}

###############################################################################

$test++;

if (User::Utmp::HAS_UTMPX())
{
   @utmp = User::Utmp::getutx();

   $found = 0;

   foreach $entry (@utmp)
   {
      if ($entry->{ut_type} == USER_PROCESS)
      {
	 $found++ if $entry->{ut_user} eq $user;
	 $found++ if $entry->{ut_line} =~ $term;
      }
   }

   print $found ? "" : "not ", "ok $test ";

   if (not $found)
   {
      print "(Could not find utmpx entry for user $user and/or line $term)";
   }

   print "\n";

}
else
{
   print "skipped $test (utmpx not available on this system)\n";
}

###############################################################################

$test++;

if (User::Utmp::HAS_UTMPX())
{
   open(FH, '>', 'wtmpx');
   close(FH);

   %entry = (ut_type => BOOT_TIME,
	     ut_line => 'system boot',
	     #ut_pid  => undef,
	     ut_id   => '-',
	     ut_user => 'reboot',
	     #ut_time => time,
	     #ut_exit => {e_termination => 1, e_exit => 2},
	     #ut_tv => {tv_sec => 79200000, tv_usec => 43},
	    );

   User::Utmp::utmpxname('wtmpx');
   User::Utmp::pututxline(\%entry);

   @utmp = User::Utmp::getutx();

   $found = 0;

   foreach $entry (@utmp)
   {
      if ($entry->{ut_type} == BOOT_TIME)
      {
	 $found++ if $entry->{ut_user} eq 'reboot';
	 $found++ if $entry->{ut_line} eq 'system boot';
      }
   }

   unlink 'wtmpx';

   print $found ? "" : "not ", "ok $test ";

   if (not $found)
   {
      print "(Could not find utmpx entry I just wrote)";
   }

   print "\n";

}
else
{
   print "skipped $test (utmpx not available on this system)\n";
}

###############################################################################
