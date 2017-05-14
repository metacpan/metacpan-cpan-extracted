use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Fractal',    # Name of package
    'LIBS'	   => ['-L/home/sriram/ftp/gd1.2 -lgd'],     # All custom libraries to be linked with
    'INC' => "-I/home/sriram/ftp/gd1.2",
    'OBJECT' => 'mandel.o Fractal.o' # All object files
);

