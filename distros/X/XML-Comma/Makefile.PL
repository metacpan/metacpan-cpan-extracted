#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.006_001;

package MY;
sub MY::libscan {
  my ( $self, $passed_path ) = @_;
  # print " path --> $passed_path\n";
  my $path = $self->SUPER::libscan($passed_path);
  if ( $path =~ m|Comma/Configuration\.pm$| ) {
    # print "matched config path\n";
    if ( `$^X -e 'eval { require XML::Comma::Configuration }; print "ok" unless \$@;'`
           eq 'ok' ) {
      print <<'END';

- XML::Comma is already installed on this machine. We'll use your
- existing XML::Comma::Configuration file for 'make test', and leave
- it alone during any future 'make install' operation. If you would
- like to make any changes before installing this version of Comma,
- simply edit the version of Configuration.pm under blib/ after
- running 'make', but before 'make test' and 'make install'

END
      return '';
    }
  }
  return $path; 
};

package main;


my @cmd_line_utils = map { chomp; $_ } <bin/*.pl>;

my $dbd_module = "DBD::mysql";
eval { require DBD::mysql; }; if($@) {
  #no mysql, try pg
  $dbd_module = "DBD::Pg";
  eval { require DBD::Pg; }; if($@) {
    #neither found, use mysql by default due to its popularity
    $dbd_module = "DBD::mysql";
  }
}

my $prereq_pm = 
  # need Storable to run bin/comma-create-config.pl
  # but that's ok since it's been in core since 5.007003
  # (5.8 came out around 2002)
  { 'Class::ClassDecorator'    => 0,
    'Clone'                    => 0,
    'Compress::Zlib'           => 0,
    'Crypt::Blowfish'          => 0,
    'Crypt::CBC'               => 0,
    $dbd_module                => 0,
    'DBI'                      => 0,
    'Digest::HMAC_MD5'         => 0,
    'Inline'                   => 0,
    'Lingua::Stem'             => 0,
    'Math::BaseCalc'           => 0,
    'PAR'                      => 0,
    'Proc::Exists'             => "0.04",
    'String::CRC'              => 0,
    'Storable'                 => 0,
    'Test::More'               => 0,
};

WriteMakefile(
    'NAME'         => 'XML::Comma',
    'ABSTRACT'     => 'XML::Comma document life-cycle platform',
    'LICENSE'      => 'gpl',
    'EXE_FILES'    => \@cmd_line_utils,
    'VERSION_FROM' => 'lib/XML/Comma.pm',
    'PREREQ_PM'    => $prereq_pm,
    #'clean' => {
    #  'FILES' => 'lib/XML/Comma.pm'
    #}
);

#install base macros, defs, includes, etc.
use misc::MakeMakerMod;
misc::MakeMakerMod::add_steps(
	step => "all", 
	what => "$^X bin/comma-create-config.pl", 
);
misc::MakeMakerMod::add_steps(
   step => "install",
   what => "$^X misc/install-extras.pl"
);
misc::MakeMakerMod::add_steps(
   step => "distclean",
   what => "rm -rf .test",
);

my $has_all_pms = 1;
foreach my $pm (keys %$prereq_pm) {
  $pm =~ s/::/\//g;
  $pm =~ s/$/.pm/;
  eval { require $pm; };
  if($@) {
    #if we get here, we hope the user or CPAN will fill in the blanks.
    warn "missing one or more dependencies ($pm), here's hoping CPAN fills in the rest\n";
    $has_all_pms = 0;
    last;
  }
}

if($has_all_pms && ($dbd_module ne "DBD::mysql")) {
  die "using non-mysql backend - you must create a valid Configuration.pm and run Makefile.PL again\n";
}

