use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'Text::FixedLength',
              dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              VERSION_FROM => 'FixedLength.pm');
