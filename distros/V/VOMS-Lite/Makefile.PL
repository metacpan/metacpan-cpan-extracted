use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
  return <<EOT;
.PHONY: version rpm

version:
	perl updateversion.pl

rpm: dist version
	sh buildRPM.sh

EOT
}

# Are we using CPAN?
my $UsingCPAN=$INC{"CPAN.pm"};

# List required modules and their version details:

my $RequiredModules={
                      Term::ReadKey   => 0,
                      Digest::MD5     => 0,
                      Digest::SHA1    => 0,
#                      Digest::MD4     => 0,
                      Digest::MD2     => 0,
#                      Crypt::Primes    => 0,
                      Crypt::CBC      => 0,
Crypt::DES => 0,
                      Crypt::DES_EDE3 => 0,
#                      Crypt::RSA::Key => 0,  #No longer needed
                      Math::BigInt    => 0,
                      MIME::Base64    => 0,
#                      Regexp::Common  => 0,   #Used simpler URI Regexp (assume caller knows URI format)
                      File::Copy      => 0,
                      Time::Local     => 0,
                      IO::Socket      => 0,
                      IO::Socket::SSL => 0,    #MyProxy needs this
                      Sys::Hostname   => 0
                    };

# Set up optional dependencies

my %optionals=( Math::BigInt::GMP  => "speeds signing and encrypting up by between 5 and 20 times"
               ,HTTP::Daemon::SSL  => "is used by the example script voms-server.pl"
               ,LWP::UserAgent     => "is used by the example script voms-proxy-init.pl"
               ,DBI                => "is used if connection to a gLite VOMS Data base is required"
               ,DBD::mysql         => "is used if connection to a gLite VOMS MySQL Data base is required\nNB you'll need mysql client and a running server for make test to work!"
#               ,DBD::Oracle        => "would be used if connection to a gLite VOMS Oracle Data base is required\nNB you need an Oracle client installed"
              );

if ( $UsingCPAN ) {

# Ask whether to make optional dependencies prerequisites.
  foreach $optional (keys %optionals) {
    if ( ! eval "require $optional" ) {
      print <<EOF;

$optional is not installed.
While this is not a requirement, you may want to include it in the
installation prerequisites.

$optional
  $optionals{$optional}
EOF

      print <<EOF;

I see you're using CPAN to install VOMS::Lite (a wise choice).
I can instruct CPAN to download and install $optional
by adding it to the "PREREQ_PM" list.
EOF
      my $answer = ExtUtils::MakeMaker::prompt("Shall I add $optional to the PREREQ_PM list?", "yes");
      if ($answer =~ /^\s*y/i) {
        $$RequiredModules{$optional}=0;
      }
    }
  }
}

########Wonders whether we should even enter this loop if using CPAN
if ( ! $UsingCPAN && 0 ) {
  foreach $required (keys %$RequiredModules) {
    if ( ! eval "require $required" ) {
      print "\n$required is not installed and you're not using CPAN.\n";
      print <<EOF;

$required is not installed and
I see you're installing VOMS::Lite by hand. If you wish,
I can try to use CPAN to download and install $required.
EOF
      my $answer = ExtUtils::MakeMaker::prompt("Shall I attempt to install $required with CPAN?", "yes");
      if ($answer =~ /^\s*y/i) {
        if ( eval "require CPAN" ) { # Can I load CPAN?
          $CPAN::Config{ftp_passive}=q[1];
          $ENV{FTP_PASSIVE} = 1;
          $CPAN::Config{prerequisites_policy}='follow';
          CPAN::install $required;
        }
        else {# I can't load CPAN
          print "Can't find CPAN on your system, sorry the CPAN install won't work!\n";
          exit(1);
        } 
      }
    }
  }
}

# Make Makefile

WriteMakefile(
    NAME              => 'VOMS::Lite',
    VERSION_FROM      => 'lib/VOMS/Lite.pm', # finds $VERSION
    EXE_FILES         => [ qw( bin/extractVOMS.pl 
                               bin/examineAC.pl
                               bin/cert-init.pl
                               bin/cert-req.pl
                               bin/verifycert.pl 
                               bin/voms-proxy-init.pl 
                               bin/voms-proxy-list.pl
                               bin/proxy-init.pl 
                               bin/voms-ac-issue.pl
                               bin/myproxy-get.pl
                               bin/myproxy-init.pl
                               sbin/voms-server.pl
                               sbin/vomsserver.pl
                              ) ],
    PREREQ_PM         => $RequiredModules,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VOMS/Lite.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Jones <mike.jones@manchester.ac.uk>') : ()),
);
