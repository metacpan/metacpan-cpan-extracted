use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Google::Cloud::Auth::ServiceAccount',
    AUTHOR        => 'Larion Garaczi <larion@cpan.org>',
    VERSION_FROM  => 'lib/WWW/Google/Cloud/Auth/ServiceAccount.pm',
    ABSTRACT_FROM => 'lib/WWW/Google/Cloud/Auth/ServiceAccount.pm',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => 5.10.0,
    PREREQ_PM => {
        'Test::More'                => 0,
        'LWP::UserAgent'            => 0,
        'JSON'                      => 0,
        'Moose'                     => 0,
        'MooseX::HasDefaults::RO'   => 0,
        'MooseX::StrictConstructor' => 0,
        'namespace::autoclean'      => 0,
        'Carp'                      => 0,
        'Crypt::JWT'                => 0,
    },
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/larion/www-google-cloud-auth-serviceaccount.git',
              web  => 'https://github.com/larion/www-google-cloud-auth-serviceaccount'
          },
      }})
   : ()
   ),
);
