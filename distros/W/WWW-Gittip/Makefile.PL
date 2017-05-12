use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'WWW::Gittip',
    'VERSION_FROM'  => 'lib/WWW/Gittip.pm',
    'PREREQ_PM'     => {
                           'LWP::UserAgent'       => '6.04',
                           'MIME::Base64'         => 0,       # For Authentication header
                           'LWP::Protocol::https' => '6.04',  # for https support
                           'JSON'                 => 0,
                           'HTML::TreeBuilder'    => '5.03',
                        },
    "TEST_REQUIRES" => {
                           'Test::More'           => '1.00',
                           'Test::Deep'           => '0.113',
                           'Test::Warn'           => '0.30',
    },
    ABSTRACT_FROM => 'lib/WWW/Gittip.pm',
    AUTHOR        => 'Gabor Szabo <szabgab@cpan.org>',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),

    (eval { ExtUtils::MakeMaker->VERSION(6.46) }
      ? (META_MERGE => {
          resources => {
            repository => 'http://github.com/szabgab/WWW-Gittip',
          }
        })
      : ()
    ),
);
