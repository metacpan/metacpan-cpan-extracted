use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/File/ShareDir.pm',
    'lib/Test/File/ShareDir/Dist.pm',
    'lib/Test/File/ShareDir/Module.pm',
    'lib/Test/File/ShareDir/Object/Dist.pm',
    'lib/Test/File/ShareDir/Object/Inc.pm',
    'lib/Test/File/ShareDir/Object/Module.pm',
    'lib/Test/File/ShareDir/TempDirObject.pm',
    'lib/Test/File/ShareDir/Utils.pm',
    't/00-compile/lib_Test_File_ShareDir_Dist_pm.t',
    't/00-compile/lib_Test_File_ShareDir_Module_pm.t',
    't/00-compile/lib_Test_File_ShareDir_Object_Dist_pm.t',
    't/00-compile/lib_Test_File_ShareDir_Object_Inc_pm.t',
    't/00-compile/lib_Test_File_ShareDir_Object_Module_pm.t',
    't/00-compile/lib_Test_File_ShareDir_TempDirObject_pm.t',
    't/00-compile/lib_Test_File_ShareDir_Utils_pm.t',
    't/00-compile/lib_Test_File_ShareDir_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_basic.t',
    't/01_files/lib/Example.pm',
    't/01_files/share/afile',
    't/02_distdir.t',
    't/02_files/share/afile',
    't/03_cwd.t',
    't/03_files/lib/Example.pm',
    't/03_files/share/afile',
    't/04_basic_simple.t',
    't/04_files/lib/Example.pm',
    't/04_files/share/afile',
    't/05_dist_dir_simple.t',
    't/05_files/share/afile',
    't/06_cwd_simple.t',
    't/06_files/lib/Example.pm',
    't/06_files/share/afile',
    't/07_files/lib/Example.pm',
    't/07_files/share/afile',
    't/07_util_withdist.t',
    't/08_files/lib/Example.pm',
    't/08_files/share/afile',
    't/08_util_withmodule.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
