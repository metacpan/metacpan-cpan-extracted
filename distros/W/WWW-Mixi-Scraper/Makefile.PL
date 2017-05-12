use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME           => 'WWW::Mixi::Scraper',
  AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM   => 'lib/WWW/Mixi/Scraper.pm',
  ABSTRACT_FROM  => 'lib/WWW/Mixi/Scraper.pm',
  PREREQ_PM => {
    'Encode'                         => 0,
    'Exporter'                       => 0,
    'Module::Find'                   => 0,
    'String::CamelCase'              => 0,
    'Test::UseAllModules'            => '0.09',
    'Time::HiRes'                    => 0,
    'URI'                            => 0,
    'URI::QueryParam'                => 0,
    'Web::Scraper'                   => '0.17',
    'WWW::Mechanize'                 => '1.50',
  },
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      repository => 'http://github.com/charsbar/www-mixi-scraper/',
    },
  },
);

my $eumm = $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}          if $eumm < 6.31;
delete $params{MIN_PERL_VERSION} if $eumm < 6.48;
delete $params{META_MERGE}       if $eumm < 6.46;
delete $params{META_ADD}         if $eumm < 6.46;
delete $params{LICENSE}          if $eumm < 6.31;

if ($eumm < 6.52 && $params{CONFIGURE_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}          || {} },
        %{ $params{CONFIGURE_REQUIRES} },
    };
    delete $params{CONFIGURE_REQUIRES};
}
if ($eumm < 6.5503 && $params{BUILD_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}      || {} },
        %{ $params{BUILD_REQUIRES} },
    };
    delete $params{BUILD_REQUIRES};
}

WriteMakefile(%params);
