use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'URL::Signature::Google::Maps::API',
    VERSION_FROM => 'lib/URL/Signature/Google/Maps/API.pm',
    AUTHOR       => 'Michael R. Davis',
    ABSTRACT_FROM=> 'lib/URL/Signature/Google/Maps/API.pm',
    PREREQ_PM    => {
                     'Test::Simple'       => 0.44,
                     'Package::New'       => 0,
                     'Path::Class'        => 0,
                     'Config::IniFiles'   => 0,
                     'MIME::Base64'       => 0,
                     'Digest::HMAC'       => 0,
                    },
    'META_MERGE' => {
                     'resources' => {
                       'repository' => {
                         'web' => 'https://github.com/mrdvt92/perl-URL-Signature-Google-Maps-API.git',
                         'url' => 'git@github.com:mrdvt92/perl-URL-Signature-Google-Maps-API.git',
                         'type' => 'git'
                       },
                       'homepage' => 'https://github.com/mrdvt92/perl-URL-Signature-Google-Maps-API',
                       'bugtracker' => {
                         'web' => 'https://github.com/mrdvt92/perl-URL-Signature-Google-Maps-API/issues'
                       }
                     },
                     'meta-spec' => {
                       'version' => 2
                     }
                    }
);
