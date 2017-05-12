use strict;
use Test::More;

use Win32::Unicode;

can_ok 'main', $_ for qw{
    printW printfW warnW sayW dieW
    file_type file_size copyW moveW unlinkW touchW renameW statW
    mkdirW rmdirW getcwdW chdirW findW finddepthW mkpathW rmtreeW mvtreeW cptreeW dir_size
};

done_testing;
