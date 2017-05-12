# -*- perl -*-

use strict;
use ExtUtils::MakeMaker;
use Getopt::Long ();

use vars qw($opt_config);
Getopt::Long::GetOptions('config');

my %prereq =
( 'Data::Dumper' => 0,
  'IO::AtomicFile' => 0,
  'HTML::EP' => 0,
  'Wizard' => 0,
  'Net::Netmask' => 0.05,
  'Convert::BER' => 0,
  'Net::LDAP' => 0,
  );


my $cfg;
# Make sure a Makefile is generated; the CPAN module depends on it
eval {
  if (-f "lib/Wizard/LDAP/Config.pm") {
    $cfg = eval { require "lib/Wizard/LDAP/Config.pm" };
  }
  if (!$cfg  ||  $opt_config) {
    my $prefsfile = $cfg->{'ldap-prefs-file'} || '/etc/Wizard-LDAP/prefs';
    $cfg->{'ldap-prefs-file'} =
      prompt("Enter path of the LDAP Wizard prefs file:", $prefsfile);
  }
  die "Failed to create directory lib/Wizard/LDAP: $!"
    unless ((-d "lib/Wizard/LDAP")  or
	    mkdir("lib/Wizard/LDAP", 0755));
  require Data::Dumper;
  my $dump = Data::Dumper->new
    ([$cfg], ["Wizard::LDAP::Config::config"])->Indent(1)->Dump();
  if (!open(FILE, ">lib/Wizard/LDAP/Config.pm")  or
      !(print FILE ("package Wizard::LDAP::Config;\n",
		    $dump))  or
      !close(FILE)) {
    die "Failed to create file lib/Wizard/LDAP/Config.pm: $!";
  }
};
my $status = $@;

my %opts = ('NAME'         => 'Wizard-LDAP',
	    'VERSION_FROM' => 'lib/Wizard/LDAP.pm',
	    'EXE_FILES'    => ['ldapAdmin', 'ldapWizard'],
	    'dist'         => { 'SUFFIX'       => ".gz",
				'DIST_DEFAULT' => 'all tardist',
				'COMPRESS'     => "gzip -9f" },
	    'clean'        => { 'FILES' => '$(EXE_FILES)' });
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
#    $opts{ABSTRACT_FROM} = 'lib/Wizard/SaveAble/LDAP.pm';
    $opts{AUTHOR} = 'Jochen Wiedmann <joe@ispsoft.de> and Amarendran R. Subramanian <amar@ispsoft.de>';
    $opts{PREREQ_PM} = \%prereq;
}


WriteMakefile(%opts);

die $status if $status;


package MY;

sub libscan {
    my $self = shift;  my $path = shift;
    return undef if $path =~ /\~$/; # Emacs backup file
    $path;
}

sub postamble {
    qq{

all :: README

README: lib/Wizard/LDAP.pod
\tpod2text lib/Wizard/LDAP.pod >README

};
}
