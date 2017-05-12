use strict;
use warnings FATAL => 'all';
use 5.006;
use ExtUtils::MakeMaker;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %WriteMakefileArgs = (
  NAME => 'Web::Simple',
  VERSION_FROM => 'lib/Web/Simple.pm',

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,
    resources => {
      # r/w: catagits@git.shadowcat.co.uk:Web-Simple.git
      repository => {
        url => 'git://git.shadowcat.co.uk/catagits/Web-Simple.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=catagits/Web-Simple.git',
        type => 'git',
      },
      bugtracker => {
          mailto => 'bug-Web-Simple@rt.cpan.org',
          web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Web-Simple',
      },
    },
  },

  META_ADD => {
    prereqs => {
      configure => {
        requires => {
          'ExtUtils::MakeMaker' => 0,
        },
      },
      runtime => {
        requires => {
          'Encode' => '0',              # not core in 5.6
          'Exporter' => '5.57',         # use Exporter 'import'
          'Moo' => '0.009014',
          'Plack' => '0.9968',
          'HTTP::Body' => '1.22',
          'Scalar::Util' => '0',        # not core in 5.6
          'Syntax::Keyword::Gather' => '1.001',
          'strictures' => '1',
          'warnings::illegalproto' => '0',
          'perl' => '5.006',
        },
      },
      test => {
        requires => {
          'Data::Dumper::Concise' => '2.020',
          'Test::More' => '0.88',
        },
        recommends => {
          'Devel::Cycle' => '0',
          'HTTP::Request::AsCGI' => '0',
        },
      },
    },
  },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
  if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
  if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
  if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);
