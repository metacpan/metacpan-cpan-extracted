use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  =>  {
                type => 'git',
                url => 'https://github.com/dinesh-it/www-google-drive.git',
                web => 'https://github.com/dinesh-it/www-google-drive'
            },
        },
    }
};

WriteMakefile(
    'NAME'         => 'WWW::Google::Drive',
    'VERSION_FROM' => 'lib/WWW/Google/Drive.pm',
    'LICENSE'      => 'perl_5',
    'PREREQ_PM'    => {
        'Log::Log4perl'         => 1.47,
        'Moose'                 => 2.1212,
        'LWP::UserAgent'        => 6.06,
        'URI'                   => 1.71,
        'HTTP::Headers'         => 6.05,
        'HTTP::Request::Common' => 6.04,
        'HTML::Entities'        => 3.69,
        'JSON'                  => 2.90, # from_json to_json decode_json
        'JSON::WebToken'        => 0.10,
        'Config::JSON'          => 1.52,
        'Sysadm::Install'       => 0.47, # slurp
        'File::Basename'        => 2.84,
        'File::MimeInfo'        => 0.25,
        'Crypt::OpenSSL::RSA'   => 0.20,
    },
    EXE_FILES                => [],
    clean => { FILES => 'WWW-Google-Drive-*' },
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR => 'Dinesh Dharmalingam <dd.dinesh.rajakumar@gmail.com>') : ()),
);
