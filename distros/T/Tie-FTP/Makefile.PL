use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Tie::FTP',
    'VERSION_FROM' => 'FTP.pm',     # finds $VERSION
    'PREREQ_PM'    => {
        'Net::FTP'   => 0,
        'File::Temp' => 0,
        'URI'        => 0
    },
);

