use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::BMEcat',
    'VERSION_FROM'	=> 'BMEcat.pm',      # finds $VERSION
    ($] ge '5.005') ? (
        'AUTHOR'   => 'Frank-P. Reich (fpreich@cpan.org)',
        'ABSTRACT' => 'Perl extension for generating BMEcat-XML'
    ) : (),
);
