use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::SystemInfo',
    'VERSION_FROM'	=> 'SystemInfo.pm', # finds $VERSION
    ($] ge '5.8.0') ? (
        'AUTHOR' => 'Chad Johnston (cjohnston@megatome.com)',
        'ABSTRACT' => 'Memory and Processor information on Win32 systems',
    ) : (),
    'PREREQ_PM'		=> {'Win32::API' => 0.60,
                            'Win32::TieRegistry' => 0.23}, # e.g., Module::Name => 1.1
);