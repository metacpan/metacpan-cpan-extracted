use strict;
use warnings;
use version 0.77;

use 5.010000;

use ExtUtils::MakeMaker ;

my (%fribidi, $libs, $cflags);

my $min_fribidi = '1.0.0';

eval { require ExtUtils::PkgConfig };
if ( $@ ) {
    warn $@;
} else {
    %fribidi = eval { ExtUtils::PkgConfig->find('fribidi') };
}
if ( %fribidi ) {
    $libs = $fribidi{'libs'};
    $cflags = $fribidi{'cflags'};
    if (version->parse($fribidi{'modversion'}) < version->parse($min_fribidi)) {
        warn <<EOF;
Found an old version of the fribidi library. This version
of Text::Bidi requires fribidi >= $min_fribidi
EOF
        exit 0;
    }
} else {
    unless ( -r '/usr/include/fribidi/fribidi.h' ) {
        warn <<'EOF';

It seems that fribidi is missing. 

fribidi should be installed prior to the installation of this module.

EOF
        exit 0;

    }
    warn "Using heuristic values for CFLAGS and LIBS\n";
    $libs = '-lfribidi';
    $cflags = '-I/usr/include/fribidi -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include';
}

my %PM = map { 'lib/' . $_ => '$(INST_LIB)/' . $_} qw(
Text/Bidi/private.pm
Text/Bidi.pm
Text/Bidi/private.pm
Text/Bidi/Paragraph.pm
Text/Bidi/Constants.pm
Text/Bidi/Array.pm
Text/Bidi/Array/Byte.pm
Text/Bidi/Array/Long.pm

);

my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'DISTNAME' => 'Text-Bidi',
                       'MIN_PERL_VERSION' => '5.010000',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '0'
                                               },
                       'EXE_FILES' => [
                                        'bin/fribidi.pl'
                                      ],
                       'NAME' => 'Text::Bidi::private',
                       'ABSTRACT' => 'Unicode bidi algorithm using libfribidi',
                       'LICENSE' => 'perl',
                       'VERSION' => '2.16',
                       'PREREQ_PM' => {
                                        'Tie::Array' => '0',
                                        'integer' => '0',
                                        'Getopt::Long' => '0',
                                        'strict' => '0',
                                        'base' => '0',
                                        'Exporter' => '0',
                                        'DynaLoader' => '0',
                                        'Carp' => '0',
                                        'warnings' => '0',
                                        'overload' => '0',
                                        'open' => '0',
                                        'Encode' => '0'
                                      },
                       'AUTHOR' => 'Moshe Kamensky <kamensky@cpan.org>',
                       'TEST_REQUIRES' => {
                                            'Data::Dumper' => '0',
                                            'charnames' => '0',
                                            'File::Temp' => '0',
                                            'IO::Handle' => '0',
                                            'File::Spec' => '0',
                                            'ExtUtils::MakeMaker' => '0',
                                            'IPC::Open3' => '0',
                                            'Test::More' => '0',
                                            'version' => '0.77'
                                          }
                     );


%WriteMakefileArgs = (%WriteMakefileArgs,
    INC => $cflags,
    LIBS => $libs,
    OBJECT => 'private.o',
    PM => \%PM,
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    <<EOF;
pm_to_blib: lib/Text/Bidi/private.pm

private.c lib/Text/Bidi/private.pm: swig/fribidi.i
	-/usr/bin/swig -perl -Wall -I/usr/include $cflags -outdir lib/Text/Bidi/ -o private.c \$<
 
swig-clean: clean
	-rm private.c lib/Text/Bidi/private.pm

EOF
}

