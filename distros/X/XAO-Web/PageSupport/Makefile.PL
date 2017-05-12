use 5.008006;
use ExtUtils::MakeMaker;

### $CC='c++';
### 
### WriteMakefile(
###     NAME                => 'XAO::PageSupport',
###     VERSION_FROM        => 'PageSupport.pm',
###     PREREQ_PM           => {},
###     LIBS                => [''], # e.g., '-lm'
###     DEFINE              => '', # e.g., '-DHAVE_SOMETHING'
###     INC                 => '-I.', # e.g., '-I. -I/usr/include/other'
###     CC                  => $CC,
###     LD                  => '$(CC)',
###     'XSOPT'             => '-C++',
###     #'TYPEMAPS'          => ['perlobject.map' ],
### );

WriteMakefile(
    'NAME'		=> 'XAO::PageSupport',
    'VERSION_FROM'	=> 'PageSupport.pm'
);
