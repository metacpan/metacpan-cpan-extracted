use Inline::MakeMaker;

WriteInlineMakefile(
    'NAME'		=> 'Video::OpenQuicktime',
    'VERSION_FROM'	=> 'OpenQuicktime.pm',
    'PREREQ_PM'		=> { Inline::C => 0.01   },

     ($] >= 5.005 ? (
       ABSTRACT_FROM    => 'OpenQuicktime.pm',
       AUTHOR           => 'Allen Day <allenday@ucla.edu>') : ()
     ),

    'PERL_MALLOC_OK'    => 1,
    'CONFIG'            => ['lddlflags'],
    'LIBS'		=> ['-lopenquicktime'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'CCFLAGS'		=> '-D_GNU_SOURCE -fno-strict-aliasing -I/usr/local/include',
    'INC'		=> '-I/usr/local/include', # e.g., '-I/usr/include/other'

    # Un-comment this if you add C files to link with later:
    'OBJECT'		=> '$(O_FILES)', # link all the C files too

#    'dynamic_lib'       => {'--rpath' => '/usr/local/lib'}
);


#gcc -c -I/home/allenday/cvsroot/perlquicktime -fno-strict-aliasing -I/usr/local/include -O2 -march=i386 -mcpu=i686   -DVERSION=\"1.02\" -DXS_VERSION=\"1.02\" -fPIC -I/usr/lib/perl5/5.6.1/i386-linux/CORE  OpenQuicktime.c

