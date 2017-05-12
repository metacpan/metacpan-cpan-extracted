use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.31;
use Config;

my $prefix;
if (@ARGV) { # PREFIX=~
  while (my $arg = shift @ARGV) {
    if ($arg =~ /^-?-?PREFIX=(.*)/i) {
      # lib and include prefix if installed locally (ie. travis)
      $prefix = $1;
    }
  }
}

eval 'use Devel::CheckLib;' and
  check_lib_or_exit(
    lib => 'hs',
    header => 'hs/hs.h',
    $prefix ? (
      incpath => "$prefix/include",
      libpath => "$prefix/lib"
    ) : ());

my %WriteMakefileArgs = (
  'NAME'          => 're::engine::Hyperscan',
  'VERSION_FROM'  => 'Hyperscan.pm',
  'ABSTRACT_FROM' => 'Hyperscan.pm',
  'AUTHOR'        => 'Reini Urban <rurban@cpan.org>',
  'BUILD_REQUIRES' => {
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
  ($prefix
   ? ('CCFLAGS'   => "$Config{ccflags} -I$prefix/include",
      'LDDLFLAGS' => "$Config{lddlflags} -I$prefix/lib")
   : ()),
  'LIBS' => ($prefix ? [ "-L$prefix/lib", '-lhs' ] : [ '-lhs' ]),
  'LICENSE' => 'perl',
  'test' => {
    'TESTS' => 't/*.t t/perl/*.t'
  },
  'SIGN' => 1,
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
	echo git commit -a -m\"release \$(VERSION)\"
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
