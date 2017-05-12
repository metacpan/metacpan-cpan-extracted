use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VIM::Uploader',
    AUTHOR              => q{Cornelius <cornelius.howl@gmail.com>},
    VERSION_FROM        => 'lib/VIM/Uploader.pm',
    ABSTRACT_FROM       => 'lib/VIM/Uploader.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'MIT')
      : ()),
    EXE_FILES            => [ 'bin/vim-upload' ],
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'WWW::Mechanize' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VIM-Uploader-*' },
);
