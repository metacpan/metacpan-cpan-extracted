use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		    => 'XML::Filter::BufferText',
    'VERSION_FROM'	=> 'BufferText.pm',
    'AUTHOR'        => 'Robin Berjon',
    'ABSTRACT'      => 'SAX Filter to guarantee characters in one event',
    'PREREQ_PM'		=> {
                        XML::SAX::Base  => '1.03',
                        Test::More      => '0.40',
                        XML::SAX        => '0.04',
                       },
);
