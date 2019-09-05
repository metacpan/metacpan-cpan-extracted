use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'WebService::Discord::Webhook',
  AUTHOR           => 'Greg Kennedy <kennedy.greg@gmail.com>',
  VERSION_FROM     => 'lib/WebService/Discord/Webhook.pm',
  ABSTRACT_FROM    => 'lib/WebService/Discord/Webhook.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => 5.006,
  PREREQ_PM        => {
    'HTTP::Tiny'   => 0,
    'JSON::PP'     => 0,
    'MIME::Base64' => 0,
    'Carp'         => 0,
    'File::Spec'   => 0,
  },
  META_MERGE => {
    resources => {
      homepage =>
        'https://github.com/greg-kennedy/p5-WebService-Discord-Webhook',
      repository =>
        'https://github.com/greg-kennedy/p5-WebService-Discord-Webhook',
      bugtracker =>
        'https://github.com/greg-kennedy/p5-WebService-Discord-Webhook/issues',
    },
  },
);
