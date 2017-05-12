#!perl

use 5.006000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# Because where would sysexits.h come from? This is mostly to cut down
# on false positives from smoke tester boxes.
if ( $^O =~ m/MSWin32/ ) {
  print "Sorry, no automated install is available on Windows.\n";
  exit(0);
}

my %params = (
  NAME         => 'Unix::Sysexits',
  VERSION_FROM => 'lib/Unix/Sysexits.pm',    # finds $VERSION
  PREREQ_PM    => { 'Test::More' => 0, },    # e.g., Module::Name => 1.1
  ( $] >= 5.005
    ?    ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM => 'lib/Unix/Sysexits.pm', # retrieve abstract from module
      AUTHOR => 'Jeremy Mates <jmates@cpan.org>'
      )
    : ()
  ),
  LIBS   => [''],     # e.g., '-lm'
  DEFINE => '',       # e.g., '-DHAVE_SOMETHING'
  INC    => '-I.',    # e.g., '-I. -I/usr/include/other'
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'http://github.com/thrig/Unix-Sysexits',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/thrig/Unix-Sysexits',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.006000;
}

WriteMakefile((MM->can('signature_target') ? (SIGN => 1) : ()), %params);

if ( eval { require ExtUtils::Constant; 1 } ) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (
    qw(EX_CANTCREAT EX_CONFIG EX_DATAERR EX_IOERR EX_NOHOST
      EX_NOINPUT EX_NOPERM EX_NOUSER EX_OK EX_OSERR EX_OSFILE
      EX_PROTOCOL EX_SOFTWARE EX_TEMPFAIL EX_UNAVAILABLE EX_USAGE
      EX__BASE EX__MAX)
  );
  ExtUtils::Constant::WriteConstants(
    NAME         => 'Unix::Sysexits',
    NAMES        => \@names,
    DEFAULT_TYPE => 'IV',
    C_FILE       => 'const-c.inc',
    XS_FILE      => 'const-xs.inc',
  );

} else {
  use File::Copy;
  use File::Spec;
  foreach my $file ( 'const-c.inc', 'const-xs.inc' ) {
    my $fallback = File::Spec->catfile( 'fallback', $file );
    copy( $fallback, $file ) or die "Can't copy $fallback to $file: $!";
  }
}
