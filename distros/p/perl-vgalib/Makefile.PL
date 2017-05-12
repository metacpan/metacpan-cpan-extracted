use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'vga',
    'VERSION_FROM' => 'vga.pm', 
    'LIBS'	=> ['-lvga'],  
    'DEFINE'	=> '',    
    'INC'	=> '',    
);
