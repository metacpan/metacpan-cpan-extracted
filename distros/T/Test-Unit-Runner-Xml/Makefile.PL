use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'Test::Unit::Runner::XML',
              AUTHOR => 'Andrew Eland <andrew@andreweland.org',
              ABSTRACT => 'Generate XML reports from unit test results',
              PREREQ_PM => {'Test::Unit' => '0.24',
                            'Time::HiRes' => 0,
                            'XML::Generator' => 0,
                            'XML::XPath' => 0},
              VERSION_FROM => 'lib/Test/Unit/Runner/XML.pm');

