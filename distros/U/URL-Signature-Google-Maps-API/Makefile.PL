use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'URL::Signature::Google::Maps::API',
    VERSION_FROM => 'lib/URL/Signature/Google/Maps/API.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/URL/Signature/Google/Maps/API.pm',
    PREREQ_PM    => {
                     'Test::Simple'       => 0.44,
                     'Package::New'       => 0,
                     'Path::Class'        => 0,
                     'Config::IniFiles'   => 0,
                     'MIME::Base64'       => 0,
                     'Digest::HMAC_SHA1'  => 0,
                    },
);
