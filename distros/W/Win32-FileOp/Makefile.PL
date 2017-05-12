use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Win32::FileOp',
    'PREREQ_PM' => {'Win32::API' => 0, 'Data::Lazy' => '0.5', 'Win32::AbsPath' => '1.0'},
    'VERSION_FROM' => 'FileOp.pm', # finds $VERSION
   ($] ge '5.005')
    ? (
     'AUTHOR' => 'Jan Krynicky (Jenda@Krynicky.cz),Mike (blazer@mail.nevalink.ru),Bill Luebkert (dbe@wgn.net)',
     'ABSTRACT' => 'Operations on files, copy/move/delete/recycle with fancy dialogs, Open and SaveAs dialogs, INI files editing, maping drives and a few others',
    )
    : ()
);
