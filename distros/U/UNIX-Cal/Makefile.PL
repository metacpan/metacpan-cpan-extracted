use Inline::MakeMaker;

use Cwd qw(abs_path); 
WriteInlineMakefile(
    clean => { 'FILES'	=> '*~ *.inl core test*.txt *.tar.gz _Inline ' },
    'PREREQ_PM' => { 'Inline'	=> '0.43' },
    dist => { 'TARFLAGS'	=> 'cvf',
              'COMPRESS'        => 'gzip -9f',
    		'SUFFIX'	=> '.tgz'},
    'NAME'	=> 'UNIX::Cal',
    'VERSION_FROM' => 'Cal.pm',
    'DEFINE'	=> '',   
);
