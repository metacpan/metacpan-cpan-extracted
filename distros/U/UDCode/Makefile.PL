use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => 'UDCode',
              VERSION_FROM => 'lib/UDCode.pm',
#             'linkext' => {LINKTYPE => ''},
              'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
);

