use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'XML::Invisible',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/XML/Invisible.pm',
  ABSTRACT_FROM    => 'lib/XML/Invisible.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.008003',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64', # TEST_REQUIRES
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
    'Import::Into' => '0',
    'Test::Snapshot' => '0.02', # better snapshot filenames
  },
  PREREQ_PM => {
    'Pegex' => '0.64',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'XML-Invisible-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/xml-invisible.git',
        web => 'https://github.com/mohawk2/xml-invisible',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/xml-invisible/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      runtime => {
        suggests => {
          'XML::LibXML' => '0',
        },
      },
      develop => {
        requires => {
          'Test::Pod::Coverage' => '1.08',
          'Test::Pod' => '1.22',
          'Pod::Markdown' => 0,
          'XML::LibXML' => '0',
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
