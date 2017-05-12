use 5.6.1;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME            => 'Text-TWikiFormat-SAX',
              AUTHOR          => 'Aleksandr Guidrevitch (pillgrim@mail.ru)',
              ABSTRACT        => 'TWiki SAX parser',
              VERSION         => '0.03',
              PREREQ_PM => {
                            'XML::SAX::Writer'          => 0,
                            'XML::SAX::Base'            => 0,
                            'XML::SAX::DocumentLocator' => 0,
                            'HTML::Parser'              => 0,
                            'Test::More'                => 0,
                            'Test::Exception'           => 0
                           },
              EXE_FILES => [ ],
);
