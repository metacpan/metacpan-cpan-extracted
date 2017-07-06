use 5.010;
use ExtUtils::MakeMaker;

$^O =~ /^MSWin32/i or warn "This module only works on Windows!!!\nContinuing anyway...\n";

WriteMakefile( NAME              => 'Win32::Ldd',
               VERSION_FROM      => 'lib/Win32/Ldd.pm',
               ABSTRACT_FROM     => 'lib/Win32/Ldd.pm',
               AUTHOR            => 'Salvador Fandino <sfandino@yahoo.com>',
               LICENSE           => 'gpl',
               LIBS              => ['-limagehlp'],
               DEFINE            => '',
               INC               => '-I.',
               OBJECT            => '$(O_FILES)' );


