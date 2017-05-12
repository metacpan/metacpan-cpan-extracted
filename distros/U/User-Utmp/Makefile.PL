use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'    => 'User::Utmp',
# $Format: "    'VERSION' => '$ProjectVersion$',"$
    'VERSION' => '1.8',
    'LIBS'    => [''],   # e.g., '-lm' 
    'DEFINE'  => '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'     => '',     # e.g., '-I/usr/include/other' 
    'dist'    => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
