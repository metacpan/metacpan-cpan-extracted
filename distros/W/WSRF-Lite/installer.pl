#! /usr/bin/perl -w

# Installer script for WSRF::Lite. This script is designed to work
# with the OMII (http://www.omii.ac.uk/) installation system which
# uses ant. The build.xml file invokes this script with the required
# command line option.

use CPAN;
use CPAN::Config;
use Cwd;
use Getopt::Std;
#use strict;
$|++;


# We fork processes, eg client scripts, need to reap what we sow.
# REAPER kills of stray children.
sub REAPER {
   local $!;
   waitpid(-1,0);
   $SIG{CHLD} = \&REAPER;  # still loathe sysV
}


$VERSION = 0.3;

our ($opt_h,$opt_t,$opt_i,$opt_v);

my $usage = <<EOF;
This is the installer script for the OMII distribution of WSRF::Lite. It must 
be run from the WSRF::Lite distribution directory. 

-i install WSRF::Lite.

-t test WSRF::Lite installation, will start a WSRF::Lite Container and check
   that it is functioning correctly.

-v check whether the Perl environment is correct.

-h prints this message.   

EOF


if ( ! @ARGV )
{
   print $usage;
   exit 0;
}



#The set of modules that need to be installed by
#WSRF::Lite
my @CriticalModules = qw(URI LWP SOAP::Lite XML::DOM DateTime
                         DateTime::Format::Epoch DateTime::Format::W3CDTF
                         Storable IO::Socket HTTP::Status HTTP::Daemon HTTP::Request
                         HTTP::Response);

my @NonCriticalModules = qw(Digest::SHA1 HTTP::Daemon::SSL 
                            Crypt::OpenSSL::X509 XML::CanonicalizeXML
                            Crypt::OpenSSL::RSA );

my @modules = ( @CriticalModules, @NonCriticalModules );


getopts("hitv");

# print help message and exit
if($opt_h) {
   print $usage;
   exit 0;
}


# install WSRF::Lite and exit
if($opt_i) {
   print "Installing WSRF::Lite...\n";
   eval {   #trap exceptions and make sure to clean up
     install_wsrf_lite(); 
   };      
   if ($@) {
      print "$@";
      local $SIG{HUP} = 'IGNORE';
      kill (HUP, -$$);
      exit -1;
   }
}

# test installation of WSRF::Lite
if($opt_t) {
   print "Testing WSRF::Lite installation...\n";
   eval {   #trap exceptions and make sure to clean up
       test_wsrf_lite();
   };
   if ($@) {
      print "$@";
      local $SIG{HUP} = 'IGNORE';
      kill (HUP, -$$);
      exit -1;
   }
}

# check the Perl environment
if($opt_v) {
   print "Validating the Perl environment...\n";
   my @MissingNonCriticalModules = ();
   my @MissingCriticalModules = ();
   my $noncrit = 0;
   foreach my $module ( @NonCriticalModules )
   {
      eval "require $module";
      if( $@ )    #could not load module
      {
        $noncrit = 1; 
        push @MissingNonCriticalModules, $module;
        print " Non Critical module $module missing.\n";      
      }        
   }   

   my $fail = 0;
   foreach my $module ( @CriticalModules )
   {
      eval "require $module";
      if( $@ )    #could not load module
      {
        $fail = 1; 
        push @MissingCriticalModules, $module;      
        print " Fail: Critical module $module missing\n";
      }  
   }

   #check for versions
   if ( defined($SOAP::Lite::VERSION) && ( $SOAP::Lite::VERSION lt 0.67 ) )
   {
    print " Fail: SOAP::Lite version is $SOAP::Lite::VERSION, version 0.67 or higher is required\n";
    $fail = 1;
   }

   print "WSRF::Lite can be installed on this system but will have limited functionality due to missing modules.\n" if ( !$fail && $noncrit);

   die "Perl environment will not support WSRF::Lite\n"
          if $fail;
}



#Come to the end of the script kill everything.
{
  local $SIG{HUP} = 'IGNORE';
  kill (HUP, -$$);
}


exit;


sub test_wsrf_lite {

 #Check if WSRF_MODULES environmental variable is set
 if ( !defined($ENV{WSRF_MODULES}) )
 {
    print "Environmental variable WSRF_MODULES not set.\n";
    my $dir = getcwd;
    $ENV{WSRF_MODULES} = $dir."/modules";
    print 'Setting $ENV{WSRF_MODULES} to '.$dir."/modules\n";
 } 

 #check if the directories have been created
 my @dirs = qw( /tmp/wsrf /tmp/wsrf/data);
 foreach my $dir (@dirs)
 {
   print "Checking for directory $dir...";
   if ( ! -d $dir)
   {
     print "No, doesn't exist.\nCreating $dir...";
     return "Could not make $dir\n" unless mkdir($dir);
     print "Done\n";
   }
   else
   {
     print "OK\n";
   }
   print "Checking if $dir has correct permissions...";
   if ( ! -w $dir || ! -r $dir )
   {
      print "No\n";
      exit;
   }
   else
   {
      print "Yes\n"; 
   }
 }
 
 #need to start Container...
 opendir(DIR, ".") or die "Could not open directory \".\" $!\n";
 my @files = readdir DIR;
 closedir DIR;
 
 die "Could not find ./Container.pl\n" 
         unless grep (/^Container.pl$/, @files);

 #fork and exec the Container 
 if (my $pid = fork)  #parent
 {  
   print "Parent $$ Forked\n"; 
   sleep 1;
   #Check if the Container is still runing.
   die "Container process $pid does not seem to be running, check \"./output\"" 
      if not kill(0,$pid);

   print "Changing directory to ./test\n";
   chdir "./test" or return "Could not change directory to ./test";
   print "Running ./client_test.pl\n";
   my @args = qw(./client_test.pl);
   system(@args) == 0
      or die "system @args failed: $?"; 
 }
 elsif (defined($pid) )  #child
 {
   print "Child $$ starting Container.pl, output sent to ./output\n";
   exec "./Container.pl -d > ./output 2>&1 " 
      or die "Couldn't execute  ./Container.pl -d > ./output 2>&1"; 
 }
 else
 {
   die "Fork failed\n";
 }	 

 return;
}



sub install_wsrf_lite {

my $message = <<EOF;
To install WSRF::Lite you need CPAN configured for this account - for more
information on configuring CPAN see CPAN_help in the WSRF::Lite distribution
directory. You can use Cntrl-C to exit the script.
EOF

#remember where the cwd is
my $cwd = getcwd;

#Print the set of CPAN mirrors that this installation
#has been configured to use
 my @urllist = @{$CPAN::Config->{'urllist'}};

 print "CPAN has been configured to use the following mirrors...\n";
 foreach my $url ( @urllist )
 {
   print "  ".$url."\n";	
 }

 print "Installing Crypt::OpenSSL::RSA version 0.18\n";
 $obj = CPAN::Shell->expandany("IROBERTS/Crypt-OpenSSL-RSA-0.18.tar.gz");

 if ( $obj->uptodate() )
 {
   print "  Crypt::OpenSSL::RSA is up to date\n"; 
 }
 else
 {
   $obj->install;	 
 }	

 foreach my $mod ( @modules )
 {
     print "Installing $mod...\n";
     $obj = CPAN::Shell->expand('Module',$mod);
     $obj->install;
 }


 unless (my $return = do './Makefile.PL')
 {
   die "Couldn't parse Makefile.PL: $@" if $@;
   die "Couldn't do Makefile.PL: $!" unless defined $return;
   die "Couldn't run Makefile.PL" unless $return;
 }

#find out which make we should use...

 my $make = $CPAN::Config->{'make'};
 print $make."\n";

 print "Running make...\n";
 print `$make`;
 print "Running make test...\n";
 print `$make test`;
 print "Running make install...\n";
 print `$make install`;

 chdir($cwd);
 return;
}
