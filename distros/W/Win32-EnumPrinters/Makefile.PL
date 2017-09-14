use 5.024001;
use ExtUtils::MakeMaker;

if (-f "./.git" or !-f "./consts-c.inc") {
    warn "Generating constant declarations...\n";
    system $^X, "helpers/make_constants.pl";
}

WriteMakefile(NAME          => 'Win32::EnumPrinters',
              VERSION_FROM  => 'lib/Win32/EnumPrinters.pm',
              PREREQ_PM     => {},
              ABSTRACT_FROM => 'lib/Win32/EnumPrinters.pm',
              AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
              LICENSE       => 'perl',
              INC           => '-I.',
             );
