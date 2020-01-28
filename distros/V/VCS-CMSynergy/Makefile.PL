#!/usr/bin/perl -w

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod usage and distribution rights.

use strict;
use Config;
use File::Spec;
use ExtUtils::MakeMaker;

# --- Check that Synergy CLI is installed

sub nay { warn(@_); exit(0); }
# NOTE: Don't die if the following checks fail,
# just exit(0) without producing a Makefile -
# the automated CPAN tests will interpret this as an indicator that
# a prerequisite of this module is missing and will generate 
# an NA report instead of FAIL.

nay qq{
  The CCM_HOME environment variable must be set
  to the path of the Synergy installation directory.
  See the README file for more information.
  ABORTED!
} unless $ENV{CCM_HOME};

my $ccm_exe = File::Spec->catfile(
    $ENV{CCM_HOME}, "bin", "ccm$Config{_exe}");
nay qq{  
  The value ($ENV{CCM_HOME})
  of the CCM_HOME environment variable is not valid.
  It must be set to the path of the Synergy installation directory.
  See the README file for more information.
  ABORTED!
} unless -x $ccm_exe || ($^O eq 'cygwin' && -e $ccm_exe);
# NOTE: -x $ccm_exe fails on cygwin

my $ccm_version = qx("$ccm_exe" version);
nay qq{  
  The Synergy CLI program ($ccm_exe)
  doesn't appear to work on this machine. 
  See the README file for more information.
  ABORTED!
} unless $? == 0;

nay qq{  
  Failed to recognize the output of
  "$ccm_exe version" -
  perhaps this Synergy version is too old or too new.
  ABORTED!
} unless $ccm_version =~ m{(?:CM Synergy|SYNERGY/CM|Telelogic Synergy|IBM Rational Synergy)\s+Version\s+(\d+\.\d+)}i;
$ccm_version = $1;
print "Detected Synergy version $ccm_version\n";

warn qq{
  Please install module Scalar::Util and make sure it implements weaken().
  Without weaken(), a Synergy session might not be stopped as soon
  as the corresponding VCS::CMSynergy object goes out of scope
  (however, all sessions will be stopped when the script exits).
  Cf. "Why is Scalar::Util recommended?" in the POD for 
  VCS::CMSynergy::Object for details.
} unless (eval "use Scalar::Util qw(weaken); 1");


# arrange for all tests to be run a second time with UseCoprocess => 1
if ($ENV{RELEASE_TESTING}       # maintainer tests only
    && $ccm_version < 7.2       # UseCoprocess only works in classic mode
    && (eval { require Expect; import Expect 1.15; 1; }))
{
    print "Detected suitable version of Expect.pm, enabling tests with UseCoprocess => 1\n";

    foreach my $test (glob("xt/*.t"))
    {
        next if $test =~ m{^xt/zz_};

        open my $t, "<$test" or die "Can't read $test: $!";
        next unless grep { /using coprocess/ } <$t>;
        close $t;
        
        (my $zz_test = $test) =~ s{xt/}{xt/zz_};
        open my $zh, ">", $zz_test or warn "Can't create $zz_test: $!";
        print $zh <<"ZZ";
#!perl -w
\$ENV{CCM_USE_COPROCESS} = 1;
do './$test' or warn \$!;
die if \$\@;
exit 0;
ZZ
        close $zh or warn "Error writing $zz_test: $!";
    }
}

WriteMakefile1(

    NAME                        => 'VCS::CMSynergy',
    ABSTRACT_FROM               => 'lib/VCS/CMSynergy.pod',
    VERSION_FROM                => 'lib/VCS/CMSynergy.pm',
    AUTHOR                      => 'Roderich Schupp <schupp@argumentum.de>',
    LICENSE                     => 'perl_5',

    MIN_PERL_VERSION            => '5.010000',  # for feature "stat"

    PREREQ_PM => {
      'Tie::CPHash'             => 0,
      'Digest::MD5'		=> 0,
      'File::Spec'		=> 0,
      'File::Temp'		=> 0,
      'IPC::Run3'		=> '0.030',
      'List::Util'		=> '1.09',
      'Log::Log4perl'           => 0,
      'Pod::Usage'		=> 0,
      'Scalar::Util'		=> '1.19',
      'Time::HiRes'		=> 0,
      'Type::Params'		=> 0,
      'Types::Standard'         => 0,
    },
    TEST_REQUIRES => {
      'Test::More'		=> 0,
    },

    EXE_FILES                   => [ 'script/ccm_project_diff' ],

    clean                       => { FILES => 'xt/zz_*.t' },

    META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository  => {
          type => 'git',
          url  => 'git://github.com/rschupp/VCS-CMSynergy.git',
          web  => 'https://github.com/rschupp/VCS-CMSynergy',
        },
      },
      no_index => {
        package => [
          'Tie::ReadonlyArray', 
          'VCS::CMSynergy::ObjectTieHash', 
          'VCS::CMSynergy::Traversal',
        ],
      },
    },
);


sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
    $params{META_ADD}->{author}=$params{AUTHOR};
    $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
  }
  if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
    $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;

  WriteMakefile(%params);
}

