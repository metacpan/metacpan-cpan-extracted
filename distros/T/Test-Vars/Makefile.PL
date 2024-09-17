use strict;
use warnings;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

# 1. Start with one big hash is consistent with CPAN::Meta::Spec, version 2
# and holds all the settings we'll need.

my $meta = {
   # "abstract" : See x_abstract_from
  "author"                  => ["Goru Fuji (gfuji\@cpan.org)"],
  "dynamic_config"          => 1,
  "generated_by"            => "ExtUtils::MakeMaker version 7.70, CPAN::Meta::Converter version 2.150010",
  "license"                 => ["perl_5"],
  "meta-spec"               => {
                                 url => "https://metacpan.org/pod/CPAN::Meta::Spec",
                                 version => 2,
                               },
  "name"                    => "Test-Vars",
  "no_index"                => { directory => ["example", "t", "xt"] },
  "prereqs" => {
      "develop" => {
        "requires" => {
          "Pod::Spelling" => "0",
          "Test::Pod" => "1.41",
          "Test::Pod::Coverage" => "1.04",
          "Test::Spelling" => "0.12",
          "Test::Synopsis" => "0"
        }
      },
      "configure" => {
         "requires" => {
            "ExtUtils::MakeMaker" => "6.17",
         }
      },
      "build" => {
         "requires" => {
            "ExtUtils::MakeMaker" => "6.17",
         }
      },
      "runtime" => {
         "requires" => {
            "B" => "0",
            "ExtUtils::Manifest" => "0",
            "IO::Pipe" => "0",
            "List::Util" => "1.33",
            "parent" => "0",
            "perl" => "5.010000",
            "Storable" => "0",
            "Symbol" => "0",
         }
      },
      "test" => {
         "requires" => {
            "File::Spec::Functions" => "0",
            "Test::More" => "0.88",
            "Test::Tester" => "0",
         },
         "recommends" => {
            "Moose::Role" => "0",
            "Test::Output" => "0",
         },
      },
    }, # END "prereqs"
   "provides" => {
      "Test::Vars" => {
         "file" => "lib/Test/Vars.pm",
         "version" => "0.017",
      }
   },
  "release_status"          => "stable",
  "resources" => {
      "bugtracker" => {
         "web" => "https://github.com/houseabsolute/p5-Test-Vars/issues"
      },
      "homepage" => "https://github.com/houseabsolute/p5-Test-Vars",
      "repository" => {
         "url" => "git://github.com/houseabsolute/p5-Test-Vars.git",
         "web" => "https://github.com/houseabsolute/p5-Test-Vars"
      }
   },
   # "version" # See x_version_from
  "x_contributors" => [
     'Dave Rolsky <autarch@urth.org>',
     'Dmitry Matrosov <amidos@amidos.ru>',
     'FUJI Goro <gfuji@cpan.org>',
     'FUJI Goro <gfx@users.noreply.github.com>',
     'FUJI Goro <goro.fuji@ebookjapan.co.jp>',
     'Fuji, Goro <g.psy.va@gmail.com>',
     'Gregory Oschwald <goschwald@maxmind.com>',
     'James E Keenan <jkeenan@cpan.org>',
     'Michael G. Schwern <schwern@pobox.com>',
     'Nicholas Clark <nick@ccl4.org>',
     'Olivier Mengué <dolmen@cpan.org>',
     'Ran Eilam <ran.eilam@gmail.com>',
     'Richard Leach <richardleach@users.noreply.github.com>',
     'cpansprout <cpansprout@gmail.com>'
  ],
  "x_abstract_from"         => "lib/Test/Vars.pm",
  "x_serialization_backend" => "JSON::PP version 4.16",
  "x_version_from"          => "lib/Test/Vars.pm",
};

my %dynamic_config;

# 2. In style of Type::Tiny Makefile.PL, handle some special cases defined by
# environmental variables like PERL_AUTHOR_TESTING, PERL_EXTENDED_TESTING,
# PERL_MINIMAL_INSTALL.  For example, in Type::Tiny MINIMAL_INSTALL omits
# 'recommends' and 'suggests' elements underneath 'prereqs'; EXTENDED_TESTING
# adds key-value pairs to prereqs->test->requires for further testing
# (INVESTIGATE FURTHER).

# TK

# 3. Create %WriteMakefileArgs.  Here we begin to create the data structure
# traditionally passed to ExtUtils::MakeMaker::WriteMakefile().

# %explicits: elements in $meta which we handle explicitly and which therefore
# do not need to be in META_MERGE

my %explicits = map {$_ => 1} qw( author license name x_abstract_from x_version_from );
my $for_meta_merge = { map { $_ => $meta->{$_} } grep { ! $explicits{$_} } keys %{$meta} };

my %WriteMakefileArgs = (
  ABSTRACT_FROM   => $meta->{x_abstract_from},
  AUTHOR          => ($EUMM >= 6.5702 ? $meta->{author}[0] : $meta->{author}),
  DISTNAME        => $meta->{name},
  VERSION_FROM    => $meta->{x_version_from},
  LICENSE         => ($EUMM >= 6.3001 ? $meta->{license}[0] : ''),
  EXE_FILES       => [],
  NAME            => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
  test            => { TESTS => ($ENV{PERL_AUTHOR_TESTING} ? "t/*.t xt/*.t" : "t/*.t") },
  ($EUMM < 6.46 ? () :  (META_MERGE => $for_meta_merge) ),
  %dynamic_config,
);

my ($build_requires, $configure_requires, $runtime_requires, $test_requires);
# Verify EUMM versions from Changes
# Validate by running against older perls with earlier versions of EUMM
if ($EUMM >= 6.6303) {
  $WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
  $WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
  $WriteMakefileArgs{TEST_REQUIRES}      ||= deps('test');
  $WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ($EUMM >= 6.5503) {
  $WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build', 'test');
  $WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
  $WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ($EUMM >= 6.52) {
  $WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
  $WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime', 'build', 'test');
}
else {
  $WriteMakefileArgs{PREREQ_PM}          ||= deps('configure', 'build', 'test', 'runtime');
}

my $minperl = min_perl_version($meta);
$WriteMakefileArgs{MIN_PERL_VERSION} = $EUMM >= 6.48 ? $minperl : '';

WriteMakefile(%WriteMakefileArgs);

#my $mm = WriteMakefile(%WriteMakefileArgs);
#require Data::Dump;
#Data::Dump::pp($mm);

########## SUBROUTINES ##########

sub deps { # Note: Not fully encapsulated; presumes $meta
  my %r;
  for my $stage (@_) {
    for my $degree (qw| requires recommends |) {
      for my $dep (keys %{$meta->{prereqs}{$stage}{$degree}}) {
        next if $dep eq 'perl';
        my $ver = $meta->{prereqs}{$stage}{$degree}{$dep};
        $r{$dep} = $ver if !exists($r{$dep}) || $ver >= $r{$dep};
      }
    }
  }
  return \%r;
}

sub min_perl_version {
  my $meta = shift;
  my ($minperl) = reverse sort(
    grep defined && /^[0-9]+(\.[0-9]+)?$/,
    map $meta->{prereqs}{$_}{requires}{perl},
    qw( configure build runtime )
  );

  if (defined($minperl)) {
    die "Installing $meta->{name} requires Perl >= $minperl"
      unless $] >= $minperl;
  }

  return $minperl;
}


# --- MakeMaker overrides ---
# inspired by Devel::NYTProf's Makefile.PL

package MY;

# add some extra utility targets to the make file
sub post_constants {
    q{

AUTHOR_TEST_FILES = "t/*.t xt/*.t"

test_author ::
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(AUTHOR_TEST_FILES)

atest: test_author

}
}

