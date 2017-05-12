use 5.000000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Traceroute::Similar',
    VERSION_FROM      => 'lib/Traceroute/Similar.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Traceroute/Similar.pm',
    AUTHOR            => 'Sven Nierlein <nierlein@cpan.org>',
    $ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( 'LICENSE' => 'perl' ) : (),
);
