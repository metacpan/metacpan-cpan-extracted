use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Test::Snapshot',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/Test/Snapshot.pm',
  ABSTRACT_FROM    => 'lib/Test/Snapshot.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.008003', # first with right Exporter
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.04',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.96', # subtest does done_testing
    'Test2::API' => '0',
    'Capture::Tiny' => 0,
    'App::Prove' => 0,
  },
  PREREQ_PM => {
    'Test::More' => '0.96', # subtest does done_testing
    'Test2::API' => '0',
    'Exporter' => '5.57', # exported "import"
    'File::Path' => '2.07', # make_path
  },
  clean => { FILES => 'Test-Snapshot-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/Test-Snapshot.git',
        web => 'https://github.com/mohawk2/Test-Snapshot',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/Test-Snapshot/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
          'Test::Pod' => '1.22',
          'Pod::Markdown' => 0,
        },
      },
    },
  },
);

sub MY::postamble {
  <<EOF;
pure_all :: README.md

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}
