use strict;
use Test::More;

use Win32::Unicode;

can_ok 'Win32::Unicode::Console', qw(
    printW
    printfW
    sayW
    warnW
);

can_ok 'Win32::Unicode::Dir', qw(
    getcwdW
    chdirW
    mkdirW
    rmdirW
    rmtreeW
    findW
    open
    close
    fetch
    file_type
    file_size
    file_list
    dir_list
);

can_ok 'Win32::Unicode::File', qw(
    file_type
    file_size
    touchW
    moveW
    copyW
    unlinkW
    renameW
);

can_ok 'Win32::Unicode::Util', qw(
    utf16_to_utf8
    utf8_to_utf16
    cygpathw
    to64int
    catfile
    splitdir
);

can_ok 'Win32::Unicode::Error', qw(
    errorW
);

can_ok 'Win32::Unicode::Process', qw(
    systemW
    execW
);

done_testing;
