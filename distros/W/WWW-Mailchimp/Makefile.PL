use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'WWW::Mailchimp',
  AUTHOR  => 'Justin Hunter <justin.d.hunter@gmail.com>',
  VERSION_FROM => 'lib/WWW/Mailchimp.pm',
  LICENSE => 'perl',
  ABSTRACT_FROM => 'lib/WWW/Mailchimp.pm',
  MIN_PERL_VERSION => '5.008001',
  PREREQ_PM => {
    'JSON' => '0',
    'LWP' => '0',
    'Moo' => '1.000007',
    'URI' => '0',
    'PHP::HTTPBuildQuery' => '0',
    'Sub::Name' => '0.05',
    'MooX::Types::MooseLike' => '0.16',
  },
  'BUILD_REQUIRES' => {
    'Test::More' => '0.88',
    'Test::Fatal' => '0.010',
  },
  META_MERGE      => {
    resources => {
      license     => 'http://dev.perl.org/licenses/',
      bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mailchimp',
      repository  => 'https://github.com/arcanez/www-mailchimp',
    },
  },
);

