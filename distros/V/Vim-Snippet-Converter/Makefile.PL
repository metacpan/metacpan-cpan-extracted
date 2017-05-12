use inc::Module::Install;
# Define metadata
name 'Vim-Snippet-Converter';
author 'Yo-An Lin <cornelius.howl {at} gmail.com>';
all_from 'lib/Vim/Snippet/Converter.pm';
license 'perl';

# Specific dependencies
requires 'Test::More' => 0;
requires 'File::Path' => 0;
requires 'File::Copy' => 0;
install_script 'bin/scc';
WriteAll;

__END__
use strict;
use warnings;
use ExtUtils::MakeMaker;

eval "use 5.008; 1"
    or die "ERROR: perl: Version $] is installed, "
    . "but we need version >= 5.008 ";

WriteMakefile(
    NAME          => 'Vim::Snippet::Converter',
    AUTHOR        => 'Cornelius <c9s@aiink.com>',
    VERSION_FROM  => 'lib/Vim/Snippet/Converter.pm',
    ABSTRACT_FROM => 'lib/Vim/Snippet/Converter.pm',
    PL_FILES      => { },
    PREREQ_PM     => {
        'Test::More' => 0,
        'File::Path' => 0,
        'File::Copy' => 0
    },
    EXE_FILES => [<bin/*>],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Vim-Snippet-Converter-*' },
);
