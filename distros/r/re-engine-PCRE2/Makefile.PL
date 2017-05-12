use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.31;
use Config;

my $prefix;
if (@ARGV) { # PREFIX=~
  for my $arg (@ARGV) {
    if ($arg =~ /^-?-?PREFIX=(.*)/i) {
      # lib and include prefix if installed locally (ie. travis)
      $prefix = $1;
    }
  }
}

# this merely checks for the existance of the library.
# not if the static library can be used in a shared lib on ELF.
# i.e. if fPIC is used or not.
# we really need a fallback, like Alien::PCRE2 or shipped sources.
eval 'use Devel::CheckLib;' and
  check_lib_or_exit(
    lib => 'pcre2-8',
    header => 'pcre2.h',
    $prefix ? (
      incpath => "$prefix/include",
      libpath => "$prefix/lib"
    ) : ());

# fixup darwin macports usr vs opt precedence. /usr/local/include vs /usr/local/lib
my $ccflags = $Config{ccflags};
my $ldflags = $Config{ldflags};
my $lddlflags = $Config{lddlflags};
if ($lddlflags =~ m| -L/opt/local/lib| and $ccflags =~ m| -I/opt/local/include|) {
    # opt first?
    if ($lddlflags =~ m| -L/opt/local/lib.*-L/usr/local/lib|
        and $ccflags =~ m| -I/usr/local/include.*-I/opt/local/include|)
    {
        warn("Your perl has corrupt /opt/local vs /usr/local precedence!\n");
        warn("include prefers /usr/local, but lib /opt/local\n");
        warn("Fixing it up for you...\n");
        $lddlflags =~ s|(-L/opt/local/lib.*)(-L/usr/local/lib)|$2 $1|;
        if ($ldflags =~ m| -L/opt/local/lib.*-L/usr/local/lib|) {
            $ldflags =~ s|(-L/opt/local/lib.*)(-L/usr/local/lib)|$2 $1|;
        }
    }
}
if ($prefix) {
    $ccflags   = "-I$prefix/include $ccflags";
    $lddlflags = "-I$prefix/lib $lddlflags";
    $ldflags   = "-I$prefix/lib $ldflags";
}

my %WriteMakefileArgs = (
  'NAME'         => 're::engine::PCRE2',
  'VERSION_FROM' => 'PCRE2.pm',
  'ABSTRACT'     => 'PCRE2 regular expression engine with jit',
  'AUTHOR'       => 'Reini Urban <rurban@cpan.org>',
  'BUILD_REQUIRES' => {
    'Devel::CheckLib' => '1.00',
    'Data::Dumper' => '0',
    'Test::More'   => '0.88',
    ($ENV{RELEASE_TESTING}
     ? ('Test::Kwalitee'    => 0,
        'Class::XSAccessor' => 0,
        'Text::CSV_XS'      => 0,
        'List::MoreUtils'   => 0,
        'Pod::Spell::CommonMistakes' => 0,
        'Test::Pod'           => '1.00',
        'Test::Pod::Coverage' => '1.04',
        'Test::Spelling'      => 0)
     : ()),
  },
  'CONFIGURE_REQUIRES' => {
    'Devel::CheckLib'     => '1.00',
    'ExtUtils::MakeMaker' => '6.31'
  },
  'dist' => {
    PREOP	=> 'pod2markdown $(VERSION_FROM) | tee README.md >$(DISTVNAME)/README.md;'
                  .' chmod -R u=rwX,go=rX . ;',
    COMPRESS	=> 'gzip -9v',
    SUFFIX	=> '.gz',
  },
  'EXE_FILES' => [],
  'CCFLAGS'   => $ccflags,
  'LDDLFLAGS' => $lddlflags,
  'LDFLAGS'   => $ldflags,
  'LIBS'    => ($prefix ? [ "-L$prefix/lib", '-lpcre2-8' ] : [ '-lpcre2-8' ]),
  'LICENSE' => 'perl_5',
  'META_MERGE' => {
    resources => {
        license     => 'http://dev.perl.org/licenses/',
        bugtracker  => 'https://github.com/rurban/re-engine-PCRE2/issues',
        repository  => 'https://github.com/rurban/re-engine-PCRE2/',
    },
  },
  'test'    => {
    'TESTS' => 't/*.t t/perl/*.t'
  },
  'SIGN'    => 1,
);


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
delete $WriteMakefileArgs{META_MERGE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.46) };

WriteMakefile(%WriteMakefileArgs);

package MY;

sub top_targets {
  local $_ = shift->SUPER::top_targets(@_);
  s/\$\(FIRST_MAKEFILE\) blibdirs/\$(FIRST_MAKEFILE\) blibdirs README.md/;
  $_
}

sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README

README.md : \$(VERSION_FROM)
	pod2markdown \$(VERSION_FROM) > \$@

release : dist
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

test_cover :: pure_all
	\$(RM_RF) cover_db
	\$(PERLRUNINST) -S cover -test
test_coveralls :: pure_all
	\$(PERLRUNINST) -S cover -test -report coveralls

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).gcov cover_db/\$(BASEEXT)-xs.html

\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov \$(BASEEXT).c \$(BASEEXT).xs

cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"
}
