use ExtUtils::MakeMaker;

WriteMakefile(
   NAME  => "Uniden::BC75XLT",
   VERSION_FROM  => 'BC75XLT.pm',
   PREREQ_PM => { 'Device::SerialPort' => 0 },
   LICENSE => 'open_source',
   ABSTRACT => 'module to program Uniden BCL75XLT radio scanner over USB connection',
   AUTHOR => 'Vladimir Ershov ',
);
