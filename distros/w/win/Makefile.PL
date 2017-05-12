use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		      => 'win',
    'VERSION_FROM'	=> 'win.pm', # finds $VERSION
    'PREREQ_PM'		=> {Win32::Autoglob => 0, Win32::Die => 0, 
                            File::Which => 0 }, 
);
