use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'jQuery::File::Upload',
    AUTHOR           => q{Adam Hopkins <srchulo@cpan.org>},
    VERSION_FROM     => 'lib/jQuery/File/Upload.pm',
    ABSTRACT_FROM    => 'lib/jQuery/File/Upload.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'CGI' => 0,
		'JSON::XS' => 0,
		'JSON' => 0,
		'Net::SSH2' => 0,
		'Net::SSH2::SFTP' => 0,
		'Image::Magick' => 0,
		'Cwd' => 0,
		'URI' => 0,
		'Data::GUID' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'jQuery-File-Upload-*' },
);
