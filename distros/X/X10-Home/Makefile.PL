use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'X10::Home',
    'VERSION_FROM' => 'Home.pm', # finds $VERSION
    'PREREQ_PM'    => {
        ControlX10::CM11   => 2.09,
        ControlX10::CM17   => 0.07,
        Log::Log4perl      => 1.10,
        YAML               => 0.35,
        Device::SerialPort => 1,
        DB_File            => 1.815,
    }, # e.g., Module::Name => 1.1
    'EXE_FILES'    => ['eg/x10'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Home.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
