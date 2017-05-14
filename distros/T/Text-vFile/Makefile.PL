use ExtUtils::MakeMaker;

our $VERSION="0.5";

open ABSTRACT, "<", "ABSTRACT";
our $ABSTRACT=<ABSTRACT>;
chomp $ABSTRACT;
close ABSTRACT;

WriteMakefile(
    NAME         => 'Text::vFile',
    VERSION      => $VERSION,
    AUTHOR       => 'Jay J. Lawrence',
    ABSTRACT     => $ABSTRACT,
    EXE_FILES    => [
    ],
    PREREQ_PM    => {
    },
);

open VERSION, ">", "VERSION";
print VERSION "$VERSION";
close VERSION;

